package HTML::StateTable::Meta;

use mro;

use HTML::StateTable::Types qw( ArrayRef CodeRef Column HashRef
                                NonEmptySimpleStr );
use Moo;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Meta - Table meta class

=head1 Synopsis

   use HTML::StateTable::Meta;

=head1 Description

Table meta class

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item columns

A mutable array reference of column object references

Handles; C<add_column>, C<all_columns>, C<clear_columns>, C<grep_column>, and
C<has_column>

=cut

has 'columns' =>
   is            => 'rw',
   isa           => ArrayRef[Column],
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_column    => 'push',
      all_columns   => 'elements',
      clear_columns => 'clear',
      grep_column   => 'grep',
      has_column    => 'count',
   };

=item default_options

An immutable hash reference with an empty default

Handles; C<default_exists>, C<get_default>, and C<set_default>

=cut

has 'default_options' =>
   is          => 'rwp',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => {
      default_exists => 'exists',
      get_default    => 'get',
      set_default    => 'set',
   },
   default     => sub { {} };

=item filters

A mutable hash reference with an empty default

Handles: C<add_filter>

=cut

has 'filters' =>
   is          => 'rw',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => { add_filter => 'set' },
   default     => sub { {} };

=item resultset_callback

An immutable code reference with a private setter. When called it is expected
to return either a L<DBIx::Class::ResultSet> or an object of type C<Iterable>

=item has_resultset_callback

Predicate

=cut

has 'resultset_callback' =>
   is        => 'rwp',
   isa       => CodeRef,
   predicate => 'has_resultset_callback';

=item table_name

An immutable non empty simple string with a private setter. The name of the
table

=cut

has 'table_name' => is => 'rwp', isa => NonEmptySimpleStr;

use namespace::autoclean;

1;

=back

=head1 Subroutines/Methods

Defines no methods or functions;

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
