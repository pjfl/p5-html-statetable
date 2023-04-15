package HTML::StateTable::Role::Animation;

use Moo::Role;

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('animation', __PACKAGE__);
   return;
};

sub serialise_animation {
   my $self = shift;

   return {};
}

use namespace::autoclean;

1;
