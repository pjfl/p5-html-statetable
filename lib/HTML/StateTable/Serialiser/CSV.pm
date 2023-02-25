package HTML::StateTable::Serialiser::CSV;

use HTML::StateTable::Constants qw( COMMA DQUOTE EOL FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Column Str );
use HTML::StateTable::Util      qw( escape_formula );
use Type::Utils                 qw( class_type );
use Text::CSV_XS;
use Moo;

extends 'HTML::StateTable::Serialiser::Base';

has '+mime_type' => default => 'text/csv';

has 'columns' =>
   is      => 'lazy',
   isa     => ArrayRef[Str],
   default => sub { [ map { $_->name } @{shift->_serialisable_columns} ] };

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

has 'headers' =>
   is      => 'lazy',
   isa     => ArrayRef[Str],
   default => sub { [ map { $_->label } @{shift->_serialisable_columns} ] };

has '_serialisable_columns' =>
   is      => 'lazy',
   isa     => ArrayRef[Column],
   default => sub { shift->table->get_serialisable_columns };

before 'serialise' => sub { shift->write_headers };

around 'serialise_row' => sub {
   my ($orig, $self, $row, $row_number) = @_;

   my $record = $orig->($self, $row, $row_number);
   my @fields = escape_formula @{$record}{@{$self->columns}};

   $self->_csv->combine(@fields);

   return $self->_csv->string;
};

sub serialise_cell {
   my ($self, $cell, $row_data) = @_;

   $row_data->{$cell->column->name} = $cell->unfiltered_value;

   return;
}

sub write_headers {
   my $self    = shift;
   my @headers = @{$self->headers};

   $headers[0] = 'id' if $headers[0] eq 'ID';

   $self->_csv->combine(@headers);
   $self->writer->("\x{FEFF}");    #BOM
   $self->writer->($self->_csv->string);
}

use namespace::autoclean;

1;
