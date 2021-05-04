package HTML::StateTable::Renderer;

use namespace::autoclean;

use HTML::StateTable::Constants qw( ENCODE_ENTITIES INDENT_CHARS TRUE );
use HTML::StateTable::Types     qw( Element HashRef Str Table );
use HTML::Element;
use Moo;

has 'container_tag' => is => 'ro', isa => Str, default => 'table';

has 'container' =>
   is      => 'lazy',
   isa     => Element,
   default => sub {
      my $self = shift;

      return HTML::Element->new_from_lol([$self->container_tag, $self->data]);
   };

has 'data' => is => 'lazy', isa => HashRef, default => sub { {} };

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

sub render {
   my $self = shift;

	return $self->container->as_HTML(ENCODE_ENTITIES, INDENT_CHARS);
}

1;
