package HTML::StateTable::Cell;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( Bool Column Date Object Row Str Undef );
use Ref::Util                   qw( is_coderef is_scalarref );
use Type::Utils                 qw( class_type );
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Cell - Cell class

=head1 Synopsis

   use HTML::StateTable::Cell;

=head1 Description

Table cell class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item column

A weak reference to a required immutable column object

=cut

has 'column' => is => 'ro', isa => Column, required => TRUE, weak_ref => TRUE;

=item filtered_value

Returns the cell's unfiltered value after passing it through the column's
filter method if one is defined

=cut

has 'filtered_value' =>
   is      => 'lazy',
   reader  => 'value',
   builder => sub {
      my $self  = shift;
      my $value = $self->unfiltered_value;

      $value = $self->column->filter->($value, $self)
         if $self->column->has_filter;

      return unless defined $value;
      return $value->render if $value->can('render');
      return "${value}";
   };

=item hidden

Calls the C<hidden> method on the column object. Returns a boolean which
indicates whether the column to which this cell belongs is hidden or not

=cut

has 'hidden' => is => 'lazy', isa => Bool, builder => sub {
   my $self   = shift;
   my $column = $self->column;

   return $column->has_hidden ? $column->hidden($self->table) : FALSE;
};

=item link

Either undefined or a lazy L<URI> object. Gets it's value by calling the
C<link> code reference on the column object

=cut

has 'link' => is => 'lazy', isa => class_type('URI')|Undef, builder => sub {
   my $self = shift;

   return unless $self->column->has_link;

   my $link = $self->column->link;

   if (is_coderef $link) { return $link->($self) }
   elsif (!ref $link) { return $link }

   return;
};

=item row

A required weak reference to a row object

=cut

has 'row' => is => 'ro', isa => Row, required => TRUE, weak_ref => TRUE;

=item value

The value of this cell object

=cut

has 'value' =>
   is      => 'lazy',
   isa     => Date|Object|Str|Undef,
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

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Placeholder to be modified by applied traits

=cut

sub BUILD {}

=item has_link

Returns true if this cell has a link

=cut

sub has_link {
   return defined shift->link;
}

=item render_value

Returns the cell value if defined or null otherwise

=cut

sub render_value {
   my $self = shift;

   return defined $self->value ? $self->value : NUL;
}

=item result

Proxy method returning the row's result object

=cut

sub result {
   return shift->row->result;
}

=item serialise_value

Returns the serialised value for the cell

=cut

sub serialise_value {
   my $self  = shift;
   my $value = $self->value;
   my $res   = { value => $value };

   if ($self->result->can('cell_traits')) {
      $res->{cellTraits} = $self->result->cell_traits
         if $self->result->cell_traits->[0];
   }

   $self->serialise_value2hash($value, $res);

   return q() unless exists $res->{value}
      && defined $res->{value} && length $res->{value};

   return 1 == scalar keys %{$res} ? $res->{value} : $res;
}

=item serialise_value2hash

Placeholder method wrapped by applied traits

=cut

sub serialise_value2hash {}

=item table

Proxy method returning the row's table object

=cut

sub table {
   return shift->row->table;
}

use namespace::autoclean;

1;

__END__

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

Copyright (c) 2023 Peter Flanigan. All rights reserved

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
