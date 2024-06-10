package HTML::StateTable::Serialiser;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool CodeRef Str Table );
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Serialiser - Serialise a table object

=head1 Synopsis

   use Moo;

   extends 'HTML::StateTable::Serialiser';

=head1 Description

Serialise a table object base class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item disable_paging

An immutable boolean which default true. If true paging is disabled and all
records in the resultset are serialised

=cut

has 'disable_paging' => is => 'ro', isa => Bool, default => TRUE;

=item extension

An immutable string without default. Optional filename extension for downloads

=item has_extension

Predicate

=cut

has 'extension' => is => 'ro', isa => Str, predicate => 'has_extension';

=item mime_type

An immutable string without default. Set by the subclass

=item has_mime_type

Predicate

=cut

has 'mime_type' => is => 'ro', isa => Str, predicate => 'has_mime_type';

=item table

An immutable required weak reference to the table object

=cut

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

=item writer

An immutable required code reference with a private setter

=cut

has 'writer' => is => 'rwp', isa => CodeRef, required => TRUE;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item serialise

Repeatedly calls C<next_row> on the table object until the iterator is
exhausted. Calls C<serialise_row> passing in the row and a running count
of the number of rows. Calls the C<writer> with the return value from
C<serialise_row>

=cut

sub serialise {
   my $self       = shift;
   my $table      = $self->table;
   my $writer     = $self->writer;
   my $row_number = 0;

   $table->paging(FALSE) if $self->disable_paging;

   $table->force_row_limit
      if $table->does('HTML::StateTable::Role::ForceRowLimit');

   while (my $row = $table->next_row) {
      $writer->($self->serialise_row($row, $row_number));
      $row_number++;
   }

   $table->reset_resultset;

   return $row_number;
}

=item serialise_cell( $cell, $data )

Adds the cell value to the data hash reference keyed by the column label

=cut

sub serialise_cell {
   my ($self, $cell, $data) = @_;

   $data->{$cell->column->label} = $cell->value;

   return;
}

=item serialise_row( $row, $index )

Repeatedly calls C<serialise_cell> for each cell in the supplied row. Will
not serialise a cell if C<skip_serialise_cell> returns false

=cut

sub serialise_row {
   my ($self, $row, $index) = @_;

   my $data = {};

   for my $cell ($row->cells) {
      next if $self->skip_serialise_cell($cell);

      $self->serialise_cell($cell, $data);
   }

   return $data;
}

=item skip_serialise_cell( $cell )

Returns true if the cell's column is hidden or the column is not listed as
serialisable. Returns false otherwise

=cut

sub skip_serialise_cell {
   my ($self, $cell) = @_;

   my $table = $self->table;

   return TRUE if $cell->column->hidden($table);
   return TRUE unless $table->serialisable_columns->{$cell->column->name};
   return FALSE;
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

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
