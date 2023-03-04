package HTML::StateTable::Role::Form;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str Undef URI );
use Scalar::Util                qw( blessed );
use Moo::Role;

has 'form_buttons' =>
   is      => 'lazy',
   isa     => ArrayRef[HashRef|Str],
   default => sub { [] };

has 'form_control_location' => is => 'ro', isa => Str, default => 'Credit';

has 'form_hidden' => is => 'ro', isa => ArrayRef, default => sub { [] };

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('form', __PACKAGE__) if $self->has_context;
};

sub serialise_form {
   my $self = shift;
   my $name = $self->name;
   (my $url = $self->context->table_form_url) =~ s{ \* }{$name}mx;

   return {
      buttons      => $self->form_buttons,
      hidden       => $self->form_hidden,
      location     => { control => $self->form_control_location },
      'table-name' => $name,
      url          => $url,
   };
}

use namespace::autoclean;

1;
