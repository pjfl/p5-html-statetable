package HTML::StateTable::Serialiser;

use namespace::autoclean;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool CodeRef Str Table );
use HTML::StateTable::Util      qw( throw );
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

   while (my $row = $table->next_row) {
      $writer->($self->serialise_row($row, $row_number));
      $row_number++;
   }

   $table->reset_resultset;

   return $row_number;
}

sub serialise_row {
   throw 'Should have been overridden in a subclass';
}

1;
