package HTML::StateTable::Role::Reorderable;

use utf8; # -*- coding: utf-8; -*-

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use Moo::Role;

has 'reorderable' => is => 'ro', isa => Bool, default => TRUE;

has 'reorderable_label_title' => is => 'ro', isa => Str,
   default => 'Drag and drop to reorder columns';

around 'sorted_columns' => sub {
   my ($orig, $self, @columns) = @_;

   my $index    = 0;
   my $position = {};
   my $params   = $self->configurable_params;

   for my $column_name (@{$params->{column_order} // []}) {
      $position->{$column_name} = $index++;
   }

   return @columns unless scalar keys %{$position};

   return map { $_->[1] } sort { $a->[0] <=> $b->[0] }
          map { [ $position->{$_->name} // $index++, $_ ] } @columns;
};

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->reorderable
      && $self->does('HTML::StateTable::Role::Configurable');

   $self->add_role('reorderable', __PACKAGE__);
   return;
};

sub serialise_reorderable {
   my $self = shift;

   return {
      title => $self->reorderable_label_title,
   };
}

use namespace::autoclean;

1;
