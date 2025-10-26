package HTML::StateTable::Role::Filterable;

use HTML::StateTable::Constants qw( COL_INFO_TYPE_ATTR EXCEPTION_CLASS FALSE
                                    MAX_FILTER_ROWS SERIALISE_TABLE_KEY
                                    SERIALISE_TABLE_VIEW TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( json_bool throw );
use Ref::Util                   qw( is_coderef );
use Unexpected::Functions       qw( UnknownView );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Filterable - Filters rows by column value

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Filterable';

=head1 Description

Filters rows by column value

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item filterable_dialog_title

An immutable string which defaults to C<Filter>. The title text displayed on
the filter dialog

=cut

has 'filterable_dialog_title' => is => 'ro', isa => Str, default => 'Filter';

=item filterable_message_label

An immutable string which defaults to C<<Filtering on column>>. Displayed
when filtering is active

=cut

has 'filterable_message_label' => is => 'ro', isa => Str,
   default => 'Filtering on column';

=item filterable_message_location

An immutable string with a default of C<Title>. The location where the
filtering message is displayed

=cut

has 'filterable_message_location' => is => 'ro', isa => Str, default => 'Title';

=item filterable_remove_label

An immutable string which defaults to C<Show all>. Displayed when filtering,
returns to the unfiltered view

=cut

has 'filterable_remove_label' => is => 'ro', isa => Str,
   default => 'Show all';

=item filterable_view_name

An immutable string which defaults to the constant C<SERIALISE_TABLE_VIEW>.
The application view name used to serialise the filter results

=cut

has 'filterable_view_name' => is => 'ro', isa => Str,
   default => SERIALISE_TABLE_VIEW;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Executes after C<BUILD>. If the table has C<context> adds the
C<serialise_filterable> method to the call chain used to serialise the table
description

=cut

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->has_context;

   $self->add_role('filterable', __PACKAGE__);

   my $view = $self->filterable_view_name;

   throw UnknownView, [$view] unless $self->context->view($view);

   my $column_name = $self->param_value('filter_column_values') or return;

   $self->context->stash(
      SERIALISE_TABLE_KEY() => {
         table              => $self,
         format             => 'json',
         no_filename        => TRUE,
         serialiser_args    => {
            disable_paging  => TRUE,
            filter_column   => $column_name,
         },
      },
      view => $view,
   );

   return;
};

=item build_prepared_resultset

Executes around the method in the consuming class. Applies the filter query
parameters to the resultset

=cut

around 'build_prepared_resultset' => sub {
   my ($orig, $self) = @_;

   my $rs = $orig->($self);
   my $name = $self->param_value('filter_column');
   my $value = $self->param_value('filter_value');

   return $rs unless $name && $value;

   $self->is_filtered(TRUE);

   my $column = $self->get_column($name);

   if ($column->has_filter_value_map) {
      my $map = $column->filter_value_map;
      my %pam = reverse %{ is_coderef $map ? $map->($self) : $map };

      $value = $pam{$value} if exists $pam{$value};
   }

   my $relation_name = $rs->current_source_alias;
   my $filter_column = $column->filter_column if $column->has_filter_column;

   if ($column->has_filter_relation) {
      my ($related_rs, $name)
         = $self->_get_related_rs($rs, $column->filter_relation);

      $relation_name = $name;
      $filter_column = $self->_get_result_source_pkey($related_rs)
         if $column->filter_use_pkey;
   }

   return $rs->search({ -nest => \[$column->sql . ' = ?' => [sql => $value]]})
      if $column->is_generated;

   return $rs->search({ "${relation_name}.${filter_column}" => $value });
};

=item filter_column_values( $column_name )

Returns the list of column values for the specified column name

=cut

sub filter_column_values {
   my ($self, $column_name) = @_;

   return [] unless $column_name;

   my $column = $self->get_column($column_name);

   return [] unless $column && $column->filterable;

   my $column_name = $column->filter_column;
   my $rs = $self->resultset->search(undef, { rows => MAX_FILTER_ROWS });

   delete $rs->{attrs}->{'+as'}; delete $rs->{attrs}->{'+select'};

   if ($column->has_filter_relation) {
      my ($related_rs, $relation)
         = $self->_get_related_rs($rs, $column->filter_relation);
      my $pkey    = $self->_get_result_source_pkey($related_rs);
      my @columns = map { "${relation}.${_}" } ($pkey, $column_name);
      my $schema  = $related_rs->result_source->schema;
      my $order   = $schema->storage->sql_maker->_quote($columns[1]);

      shift @columns unless $column->filter_use_pkey;

      $rs = $related_rs->search(undef, {
         columns => [@columns], group_by => [@columns]
      });

      my $attr = COL_INFO_TYPE_ATTR;
      my $info = $rs->result_source->column_info($column_name);
      my $order_by = 'text' eq lc $info->{$attr} ? \qq{lower($order)} : \$order;

      $rs = $rs->search(undef, { order_by => $order_by });

      return [ map { [ $_->$column_name => $_->id ] } $rs->all ];
   }

   if ($column->is_generated) {
      $rs = $self->_apply_column_sql($rs, $column)->search(undef, {
         columns => [], group_by => \$column->sql, order_by => \q{1},
      });
   }
   else {
      $rs = $rs->search(undef, {
         columns  => [$column_name],
         distinct => TRUE,
         order_by => $column_name,
      });
   }

   return [$rs->get_column($column_name)->all];
}

=item serialise_filterable

Called by C<serialise_roles> in C<EmptyDiv> renderer. Returns a hash reference
of parameters used by the front end to display the filter dialog

=cut

sub serialise_filterable {
   my $self = shift;

   return {
      'apply'         => { before => json_bool TRUE },
      'dialog-title'  => $self->filterable_dialog_title,
      'location'      => { messages => $self->filterable_message_location },
      'message-label' => $self->filterable_message_label,
      'remove-label'  => $self->filterable_remove_label,
   };
}

# Private methods
sub _get_related_rs {
   my ($self, $related_rs, $relation) = @_;

   my @relations  = split m{ \. }mx, $relation;

   for (@relations) { $related_rs = $related_rs->related_resultset($_) }

   return $related_rs, $relations[-1];
}

sub _get_result_source_pkey {
   my ($self, $rs) = @_;

   my @pkey = $rs->result_source->primary_columns;

   throw 'Related table filtering requires a single primary key'
      unless scalar @pkey == 1;

   return $pkey[0];
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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

Copyright (c) 2024 Peter Flanigan. All rights reserved

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
