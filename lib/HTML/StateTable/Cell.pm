package HTML::StateTable::Cell;

use namespace::autoclean;

use HTML::StateTable::Constants qw( NUL TRUE );
use HTML::StateTable::Types     qw( Column Date Row Str Undef );
use Ref::Util                   qw( is_coderef is_scalarref );
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

has 'value' => is => 'lazy', isa => Date|Str|Undef, builder => sub {
   my $self  = shift;
   my $value = $self->column->value;

   return $value->($self) if is_coderef $value;

   return ${$value} if is_scalarref $value;

   return $self->row->result->get_column($self->column->as)
      if $self->column->is_generated;

   return $self->row->compound_method($value) if !ref $value;

   return;
};

sub has_link {
   return defined shift->link;
}

sub render_value {
   my $self = shift;

   return defined $self->value ? $self->value : NUL;
}

sub result {
   return shift->row->result;
}

sub table {
   return shift->row->table;
}

1;
