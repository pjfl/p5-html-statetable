package HTML::StateTable::Renderer::EmptyDiv;

use HTML::StateTable::Constants qw( FALSE NUL QUERY_KEY SERIALISE_COLUMN_ATTR
                                    SPC TRIGGER_CLASS TRUE );
use HTML::StateTable::Types     qw( HashRef NonEmptySimpleStr );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_coderef is_hashref );
use Type::Utils                 qw( class_type );
use JSON::MaybeXS;
use HTML::StateTable::Result::Dummy;
use Moo;

extends 'HTML::StateTable::Renderer';

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Renderer::EmptyDiv - Renders the table as an empty div

=head1 Synopsis

   use HTML::StateTable::Renderer::EmptyDiv;

=head1 Description

Table render class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item container_tag

Overrides the default setting the container element to C<div>

=cut

has '+container_tag' => default => 'div';

=item data

Overrides the default returning a hash reference used to set the attributes
of the C<container> element. Contains the C<TRIGGER_CLASS> and the JSON
encoded table configuration

=cut

has '+data' => default => sub {
   my $self  = shift;
   my $table = $self->table;
   my $class = $table->can('table_class') ? SPC . $table->table_class : NUL;

   return {
      'class' => TRIGGER_CLASS . $class,
      'data-table-config' => $self->_json->encode({
         columns    => $self->_serialise_columns,
         name       => $self->table->name,
         properties => $self->_serialise_properties,
         roles      => $self->_serialise_roles,
      }),
   };
};

=item query_key

Defaults to the value supplied by the C<Constants> class (C<table_name>). This
is the query parameter that is used to identify which table on a page the
request is targeting

=cut

has 'query_key' => is => 'lazy', isa => NonEmptySimpleStr, default => QUERY_KEY;

# Private attributes
has '_json' => is => 'ro', isa => class_type(JSON::MaybeXS::JSON),
   default => sub {
      return JSON::MaybeXS->new( convert_blessed => TRUE, utf8 => FALSE );
   };

has '_tags' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub {
      my $self = shift;
      my %tags = ();

      for my $column ($self->table->all_visible_columns) {
         $tags{$column->append_to} = TRUE if $column->append_to;
      }

      return \%tags;
   };

=back

=head1 Subroutines/Methods

Defines no public methods

=cut

# Private functions
sub _trait_names ($$$) {
   my ($dummy_row, $column, $trait) = @_;

   my $cell = $column->create_cell($dummy_row);

   return $cell->trait_names if $cell->can('trait_names');

   $trait =~ s{ \A .* :: }{}mx;

   return [$trait];
}

# Private methods
sub _boolify {
   my ($self, $column, $attribute, $value) = @_;

   my $attr_meta = $column->_get_meta->find_attribute_by_name($attribute);
   my $type      = $attr_meta->isa if defined $attr_meta;
   my $is_bool   = defined $type && $type =~ m{ Bool }mx ? TRUE : FALSE;

   if ($is_bool) { $value = json_bool $value }
   elsif (is_hashref $value) {
      $value = {
         map  { $_ => _boolify_if_option($column, $attribute, $_, $value->{$_})}
         grep { !is_coderef $value->{$_} } keys %{$value}
      };
   }

   return $value;
}

sub _boolify_if_option {
   my ($column, $attribute, $key, $value) = @_;

   if ($attribute eq 'options' && $column->is_boolean_option($key)) {
      $value = json_bool $value;
   }

   return $value;
}

sub _dummy_row {
   my $self   = shift;
   my $table  = $self->table;
   my $result = HTML::StateTable::Result::Dummy->new;

   return $table->row_class->new(table => $table, result => $result);
}

sub _serialise_columns {
   my $self      = shift;
   my $table     = $self->table;
   my $dummy_row = $self->_dummy_row;
   my @columns;

   for my $column ($table->all_visible_columns) {
      next if $column->append_to;

      my $displayed  = $table->is_displayable_column($column->name);
      my %attributes = ( displayed => json_bool $displayed );

      for my $attribute (SERIALISE_COLUMN_ATTR()) {
         next unless $column->can($attribute);

         my $value = _is_column_trait($attribute)
            ? $column->$attribute($self) : $column->$attribute;

         next unless defined $value;

         $attributes{$attribute}
            = $self->_boolify($column, $attribute, $value);
      }

      $attributes{cell_traits} = [
         map { @{ _trait_names $dummy_row, $column, $_ } }
               @{ delete $attributes{cell_traits} }
      ];

      $attributes{downloadable} = json_bool
         ($table->serialisable_columns->{$column->name} ? TRUE : FALSE);

      $attributes{has_tags} = json_bool TRUE
         if exists $self->_tags->{$column->name};

      push @columns, \%attributes;
   }

   return \@columns;
}

sub _is_column_trait {
   my $attr = shift;

   return TRUE if $attr eq 'searchable';
   return TRUE if $attr eq 'title';
   return FALSE;
}

sub _serialise_properties {
   my $self  = shift;
   my $table = $self->table;
   my $uri   = $table->request->uri;

   $uri->query_param($self->query_key => $table->name);

   my $data = {
      'caption'         => $table->caption,
      'data-url'        => $uri->as_string,
      'enable-paging'   => json_bool $table->paging,
      'max-page-size'   => $table->max_page_size,
      'no-count'        => json_bool $table->no_count,
      'no-data-message' => $table->empty_text,
      'nav-manager'     => $table->nav_manager,
      'page-size'       => $table->page_size,
      'render-style'    => $table->render_style,
      'row-count'       => 0,
      'sort-column'     => $table->sort_column_name,
      'sort-desc'       => json_bool $table->sort_desc,
      'title-location'  => $table->title_location,
   };

   $data->{'row-count'} = $table->row_count unless $table->no_count;

   $data->{'verify-token'} = $table->context->verification_token
      if $table->has_context;

   return $data;
}

sub _serialise_roles {
   my $self  = shift;
   my $table = $self->table;
   my $roles = {};
   my $index = 0;

   if ($table->paging) {
      $roles->{'pageable'} = {
         'location'   => { control => $table->page_control_location },
         'role-index' => $index++,
         'role-name'  => 'Pageable',
      };
      $roles->{'pagesize'} = {
         'location'   => { control => $table->page_size_control_location },
         'role-index' => $index++,
         'role-name'  => 'PageSize',
      };
   }

   for my $role_name ($table->all_role_names) {
      next unless $table->does($table->get_role($role_name));

      my $method = "serialise_${role_name}";

      if (defined(my $value = $table->$method)) {
         $value->{'role-index'} = $index++;
         $roles->{$role_name} = $value;
      }
   }

   return $roles;
}

use namespace::autoclean;

1;

__END__

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<HTML::StateTable::Renderer>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-StateTable.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
