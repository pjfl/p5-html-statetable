package HTML::StateTable;

use 5.010001;
use version; our $VERSION = qv( sprintf '0.1.%d', q$Rev: 68 $ =~ /\d+/gmx );

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE NUL RENDERER_CLASS
                                    RENDERER_PREFIX TABLE_META TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool ClassName Column Context
                                    HashRef LoadableClass NonEmptySimpleStr
                                    NonZeroPositiveInt Object PositiveInt
                                    Renderer Request ResultSet SimpleStr );
use HTML::StateTable::Util      qw( ensure_class_loaded foreign_sort throw
                                    trim );
use List::Util                  qw( first );
use Ref::Util                   qw( is_arrayref is_coderef is_hashref );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( Unspecified );
use Moo;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable - Displays tables from DBIC resultsets

=head1 Synopsis

   use HTML::StateTable;

=head1 Description

A rich description of the required table is serialised to the browser via the
data attributes of an empty C<div> element. The JS running in the browser
renders the table a fetches row data from the server which it also renders.
User interactions with the table result in mutated query parameters on the
request for row data to the server. New row data is rendered without any page
reload

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item caption

An mutable string with a null default. If set will display as the tables
caption

=cut

has 'caption' => is => 'rw', isa => SimpleStr, default => NUL;

=item cell_class

A lazy loadable class that defaults to L<HTML::StateTable::Cell>

=cut

has 'cell_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   coerce  => TRUE,
   default => 'HTML::StateTable::Cell';

=item columns

A lazy privately mutable array reference of C<Column> objects in sorted order

Handles C<all_columns> via array trait

=cut

has 'columns' =>
   is          => 'rwp',
   isa         => ArrayRef[Column],
   lazy        => TRUE,
   handles_via => 'Array',
   handles     => { all_columns => 'elements' },
   default     => sub {
      my $self    = shift;
      my @columns = $self->_get_meta->all_columns;

      return [ $self->sorted_columns(@columns) ];
   };

=item context

An optional C<Context> object passed to the constructor. If supplied it is
expected to contain a request object. Some table roles require this to
function

=item has_context

Predicate for the C<context> attribute. Weakened reference

=cut

has 'context' =>
   is        => 'ro',
   isa       => Context,
   predicate => 'has_context',
   weak_ref  => TRUE;

=item displayable_columns

A lazy hash reference of booleans keyed by column name. Indicates that the
column is displayable

Handles C<is_displayable_column> via the hash trait

=cut

has 'displayable_columns' =>
   is          => 'lazy',
   isa         => HashRef[Bool],
   handles_via => 'Hash',
   handles     => { is_displayable_column => 'get' },
   default     => sub {
      return { map { $_->name => $_->displayed } shift->all_columns };
   };

=item empty_text

A string to display when there is no data

=cut

has 'empty_text' =>
   is      => 'ro',
   isa     => NonEmptySimpleStr,
   default => 'No data to display';

=item icons

An immutable string with a null default. URI of the SVG file containing named
symbols. If not supplied default UTF-8 characters will be used instead

=cut

has 'icons' => is => 'lazy', isa => SimpleStr, default => sub { NUL };

=item is_filtered

A mutable boolean that defaults to false. Is set to true by the C<Filterable>
and C<Searchable> table roles

=cut

has 'is_filtered' => is => 'rw', isa => Bool, default => FALSE;

=item log

Optional logging object used to log errors

=item has_log

Predicate

=cut

has 'log' => is => 'ro', isa => Object, predicate => 'has_log';

=item max_page_size

A non zero positive integer that defaults to 100. The hard limit on the
C<page_size> attribute

=cut

has 'max_page_size' => is => 'ro', isa => NonZeroPositiveInt, default => 100;

=item max_width

A string with a null default. Used to set the maximum width on the table

=cut

has 'max_width' => is => 'ro', isa => SimpleStr, default => NUL;

=item name

A non empty simple string that defaults to one supplied by the meta class

=cut

has 'name' =>
   is      => 'lazy',
   isa     => NonEmptySimpleStr,
   builder => sub {
      my $self = shift;
      my $meta = $self->_get_meta;

      return $meta->can('table_name') ? ($meta->table_name // q()) : q();
   };

=item no_count

A boolean which defaults to false. If set to true will prevent the counting
of database table rows which in turn leads to the non displaying of the page
count and the last link

=cut

has 'no_count' => is => 'ro', isa => Bool, default => FALSE;

=item page

A mutable non zero positive integer that defaults to 1. The number of the
current page of data being displayed

=cut

has 'page' =>
   is      => 'rw',
   isa     => NonZeroPositiveInt,
   trigger => \&clear_prepared_resultset,
   default => 1;

=item page_control_location

An immutable non empty simple string which defaults to 'BottomRight'. The
location of the page control

=cut

has 'page_control_location' => is => 'ro', isa => NonEmptySimpleStr,
   default => 'BottomLeft';

=item page_manager

An immutable simple string with a null default. Name of the JS page management
object

=cut

has 'page_manager' => is => 'ro', isa => SimpleStr, default => NUL;

=item page_size

A mutable non zero positive integer which defaults to 20. The number of rows
to be displayed per page. This is settable from preferences

=cut

has 'page_size' =>
   is      => 'rw',
   isa     => NonZeroPositiveInt,
   lazy    => TRUE,
   trigger => \&clear_prepared_resultset,
   default => sub { shift->_default('page_size', 20) };

=item page_size_control_location

An immutable non empty simple string which defaults to 'BottomLeft'. The
location of the page size control

=cut

has 'page_size_control_location' => is => 'ro', isa => NonEmptySimpleStr,
   default => 'BottomRight';

=item pager

The pager object on the prepared resultset

=cut

has 'pager' => is => 'lazy', default => sub { shift->prepared_resultset->pager};

=item paging

A mutable boolean which default to true. If false paging is disabled and no
limit is placed on the number of rows retrieved from the database

=cut

has 'paging' => is => 'rw', isa => Bool, default => TRUE;

=item prepared_resultset

A required lazy C<ResultSet> built from the C<resultset> attribute. The
builder method is C<build_prepared_resultset>. The prepared resultset restricts
the row retrieved from the database to those requested by the C<Searchable> and
C<Filterable> table roles

=item has_prepared_resultset

Predicate for C<prepared_resultset>

=cut

has 'prepared_resultset' =>
   is        => 'lazy',
   isa       => ResultSet,
   builder   => 'build_prepared_resultset',
   clearer   => 'clear_prepared_resultset',
   predicate => 'has_prepared_resultset',
   required  => TRUE;

=item render_style

A mutable simple string which defaults to 'replace'. Used by the experimental
animation feature to select which type of row replacement animation to use

=cut

has 'render_style' =>
   is      => 'rw',
   isa     => SimpleStr,
   default => sub { shift->_default('render_style', 'replace') };

=item renderer

The object used to render the table

=cut

has 'renderer' =>
   is      => 'lazy',
   isa     => Renderer,
   handles => [ qw( render ) ],
   default => sub {
      my $self = shift;
      my $args = { %{$self->renderer_args}, table => $self };

      return $self->renderer_class->new($args);
   };

=item renderer_args

A hash reference of arguments passed the renderer's constructor

=cut

has 'renderer_args' => is => 'lazy', isa => HashRef, default => sub { {} };

=item renderer_class

A lazy loadable class. The class name of the C<renderer> object

=cut

has 'renderer_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   default => sub { RENDERER_PREFIX . '::' . RENDERER_CLASS };

=item request

A lazy C<Request> object supplied by the C<context>

=cut

has 'request' =>
   is      => 'lazy',
   isa     => Request,
   default => sub {
      my $self = shift;

      throw Unspecified, ['context'] unless $self->has_context;

      return $self->context->request;
   },
   weak_ref => TRUE;

=item resultset

A L<DBIx::Class::ResultSet> object

=cut

has 'resultset' =>
   is      => 'lazy',
   isa     => ResultSet,
   default => sub {
      my $self  = shift;
      my $class = blessed $self;
      my $meta  = $self->_get_meta;

      throw Unspecified, ['resultset']
         unless $meta->can('has_resultset_callback')
         && $meta->has_resultset_callback;

      my $callback = $meta->resultset_callback;

      return $callback->($self);
   };

=item row_class

A lazy loadable class which defaults to C<HTML::StateTable::Row>. The class
name for the row object

=cut

has 'row_class' =>
   is      => 'lazy',
   isa     => LoadableClass,
   default => 'HTML::StateTable::Row';

=item row_count

The total row count as return by either the resultset pager object or the
prepared resultset count depending on whether paging is enabled

=cut

has 'row_count' =>
   is       => 'lazy',
   isa      => PositiveInt,
   init_arg => undef,
   default  => sub {
      my $self = shift;

      return $self->prepared_resultset->count unless $self->paging;
      return $self->pager->total_entries if $self->pager;
      return 0;
   };

=item serialisable_columns

A lazy hash reference of booleans keyed by column name. Indicates that the
column is serialisable

Handles C<is_serialisable_column> via the hash trait

=cut

has 'serialisable_columns' =>
   is          => 'lazy',
   isa         => HashRef[Bool],
   handles_via => 'Hash',
   handles     => { is_serialisable_column => 'get' },
   default     => sub {
      return { map { $_->name => $_->serialised } shift->all_columns };
   };

=item sort_column_name

A mutable simple string which defaults to the first sortable column name

=cut

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

=item sort_desc

A mutable boolean which defaults to false. If true the sort will be in
descending order

=cut

has 'sort_desc' =>
   is      => 'rw',
   isa     => Bool,
   default => sub { shift->_default('sort_desc', FALSE) };

=item sortable

A lazy boolean which is true if the number of sortable columns is greater
than zero

=cut

has 'sortable' =>
   is       => 'lazy',
   isa      => Bool,
   init_arg => undef,
   default  => sub { scalar @{shift->sortable_columns} > 0 };

=item sortable_columns

A lazy array reference of C<Column> objects

=cut

has 'sortable_columns' =>
   is       => 'lazy',
   isa      => ArrayRef[Column],
   init_arg => undef,
   default  => sub {
      return [ grep { $_->sortable && !ref $_->value } shift->all_columns ];
   };

=item title_location

Immutable string which defaults to C<inner>. If set to C<outer> causes the
title and credit control divs to be rendered outside of the top and bottom
control divs

=cut

has 'title_location' => is => 'ro', isa => SimpleStr, default => 'inner';

=item visisble_columns

A lazy array reference of C<Column> objects that are not hidden.

Handles C<all_visible_columns> via the array trait

=cut

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
      _add_role => 'set',
      all_roles => 'keys',
      get_role  => 'get',
   },
   default      => sub { {} };

has '_role_order' =>
   is          => 'ro',
   isa         => ArrayRef[SimpleStr],
   handles_via => 'Array',
   handles     => { add_role_name => 'push', all_role_names => 'elements' },
   default     => sub { [] };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILDARGS

Modifies the method in the base class. Allow the renderer to be specified
without a fully qualified package name

=cut

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

=item BUILD

Called after object instantiation it applies parameters from the query string
in the request object if context has been provided

=cut

sub BUILD {
   my $self = shift;

   $self->apply_params if $self->has_context;
   return;
}

=item add_role( $role_name, $class_name )

Called by the applied table roles this method registers the role and it's
class with the serialiser. Each table role is expected to implement a method
called "serialise_<role_name>"

=cut

sub add_role {
   my ($self, $role_name, $class_name) = @_;

   $self->_add_role($role_name, $class_name);
   $self->add_role_name($role_name);
   return;
}

=item apply_params

If context is provided extracts query parameter values from the request and
applies them to the table attributes

=cut

sub apply_params {
   my $self = shift;

   throw Unspecified, ['context'] unless $self->has_context;

   my $sort = $self->param_value('sort');

   $self->sort_column_name($sort) if $sort;

   my $sort_desc = $self->param_value('desc');

   $self->sort_desc(!!$sort_desc) if $sort;

   my $page = $self->param_value('page');

   $self->page($page) if defined $page && $page =~ m{ \A [0-9]+ \z }mx;

   if (my $page_size = $self->param_value('page_size')) {
      $page_size = 1 if $page_size < 1;
      $page_size = $self->max_page_size if $page_size > $self->max_page_size;
      $self->page_size($page_size);
   }

   return;
}

=item build_prepared_resultset

Applies column SQL, paging, and sorting to the supplied resultset

=cut

sub build_prepared_resultset {
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
   $resultset = $self->_apply_pageing($resultset);
   $resultset = $self->_apply_sorting($resultset) if $self->sortable;

   return $resultset;
}

=item get_displayable_columns

Returns an array reference of displayable column objects

=cut

sub get_displayable_columns {
   my $self = shift;

   return [
      grep { $self->displayable_columns->{$_->name} } @{$self->visible_columns}
   ];
}

=item get_serialisable_columns

Returns an array reference of serialisable column objects

=cut

sub get_serialisable_columns {
   my $self = shift;

   return [
      grep { $self->serialisable_columns->{$_->name} } @{$self->visible_columns}
   ];
}

=item next_result

Call C<next> on the resultset and returns the result

=cut

sub next_result {
   return shift->prepared_resultset->next;
}

=item next_row

Call C<next_result> to obtain the next result object which it uses to
instantiate a row object which it returns

=cut

sub next_row {
   my $self   = shift;
   my $result = $self->next_result;

   return unless defined $result;
 
   return $self->row_class->new( result => $result, table => $self );
}

=item param_value( $name )

If context has been provided returns the named query parameter. Will look for
"<table name>_<param name>" in the query parameters and return it if it
exists. If not will return "<param name>" from the query parameters if that
exists. If that does not exist then returns a null string

=cut

sub param_value {
   my ($self, $name) = @_;

   return unless $self->has_context;

   my $params = $self->request->query_parameters;
   my $value;

   if ($self->name) {
      my $param_key = $self->_param_key($name);

      $value = $params->{$param_key} if exists $params->{$param_key};
   }

   $value = $params->{$name} if !defined $value and exists $params->{$name};

   return trim $value;
}

=item reset_resultset

Resets the resultset so that C<next> can be called again

=cut

sub reset_resultset {
   return shift->prepared_resultset->reset;
}

=item serialiser( $moniker, \&writer, \%args )

Returns the requested serialiser object. The C<moniker> is the serialiser
class without the prefix. The C<writer> is a code reference that is called
to write the serialised output. The C<args> are passed to the constructor
call for the serialiser object

=cut

sub serialiser {
   my ($self, $moniker, $writer, $args) = @_;

   $args //= {};

   throw Unspecified, ['writer callback function']
      unless $writer && is_coderef $writer;

   throw 'Serialiser args must be a hashref' unless $args && is_hashref $args;

   $args->{table}  = $self;
   $args->{writer} = $writer;

   my $class;

   if ('+' eq substr $moniker, 0, 1) { $class = substr $moniker, 1 }
   else { $class = "HTML::StateTable::Serialiser::${moniker}" }

   ensure_class_loaded $class;

   return $class->new($args);
}

=item sort_column( $column_name )

Accessor mutator for C<sort_column_name> attribute. Returns the current sort
column object

=cut

sub sort_column {
   my ($self, $column_name) = @_;

   if ($column_name) {
      my $column = $self->get_column($column_name);

      throw "Selected sort column isn't sortable!" unless $column->sortable;
      $self->sort_column_name($column->name);
   }

   return $self->get_column($self->sort_column_name);
}

=item sorted_columns( @columns )

Returns the list of column objects sorted by their position attribute value

=cut

sub sorted_columns {
   my ($self, @columns) = @_;

   return sort { $a->position <=> $b->position } @columns;
}

# Private methods
sub _apply_column_sql {
   my ($self, $resultset, @columns) = @_;

   @columns = $self->all_visible_columns unless scalar @columns;

   my (@as, @select);

   for my $column (@columns) {
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
   my ($self, $rs) = @_;

   return $rs->search(undef, { page => $self->page }) unless $self->paging;

   return $rs->search(undef, { page => $self->page, rows => $self->page_size });
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

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

See F<dist.ini> for full list

=over 3

=item L<Moo>

=item L<Unexpected>

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
