package HTML::StateTable::Serialiser::CSV;

use HTML::StateTable::Constants qw( COMMA DQUOTE EOL FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Column Str );
use HTML::StateTable::Util      qw( escape_formula );
use Type::Utils                 qw( class_type );
use Text::CSV_XS;
use Moo;

extends 'HTML::StateTable::Serialiser';

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Serialiser::CSV - Serialise a table object in CSV format

=head1 Synopsis

   use HTML::StateTable::Serialiser::CSV;

=head1 Description

Serialise a table object in CSV format

=head1 Configuration and Environment

Extends L<HTML::StateTable::Serialiser>. Defines the following attributes;

=over 3

=item mime_type

Overrides the default in the parent class setting the value to 'text/csv'

=item has_mime_type

Predicate

=cut

has '+mime_type' => default => 'text/csv';

=item columns

An array reference of string. The list of serialisable column names

=cut

has 'columns' =>
   is      => 'lazy',
   isa     => ArrayRef[Str],
   default => sub { [ map { $_->name } @{shift->_serialisable_columns} ] };

=item headers

An array reference of string. The list of serialisable column labels

=cut

has 'headers' =>
   is      => 'lazy',
   isa     => ArrayRef[Str],
   default => sub { [ map { $_->label } @{shift->_serialisable_columns} ] };

has '_csv' =>
   is      => 'ro',
   isa     => class_type('Text::CSV_XS'),
   default => sub {
      Text::CSV_XS->new({
         always_quote => TRUE,
         binary       => TRUE,
         eol          => EOL,
         escape_char  => DQUOTE,
         quote_char   => DQUOTE,
         sep_char     => COMMA,
      });
   };

has '_serialisable_columns' =>
   is      => 'lazy',
   isa     => ArrayRef[Column],
   default => sub { shift->table->get_serialisable_columns };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item serialise

Before executing the method in the parent class, write the header line to
the output

=cut

before 'serialise' => sub { shift->_write_headers };

=item serialise_row

Modifies the method in the parent class. Takes the record returned from the
parent method, escapes any formulas, adds the data to the private CSV object
and then stringifies it returning the result

=cut

around 'serialise_row' => sub {
   my ($orig, $self, $row, $row_number) = @_;

   my $record = $orig->($self, $row, $row_number);

   $self->_csv->combine(escape_formula @{$record}{@{$self->columns}});

   return $self->_csv->string;
};

=item serialise_cell

Overrides the parent method. Sets the row data for the supplied cells column
name to the cells unfiltered value

=cut

sub serialise_cell {
   my ($self, $cell, $row_data) = @_;

   $row_data->{$cell->column->name} = $cell->unfiltered_value;

   return;
}

# Private methods
sub _write_headers {
   my $self    = shift;
   my @headers = @{$self->headers};

   $headers[0] = 'id' if $headers[0] eq 'ID';

   $self->_csv->combine(@headers);
   $self->writer->("\x{FEFF}"); # Byte object mark. Stupid MS
   $self->writer->($self->_csv->string);
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Text::CSV_XS>

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
