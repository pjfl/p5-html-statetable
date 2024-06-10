package HTML::StateTable::Renderer;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( ArrayRef HashRef Str Table );
use HTML::StateTable::Util      qw( throw );
use Type::Utils                 qw( class_type );
use HTML::Tiny;
use Try::Tiny;
use Moo;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Renderer - Renders the table

=head1 Synopsis

   use HTML::StateTable::Renderer;

=head1 Description

Table render class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item container_tag

Which HTML element to wrap the rows in. Defaults to C<table>

=cut

has 'container_tag' => is => 'ro', isa => Str, default => 'table';

=item container

The HTML C<container_tag>, applied attributes C<data>, and the table
C<rows> rendered as an HTML string

=cut

has 'container' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;
      my $tag  = $self->container_tag;

      return $self->_html->$tag($self->data, $self->rows);
   };

=item data

A hash reference of keys and values applied to the attributes of the
C<container>

=cut

has 'data' => is => 'lazy', isa => HashRef, default => sub { {} };

=item rows

An array reference of rendered HTML row elements

=cut

has 'rows' => is => 'lazy', isa => ArrayRef, default => sub { [] };

=item table

A required weak reference to the table being rendered

=cut

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

# Private attributes
has '_html' =>
   is      => 'ro',
   isa     => class_type('HTML::Tiny'),
   default => sub { HTML::Tiny->new };

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item render

Returns the result of evaluating the C<container> attribute

=cut

sub render {
   my $self = shift;
   my $output;

   try   { $output = $self->container }
   catch {
      my $table = $self->table;

      $table->log->error("${_}", $table->context) if $table->has_log;
      throw "${_}";
   };

   return $output;
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
