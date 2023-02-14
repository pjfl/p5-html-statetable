package HTML::StateTable::Serialiser::Base;

use namespace::autoclean;

use HTML::StateTable::Constants qw( FALSE TRUE );
use Moo;

extends qw( HTML::StateTable::Serialiser );

sub serialise_row {
   my ($self, $row, $index) = @_;

   my $data = {};

   for my $cell ($row->cells) {
      next if $self->skip_serialise_cell($cell);

      $self->serialise_cell($cell, $data);
   }

   return $data;
}

sub skip_serialise_cell {
   my ($self, $cell) = @_;

   my $table = $self->table;

   return TRUE if $cell->column->hidden($table);
   return TRUE unless $table->serialisable_columns->{$cell->column->name};
   return FALSE;
}

sub serialise_cell {
   my ($self, $cell, $data) = @_;

   $data->{$cell->column->label} = $cell->value;

   return;
}

1;
