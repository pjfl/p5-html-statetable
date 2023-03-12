package HTML::StateTable::Role::HighlightRow;

use Moo::Role;

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('highlightrow', __PACKAGE__);
};

sub serialise_highlightrow {
   return { 'role-name' => 'HighlightRow' };
}

use namespace::autoclean;

1;
