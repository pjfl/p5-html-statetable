package HTML::StateTable::Role::Form;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str Undef URI );
use HTML::StateTable::Util      qw( json_bool );
use Ref::Util                   qw( is_hashref );
use Scalar::Util                qw( blessed );
use Moo::Role;

has 'form_buttons' =>
   is      => 'lazy',
   isa     => ArrayRef[HashRef|Str],
   default => sub { [] };

has 'form_confirm_message' => is => 'ro', isa => Str,
   default => 'Are you sure you want to *';

has 'form_control_location' => is => 'ro', isa => Str, default => 'Credit';

has 'form_hidden' => is => 'ro', isa => ArrayRef, default => sub { [] };

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('form', __PACKAGE__) if $self->has_context;
};

sub serialise_form {
   my $self    = shift;
   my $name    = $self->name;
   (my $url    = $self->context->table_form_url) =~ s{ \* }{$name}mx;
   my $buttons = [];

   for my $button (@{$self->form_buttons}) {
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

   return {
      buttons      => $buttons,
      confirm      => $self->form_confirm_message,
      hidden       => $self->form_hidden,
      location     => { control => $self->form_control_location },
      'table-name' => $name,
      url          => $url,
   };
}

use namespace::autoclean;

1;
