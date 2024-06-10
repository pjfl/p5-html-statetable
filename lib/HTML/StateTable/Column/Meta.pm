package HTML::StateTable::Column::Meta;

use mro;

use HTML::StateTable::Constants qw( COLUMN_META FALSE TRUE );
use HTML::StateTable::Types     qw( Str );
use HTML::StateTable::Util      qw( throw );
use HTML::StateTable::Moo::Attribute;
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Column::Meta - Column meta class

=head1 Synopsis

   use HTML::StateTable::Column::Meta;

=head1 Description

Column meta class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item target

An immutable required string. The name of the consuming class

=cut

has 'target' => is => 'ro', isa => Str, required => TRUE;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item find_attribute_by_name( $attribute_name )

Iterates over the C<linearised_isa> looking for the column meta object. If it
is found and C<has_attribute> returns true, returns the value of
C<get_attribute>. Otherwise returns undefined

=cut

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

=item get_attribute( $attribute_name )

Returns an instance of L<HTML::StateTable::Moo::Attribute> if the target class
C<has_attribute>

=cut

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

=item has_attribute( $attribute_name )

Returns true if the target has the named attribute false otherwise

=cut

sub has_attribute {
   my ($self, $attr_name) = @_;

   if ($self->_is_class) {
      my $con = $self->_get_constructor;

      return exists $con->{attribute_specs}->{$attr_name} ? TRUE : FALSE;
   }

   return $self->target->can($attr_name) ? TRUE : FALSE;
}

=item linearised_isa

Calls L<mro/get_linear_isa> on the target class. Returns a list of the unique
entries

=cut

sub linearised_isa {
   my $self       = shift;
   my $target     = $self->target;
   my @target_isa = @{ mro::get_linear_isa($target) };
   my %seen       = ();

   return map { $seen{ $_ }++; $_ } grep { !exists $seen{ $_ } } @target_isa;
}

# Private methods
sub _get_all_attributes {
   my $self = shift;
   my $con  = $self->_get_constructor;

   return sort keys %{$con->{attribute_specs}};
}

sub _get_constructor {
   my $self = shift;

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

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-StateTable.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2024 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
