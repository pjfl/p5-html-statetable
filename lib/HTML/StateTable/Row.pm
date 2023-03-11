package HTML::StateTable::Row;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( ArrayRef ResultObject Table );
use Moo;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Row - Row class

=head1 Synopsis

   use HTML::StateTable::Row;

=head1 Description

Table row class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item cell_list

A lazy array reference of cell objects

Handles C<cells> via the array trait

=cut

has 'cell_list' =>
   is          => 'lazy',
   isa         => ArrayRef,
   handles_via => 'Array',
   handles     => { cells => 'elements' },
   builder     => sub {
      my $self = shift;
      my @cells;

      for my $column (@{$self->columns}) {
         push @cells,  $self->cell($column);
      }

      return \@cells;
   };

=item result

An immutable L<DBIx::Class::Result> object

=cut

has 'result' => is => 'ro', isa => ResultObject, required => TRUE;

=item table

An immutable L<HTML::StateTable> object

=cut

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

=back

=head1 Subroutines/Methods

Defines the following functions;

=over 3

=item cell( column )

Takes a column object an uses it to create a new cell object which it returns

=cut

sub cell {
   my ($self, $column) = @_;

   return $column->create_cell($self);
}

=item get_cell( column_name )

Searches the list of cells for one with a matching C<column_name>

=cut

sub get_cell {
   my ($self, $column_name) = @_;

   for my $cell (@{$self->cell_list}) {
      return $cell if $cell->column->name eq $column_name;
   }

   return;
}

=item columns

Returns an array reference of column objects

=cut

sub columns {
   my $self = shift; return $self->table->columns;
}

=item compound_method( methods, @args )

Splits the C<methods> argument on dot and descends into the result object.
Calls the final method in the list passing in the supplied C<args>

=cut

sub compound_method {
   my ($self, $methods, @args) = @_;

   my @methods = split m{ \. }mx, $methods;
   my $result  = $self->result;

   while (my $method = shift @methods) {
      return unless defined $result;

      die "Object ${result} has no ${method} method"
         unless $result->can($method);

      my @method_args = @args unless scalar @methods;

      $result = $result->$method(@method_args);
   }

   return $result;
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
