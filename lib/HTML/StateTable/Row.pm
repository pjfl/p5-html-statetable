package HTML::StateTable::Row;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( ArrayRef ResultObject Table );
use Moo;
use MooX::HandlesVia;

has 'cell_list' =>
   is          => 'lazy',
   isa         => ArrayRef,
   handles_via => 'Array',
   handles     => { cells => 'elements' },
   builder     => sub {
      my $self = shift;
      my @cells;

      for my $column (@{$self->columns}) {
         push @cells,  $self->cell($column);
      }

      return \@cells;
   };

has 'result' => is => 'ro', isa => ResultObject, required => TRUE;

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

sub cell {
   my ($self, $column) = @_;

   return $column->create_cell($self);
}

sub get_cell {
   my ($self, $column_name) = @_;

   for my $cell (@{$self->cell_list}) {
      return $cell if $cell->column->name eq $column_name;
   }

   return;
}

sub columns {
   my $self = shift; return $self->table->columns;
}

sub compound_method {
   my ($self, $methods, @args) = @_;

   my @methods = split m{ \. }mx, $methods;
   my $result  = $self->result;

   while (my $method = shift @methods) {
      return unless defined $result;

      die "Object ${result} has no ${method} method"
         unless $result->can($method);

      my @method_args = @args unless scalar @methods;

      $result = $result->$method(@method_args);
   }

   return $result;
}

1;
