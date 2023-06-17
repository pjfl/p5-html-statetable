package HTML::StateTable::Serialiser::JSON;

use HTML::StateTable::Constants qw( FALSE NUL PIPE TRUE );
use HTML::StateTable::Types     qw( Bool HashRef Object Str );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_hashref );
use JSON::MaybeXS;
use Moo;

extends qw'HTML::StateTable::Serialiser';

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Serialiser::JSON - Serialise a table object in JSON format

=head1 Synopsis

   use HTML::StateTable::Serialiser::JSON;

=head1 Description

Serialise a table object in JSON format

=head1 Configuration and Environment

Extends L<HTML::StateTable::Serialiser>. Defines the following attributes;

=over 3

=item mime_type

Overrides the default in the parent class setting the value to
'application/json'

=item has_mime_type

Predicate

=cut

has '+mime_type' => default => 'application/json';

=item filter_column

An immutable string without default. If set, it is the name of the column for
which a sorted and unique list of values will be returned

=cut

has 'filter_column' => is => 'ro', isa => Str;

=item serialise_as_hashref

An immutable boolean which defaults true. Wraps the list of serialised records
in a hash reference and includes the total record count. If false an array
reference of serialised records is returned

=cut

has 'serialise_as_hashref' => is => 'ro', isa => Bool, default => TRUE;

=item serialise_meta

An immutable boolean which defaults false. If true the table meta data will
be serialised instead of the data records

=cut

has 'serialise_meta' => is => 'ro', isa => Bool, default => FALSE;

=item serialise_record_key

An immutable string which defaults to 'name'. Can be set to 'label'. Selects
the column attribute whose value is used as the key in the output data

=cut

has 'serialise_record_key' => is => 'ro', isa => Str, default => 'name';

has '_json' => is => 'ro', isa => Object, default => sub {
   return JSON::MaybeXS->new( convert_blessed => TRUE );
};

has '_tags' =>
   is      => 'rwp',
   isa     => HashRef,
   writer  => '_set_tags',
   default => sub { {} };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item serialise

Wraps the call to the method in the parent class. Will either serialise the
filter column values, or serialise the table meta data, or call the parent
method possibly also outputting a hash reference with a row count

=cut

around 'serialise' => sub {
   my ($orig, $self) = @_;

   my $table = $self->table;

   return $self->_serialise_filter($table) if $self->filter_column;
   return $self->_serialise_meta($table)   if $self->serialise_meta;

   if ($self->serialise_as_hashref) {
      my $total = $table->no_count ? 0 : $table->row_count;

      $self->writer->('{"row-count":' . $total . ',"records":');
   }

   $self->writer->('[');

   my $index = $orig->($self);

   $self->writer->(']');
   $self->writer->('}') if $self->serialise_as_hashref;

   return $index;
};

=item serialise_row( $row, $index )

Wraps around the method in the parent class. Extracts and sets C<tags> from
the row object. Adds booleans for the active and highlight row table roles
if applied. JSON encodes the return data

=cut

around 'serialise_row' => sub {
   my ($orig, $self, $row, $index) = @_;

   $self->_set_tags($self->_extract_tags($row));

   my $data = $orig->($self, $row, $index);

   $data->{_highlight} = json_bool $self->table->highlight_row($row)
      if $self->table->does('HTML::StateTable::Role::HighlightRow');

   $data->{_inactive} = json_bool !$self->table->is_row_active($row)
      if $self->table->does('HTML::StateTable::Role::Active');

   $row = $self->_json->encode($data);
   $row = ",${row}" unless $index == 0;

   return $row;
};

=item serialise_cell( $cell, $data )

Stores the cell value in the data hash reference keyed by either the column
label or the column name. Links and tags are also added to the data if
available

=cut

sub serialise_cell {
   my ($self, $cell, $data) = @_;

   my $column = $cell->column;
   my $key    = $self->serialise_record_key eq 'label'
      ? $column->label : $column->name;
   my $value  = $cell->serialise_value;

   $value = _store_value_as_hash($value, link => $cell->link->as_string)
      if $cell->has_link;

   $value = _store_value_as_hash($value, tags => $self->_tags->{$column->name})
      if exists $self->_tags->{$column->name};

   $data->{$key} = $value;
   return;
}

=item skip_serialise_cell( $cell )

Returns true if column C<append_to> is set or the column is hidden

=cut

sub skip_serialise_cell {
   my ($self, $cell) = @_;

   return $cell->column->append_to || $cell->column->hidden($self->table);
}

# Private methods
sub _extract_tags {
   my ($self, $row) = @_;

   my $displayable_columns = $self->table->displayable_columns;
   my $sep  = PIPE;
   my %tags = ();

   for my $cell (grep { !$_->hidden && $_->unfiltered_value } $row->cells) {
      my $column = $cell->column;
      my $value  = $cell->unfiltered_value;

      $tags{$column->append_to} = [ split m{ \Q$sep\E }mx, $value ]
         if $column->append_to && $displayable_columns->{$column->name};
   }

   return \%tags;
}

sub _serialise_filter {
   my ($self, $table) = @_;

   my $records = $table->filter_column_values($self->filter_column);

   $self->writer->($self->_json->encode({ records => $records }));

   return TRUE;
}

sub _serialise_meta {
   my ($self, $table) = @_;

   $self->writer->($self->_json->encode({
      'column-order' => [ map { $_->name } @{$table->get_displayable_columns} ],
      'displayed'    => {
         map   { $_  => json_bool $table->displayable_columns->{$_}}
         keys %{$table->displayable_columns}
      },
      'downloadable' => {
         map   { $_  => json_bool $table->serialisable_columns->{$_}}
         keys %{$table->serialisable_columns}
      },
      'page-size'    => $table->page_size,
      'sort-column'  => $table->sort_column_name,
      'sort-desc'    => json_bool $table->sort_desc,
   }));
   return TRUE;
}

sub _store_value_as_hash {
   my ($store, $key, $value) = @_;

   if (is_hashref $store) { $store->{$key} = $value }
   else { $store = { $key => $value, value => $store } }

   return $store;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<JSON::MaybeXS>

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
