package HTML::StateTable::Renderer;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str Table );
use Type::Utils                 qw( class_type );
use HTML::Tiny;
use Try::Tiny;
use Moo;

has 'container_tag' => is => 'ro', isa => Str, default => 'table';

has 'container' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;
      my $tag  = $self->container_tag;

      return $self->_html->$tag($self->data, $self->rows);
   };

has 'data' => is => 'lazy', isa => HashRef, default => sub { {} };

has 'rows' => is => 'lazy', isa => ArrayRef, default => sub { [] };

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

has '_html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

sub render {
   my $self = shift;
   my $output;

   try   { $output = $self->container }
   catch { $output = $_ };

   return $output;
}

use namespace::autoclean;

1;
