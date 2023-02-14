package HTML::StateTable::Cell;

use namespace::autoclean;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( Column Row Undef);
use Ref::Util                   qw( is_coderef );
use Type::Utils                 qw( class_type );
use Moo;

has 'column' => is => 'ro', isa => Column, required => TRUE, weak_ref => TRUE;

has 'link' => is => 'lazy', isa => class_type('URI')|Undef, builder => sub {
   my $self = shift;

   return unless $self->column->has_link;

   my $link = $self->column->link;

   if (is_coderef $link) { return $link->($self) }
   elsif (!ref $link) { return $link }

   return;
};

has 'row' => is => 'ro', isa => Row, required => TRUE, weak_ref => TRUE;

sub has_link {
   return defined shift->link;
}

sub result {
   return shift->row->result;
}

sub table {
   return shift->row->table;
}

1;
