package HTML::StateTable::Column::Meta;

use mro;
use namespace::autoclean;

use HTML::StateTable::Constants qw( COLUMN_META FALSE TRUE );
use HTML::StateTable::Moo::Attribute;
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( throw );
use Moo;

has 'target' => is => 'ro', isa => Str, required => TRUE;

sub find_attribute_by_name {
   my ($self, $attr_name) = @_;

   my $attr = COLUMN_META;

   for my $class ($self->linearised_isa) {
      next unless $class->can($attr);

      my $meta = $class->$attr;

      return $meta->get_attribute($attr_name)
          if $meta->has_attribute($attr_name);
   }

   return;
}

sub get_all_attributes {
   my $self = shift;
   my $con  = $self->_get_constructor;

   return sort keys %{$con->{attribute_specs}};
}

sub get_attribute {
   my ($self, $attr_name) = @_;

   my $con  = $self->_get_constructor;
   my $attr = $con->{attribute_specs}->{$attr_name};

   return HTML::StateTable::Moo::Attribute->new($attr);
}

sub has_attribute {
   my ($self, $attr_name) = @_;

   my $con = $self->_get_constructor;

   return exists $con->{attribute_specs}->{$attr_name} ? TRUE : FALSE;
}

sub linearised_isa {
   my $self       = shift;
   my $target     = $self->target;
   my @target_isa = @{ mro::get_linear_isa($target) };
   my %seen       = ();

   return map { $seen{ $_ }++; $_ } grep { !exists $seen{ $_ } } @target_isa;
}

sub _get_constructor {
   my $self   = shift;
   my $target = $self->target;

   throw 'Not a Moo class'
      unless $Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class};

   return Moo->_constructor_maker_for($target);
}

1;
