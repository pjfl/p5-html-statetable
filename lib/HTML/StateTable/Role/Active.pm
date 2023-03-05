package HTML::StateTable::Role::Active;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool Str );
use HTML::StateTable::Util      qw( json_bool );
use Moo::Role;

has 'active_control_location' => is => 'ro', isa => Str, default => 'TopLeft';

has 'active_enabled' => is => 'ro', isa => Bool, default => TRUE;

has 'active_label' => is => 'ro', isa => Str, default => 'View Inactive';

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->active_enabled;

   $self->add_role('active', __PACKAGE__);
   return;
};

around 'build_prepared_resultset' => sub {
   my ($orig, $self) = @_;

   my $rs = $orig->($self);

   return $rs->active
      if !$self->param_value('show_inactive') && $rs->can('active');

   return $rs;
};

sub is_row_active {
   my ($self, $row) = @_;

   return $row->result->can('active') ? $row->result->active : TRUE;
}

sub serialise_active {
   my $self = shift;

   return {
      enabled  => json_bool $self->active_enabled,
      label    => $self->active_label,
      location => { control => $self->active_control_location },
   };
}

use namespace::autoclean;

1;
