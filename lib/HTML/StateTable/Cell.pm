package HTML::StateTable::Cell;

use namespace::autoclean;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( Bool Column Date Row Str Undef );
use Ref::Util                   qw( is_coderef is_scalarref );
use Type::Utils                 qw( class_type );
use Moo;

has 'column' => is => 'ro', isa => Column, required => TRUE, weak_ref => TRUE;

has 'hidden' => is => 'lazy', isa => Bool, builder => sub {
   my $self   = shift;
   my $column = $self->column;

   return $column->has_hidden ? $column->hidden($self->table) : FALSE;
};

has 'link' => is => 'lazy', isa => class_type('URI')|Undef, builder => sub {
   my $self = shift;

   return unless $self->column->has_link;

   my $link = $self->column->link;

   if (is_coderef $link) { return $link->($self) }
   elsif (!ref $link) { return $link }

   return;
};

has 'row' => is => 'ro', isa => Row, required => TRUE, weak_ref => TRUE;

has 'value' =>
   is      => 'lazy',
   isa     => Date|Str|Undef,
   reader  => 'unfiltered_value',
   builder => sub {
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

   return defined $self->unfiltered_value ? $self->unfiltered_value : NUL;
}

sub result {
   return shift->row->result;
}

sub serialise_value {
   my $self  = shift;
   my $value = $self->unfiltered_value;
   my $res   = { value => $value };

   $self->serialise_value_hash($value, $res);

   return q() unless exists $res->{value}
      && defined $res->{value} && length $res->{value};

   return 1 == scalar keys %{$res} ? $res->{value} : $res;
}

sub serialise_value_hash {}

sub table {
   return shift->row->table;
}

1;
