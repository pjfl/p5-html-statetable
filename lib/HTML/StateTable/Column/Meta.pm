package HTML::StateTable::Column::Meta;

use mro;

use HTML::StateTable::Constants qw( COLUMN_META FALSE TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( throw );
use HTML::StateTable::Moo::Attribute;
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

   if ($self->_is_class) {
      my $con  = $self->_get_constructor;
      my $attr = $con->{attribute_specs}->{$attr_name};

      return HTML::StateTable::Moo::Attribute->new($attr);
   }

   if (my $info = $Role::Tiny::INFO{$self->target}) {
      my @attributes = @{$info->{attributes}};

      while (my $name = shift @attributes) {
         my $attr = shift @attributes;

         return HTML::StateTable::Moo::Attribute->new($attr)
            if $name eq $attr_name;
      }
   }

   return;
}

sub has_attribute {
   my ($self, $attr_name) = @_;

   if ($self->_is_class) {
      my $con = $self->_get_constructor;

      return exists $con->{attribute_specs}->{$attr_name} ? TRUE : FALSE;
   }

   return $self->target->can($attr_name) ? TRUE : FALSE;
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

   throw 'Not a Moo class [_1]', [$self->target], level => 3
      unless $self->_is_class;

   return Moo->_constructor_maker_for($self->target);
}

sub _is_class {
   my $self   = shift;
   my $target = $self->target;

   return $Moo::MAKERS{$target} && $Moo::MAKERS{$target}{is_class}
        ? TRUE : FALSE;
}

use namespace::autoclean;

1;
