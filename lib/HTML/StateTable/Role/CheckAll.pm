package HTML::StateTable::Role::CheckAll;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Util      qw( json_bool );
use Moo::Role;

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('checkall', __PACKAGE__);
};

sub serialise_checkall {
   return { apply => { before => json_bool TRUE }, role_name => 'CheckAll' };
}

use namespace::autoclean;

1;
