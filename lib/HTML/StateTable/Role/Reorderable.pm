use utf8; # -*- coding: utf-8; -*-
package HTML::StateTable::Role::Reorderable;

use HTML::StateTable::Types qw( Str );
use Moo::Role;

has 'reorderable_label' => is => 'ro', isa => Str, default => '♋'; # ‡ ♋

has 'reorderable_label_title' => is => 'ro', isa => Str,
   default => 'Drag and drop to reorder columns';

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->does('HTML::StateTable::Role::Configurable');

   $self->add_role('reorderable', __PACKAGE__);
   return;
};

sub serialise_reorderable {
   my $self = shift;

   return {
      label => $self->reorderable_label,
      title => $self->reorderable_label_title,
   };
}

use namespace::autoclean;

1;
