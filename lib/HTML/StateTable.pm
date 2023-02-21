package HTML::StateTable;

use 5.010001;
use namespace::autoclean;
use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 7 $ =~ /\d+/gmx );

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE RENDERER_CLASS
                                    RENDERER_PREFIX TABLE_META TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool ClassName Column Context
                                    HashRef LoadableClass NonEmptySimpleStr
                                    NonZeroPositiveInt Object Renderer
                                    Request ResultSet SimpleStr );
use HTML::StateTable::Util      qw( foreign_sort throw );
use File::DataClass::Functions  qw( ensure_class_loaded );
use List::Util                  qw( first );
use Ref::Util                   qw( is_arrayref is_coderef is_hashref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( Unspecified );
use Moo;
use MooX::HandlesVia;

# Public attributes
has 'cell_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'HTML::StateTable::Cell';

has 'columns' =>
   is          => 'rwp',
   isa         => ArrayRef[Column],
   lazy        => TRUE,
   handles_via => 'Array',
   handles     => { all_columns => 'elements' },
   default     => sub {
      my $self    = shift;
      my @columns = $self->_get_meta->all_columns;

      return [ sort { $a->position <=> $b->position } @columns ];
   };

has 'context' =>
   is        => 'ro',
   isa       => Context,
   predicate => 'has_context';

has 'displayable_columns' =>
   is          => 'lazy',
   isa         => HashRef[Bool],
   handles_via => 'Hash',
   handles     => { is_displayable_column => 'get' },
   default     => sub {
      my $self = shift;

      return { map { $_->name => $_->displayed } $self->all_columns };
   };

has 'empty_text' =>
   is      => 'ro',
   isa     => NonEmptySimpleStr,
   default => 'No data to display';

has 'max_page_size' => is => 'ro', isa => NonZeroPositiveInt, default => 100;

has 'name' =>
   is      => 'lazy',
   isa     => NonEmptySimpleStr,
   builder => sub {
      my $self = shift;
      my $meta = $self->_get_meta;

      return $meta->can('table_name') ? ($meta->table_name // q()) : q();
   };

has 'no_count' => is => 'ro', isa => Bool, default => FALSE;

has 'page' =>
   is      => 'rw',
   isa     => NonZeroPositiveInt,
   trigger => \&clear_prepared_resultset,
   default => 1;

has 'page_size' =>
   is      => 'rw',
   isa     => NonZeroPositiveInt,
   lazy    => TRUE,
   trigger => \&clear_prepared_resultset,
   default => sub { shift->_default('page_size', 20) };

has 'pager' => is => 'lazy', default => sub { shift->prepared_resultset->pager};

has 'paging' => is => 'rw', isa => Bool, default => TRUE;

has 'prepared_resultset' =>
   is        => 'lazy',
   isa       => ResultSet,
   builder   => '_prepare_resultset',
   clearer   => 'clear_prepared_resultset',
   predicate => 'has_prepared_resultset',
   required  => TRUE;

has 'renderer' =>
   is      => 'lazy',
   isa     => Renderer,
   handles => [ qw( render ) ],
   default => sub {
      my $self = shift;
      my $args = { %{$self->renderer_args}, table => $self };

      return $self->renderer_class->new($args);
   };

has 'renderer_args' =>
   is      => 'lazy',
   isa     => HashRef,
   default => sub { {} };

has 'renderer_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   default => sub { RENDERER_PREFIX . '::' . RENDERER_CLASS };

has 'request' =>
   is      => 'lazy',
   isa     => Request,
   default => sub {
      my $self = shift;

      throw Unspecified, ['context'] unless $self->has_context;

      return $self->context->request;
   };

has 'resultset' =>
   is      => 'lazy',
   isa     => ResultSet,
   default => sub {
      my $self  = shift;
      my $class = blessed $self;
      my $meta  = $self->_get_meta;

      throw 'Must supply a resultset to [_1]', [$class]
         unless $meta->can('has_resultset_callback')
             && $meta->has_resultset_callback;

      my $callback = $meta->resultset_callback;

      return $callback->($self);
   };

has 'row_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   default => 'HTML::StateTable::Row';

has 'row_count' =>
   is       => 'lazy',
   isa      => NonZeroPositiveInt,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return $self->paging
         ? $self->pager->total_entries : $self->prepared_resultset->count;
   };

has 'sort_column_name' =>
   is      => 'rw',
   isa     => SimpleStr,
   lazy    => TRUE,
   trigger => \&clear_prepared_resultset,
   default => sub {
      my $self = shift;

      return q() unless $self->sortable;

      my $default = $self->sortable_columns->[0]->name;

      return $self->_default('sort_column_name', $default);
   };

has 'sort_desc' =>
   is      => 'rw',
   isa     => Bool,
   default => sub { shift->_default('sort_desc', FALSE) };

has 'sortable' =>
   is       => 'lazy',
   isa      => Bool,
   init_arg => undef,
   default  => sub { scalar @{shift->sortable_columns} > 0 };

has 'sortable_columns' =>
   is       => 'lazy',
   isa      => ArrayRef[Column],
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return [ grep { $_->sortable && !ref $_->value } $self->all_columns ];
   };

has 'visible_columns' =>
   is          => 'lazy',
   isa         => ArrayRef[Column],
   init_arg    => undef,
   handles_via => 'Array',
   handles     => { all_visible_columns => 'elements' },
   default     => sub {
      my $self = shift;

      return [ grep { !$_->hidden($self) } $self->all_columns ];
   };

# Private attributes
has '_column_name_map' =>
   is          => 'lazy',
   isa         => HashRef[Column],
   handles_via => 'Hash',
   handles     => { get_column => 'get' },
   default     => sub {
      my $self = shift;

      return { map { $_->name => $_ } $self->all_columns };
   };

has '_roles' =>
   is           => 'ro',
   isa          => HashRef[ClassName],
   handles_via  => 'Hash',
   handles      => {
      add_role  => 'set',
      all_roles => 'keys',
      get_role  => 'get',
   },
   default      => sub { {} };

# Construction
around 'BUILDARGS' => sub {
   my ($orig, $self, @args) = @_;

   my $args = $orig->($self, @args);

   if (defined $args->{renderer_class}) {
      if ('+' eq substr $args->{renderer_class}, 0, 1) {
         $args->{renderer_class} = substr $args->{renderer_class}, 1;
      }
      else {
         $args->{renderer_class} = RENDERER_PREFIX . '::'
            . $args->{renderer_class};
      }
   }

   return $args;
};

sub BUILD {
   my $self = shift;

   $self->_apply_params if $self->has_context;
   return;
}

# Public methods
sub next_result {
   return shift->prepared_resultset->next;
}

sub next_row {
   my $self   = shift;
   my $result = $self->next_result;

   return unless defined $result;

   return $self->row_class->new( result => $result, table => $self );
}

sub reset_resultset {
   return shift->prepared_resultset->reset;
}

sub serialiser {
   my ($self, $moniker, $writer, $args) = @_;

   $args //= {};

   throw Unspecified, ['writer callback function']
      unless $writer && is_coderef $writer;

   throw 'If supplied, args must be a hashref' unless $args && is_hashref $args;

   $args->{table}  = $self;
   $args->{writer} = $writer;

   my $class;

   if ('+' eq substr $moniker, 0, 1) { $class = substr $moniker, 1 }
   else { $class = "HTML::StateTable::Serialiser::${moniker}" }

   ensure_class_loaded $class;

   return $class->new($args);
}

# Private methods
sub _apply_column_sql {
   my ($self, $resultset) = @_;

   my (@as, @select);

   for my $column ($self->all_visible_columns) {
      next unless $column->is_generated;

      my $as = $column->as; my $sql = $column->sql;

      if (is_hashref $sql) { $sql->{-as} = $as }
      elsif (is_coderef $sql) { $sql = $sql->($self) . " AS ${as}" }
      else { $sql =~ s{ \s+ AS \s+ \w+ \s* \z }{}imx; $sql .= " AS ${as}" }

      if ($column->bind_values) {
         my @bind = $column->bind_values->($self);

         throw 'Bind values are only supported with literal SQL' if ref $sql;

         push @select, \[$sql, @bind];
      }
      else { push @select, ref $sql ? $sql : \$sql }

      push @as, $as;
   }

   return $resultset unless @select;

   return $resultset->search(undef, { '+select' => \@select, '+as' => \@as });
}

sub _apply_pageing {
   my ($self, $resultset) = @_;

   return $resultset->search(undef, {
      page => $self->page,
      rows => $self->page_size,
   });
}

sub _apply_params {
   my $self = shift;

   throw 'Applying parameters needs a context object' unless $self->has_context;

   my $sort = $self->_param_value('sort');

   $self->sort_column_name($sort) if $sort;

   my $sort_desc = $self->_param_value('desc');

   $self->sort_desc(!!$sort_desc) if $sort;

   my $page = $self->_param_value('page');

   $self->page($page) if defined $page && $page =~ m{ \A [0-9]+ \z }mx;

   if (my $page_size = $self->_param_value('page_size')) {
      $page_size = 1 if $page_size < 1;
      $page_size = $self->max_page_size if $page_size > $self->max_page_size;
      $self->page_size($page_size);
   }

   return;
}

sub _apply_sorting {
   my ($self, $resultset) = @_;

   my $column = $self->get_column($self->sort_column_name) // return $resultset;

   if ($column->is_generated) {
      my $order = $self->sort_desc ? '-desc' : '-asc';

      return $resultset->search(undef, {
         order_by => { $order => $column->as }
      });
   }

   my $sort_column = $column->has_sort_column
      ? $column->sort_column : $column->value;

   $sort_column = [{ column => $sort_column }] unless is_arrayref $sort_column;

   return foreign_sort $resultset, $sort_column, $self->sort_desc;
}

sub _default {
   my ($self, $option, $default) = @_;

   my $meta = $self->_get_meta;

   return $default unless $meta->default_exists($option);

   return $meta->get_default($option);
}

sub _get_meta {
   my $self  = shift;
   my $class = blessed $self || $self;
   my $attr  = TABLE_META;

   return $class->$attr;
}

sub _param_key {
   my ($self, $param_name) = @_;

   return $self->name ? $self->name . "_${param_name}" : $param_name;
}

sub _param_value {
   my ($self, $name) = @_;

   return unless $self->has_context;

   my $params = $self->request->query_parameters;
   my $value;

   if ($self->name) {
      my $param_key = $self->_param_key($name);

      $value = $params->{$param_key} if exists $params->{$param_key};
   }

   $value = $params->{$name} if !defined $value and exists $params->{$name};

   return $value;
}

sub _prepare_resultset {
   my $self      = shift;
   my $resultset = $self->resultset;

   for my $column ($self->all_visible_columns) {
      next if ref $column->value or $column->get_option('no_prefetch');

      my @relations = split m{ \. }mx, $column->value; pop @relations;

      next unless scalar @relations;

      my $join;

      for my $relation (reverse @relations) {
         $join = defined $join ? { $relation => $join } : $relation;
      }

      $resultset = $resultset->search(undef, { prefetch => $join });
   }

   $resultset = $self->_apply_column_sql($resultset);
   $resultset = $self->_apply_pageing($resultset) if $self->paging;
   $resultset = $self->_apply_sorting($resultset) if $self->sortable;

   return $resultset;
}

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::StateTable - One-line description of the modules purpose

=head1 Synopsis

   use HTML::StateTable;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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

Copyright (c) 2021 Peter Flanigan. All rights reserved

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
