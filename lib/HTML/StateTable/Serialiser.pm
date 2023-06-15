package HTML::StateTable::Serialiser;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool CodeRef Str Table );
use Moo;

has 'disable_paging' => is => 'ro', isa => Bool, default => TRUE;

has 'extension' => is => 'ro', isa => Str, predicate => 'has_extension';

has 'mime_type' => is => 'ro', isa => Str, predicate => 'has_mime_type';

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

has 'writer' => is => 'rwp', isa => CodeRef, required => TRUE;

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

sub serialise_cell {
   my ($self, $cell, $data) = @_;

   $data->{$cell->column->label} = $cell->value;

   return;
}

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

use namespace::autoclean;

1;
