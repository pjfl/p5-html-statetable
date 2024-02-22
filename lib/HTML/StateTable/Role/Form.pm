package HTML::StateTable::Role::Form;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str Undef URI );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_arrayref is_hashref );
use Scalar::Util                qw( blessed );
use Moo::Role;

has 'form_action' => is => 'ro', isa => Str, default => 'api/table_action';

has 'form_buttons' =>
   is      => 'lazy',
   isa     => ArrayRef[HashRef|Str]|HashRef[ArrayRef[HashRef|Str]],
   default => sub { [] };

has 'form_confirm_message' => is => 'ro', isa => Str,
   default => 'Are you sure you want to *';

has 'form_control_location' =>
   is      => 'ro',
   isa     => ArrayRef[Str]|Str,
   default => 'Credit';

has 'form_hidden' => is => 'ro', isa => ArrayRef, default => sub { [] };

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('form', __PACKAGE__) if $self->has_context;

   return;
};

sub serialise_form {
   my $self = shift;
   my $name = $self->name;

   return {
      buttons  => $self->_serialise_buttons,
      confirm  => $self->form_confirm_message,
      hidden   => $self->form_hidden,
      location => { control => $self->form_control_location },
      url      => $self->context->uri_for_action($self->form_action, [$name]),
   };
}

# Private methods
sub _serialise_buttons {
   my $self = shift;
   my $list = $self->form_buttons;

   return $self->_serialise_button_list($list) if is_arrayref $list;

   my $buttons = {};

   for my $key (keys %{$list}) {
      $buttons->{$key} = $self->_serialise_button_list($list->{$key});
   }

   return $buttons;
}

sub _serialise_button_list {
   my ($self, $list) = @_;

   my $buttons = [];

   for my $button (@{$list}) {
      my $copy = $button;

      if (is_hashref $button) {
         $copy = { %{$button} };

         if (exists $copy->{selection} && $copy->{selection} =~ m{ \d }mx) {
            if ($copy->{selection}) { $copy->{selection} = 'selection' }
            else { delete $copy->{selection} }
         }
      }

      push @{$buttons}, $copy;
   }

   return $buttons;
}

use namespace::autoclean;

1;
