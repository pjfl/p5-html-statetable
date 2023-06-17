package HTML::StateTable::Types;

use strictures;

use Type::Library             -base, -declare =>
                          qw( Column Context Date DBIxClass DBIxClassResultSet
                              Element Iterable Options Renderer Request
                              ResultObject ResultRole ResultSet Row Table
                              URI );
use Type::Utils           qw( as class_type coerce extends from
                              message subtype via where );
use Unexpected::Functions qw( inflate_message );

use namespace::clean -except => 'meta';

BEGIN { extends 'Unexpected::Types' };

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Types - Type declarations

=head1 Synopsis

   use HTML::StateTable::Types;

=head1 Description

Type declarations

=head1 Configuration and Environment

Defines the following types;

=over 3

=item Column

An instance of L<HTML::StateTable::Column>

=cut

class_type Column, { class => 'HTML::StateTable::Column' };

=item Date

An instance of L<DateTime>

=cut

class_type Date, { class => 'DateTime' };

=item DBIxClass

An instance of L<DBIx::Class>

=cut

class_type DBIxClass, { class => 'DBIx::Class' };

=item DBIxClassResultSet

An instance of L<DBIx::Class::ResultSet>

=cut

class_type DBIxClassResultSet, { class => 'DBIx::Class::ResultSet' };

=item Renderer

An instance of L<HTML::StateTable::Renderer>

=cut

class_type Renderer, { class => 'HTML::StateTable::Renderer' };

=item Row

An instance of L<HTML::StateTable::Row>

=cut

class_type Row, { class => 'HTML::StateTable::Row' };

=item Table

An instance of L<HTML::StateTable>

=cut

class_type Table, { class => 'HTML::StateTable' };

=item URI

An instance of L<URI>

=cut

class_type URI, { class => 'URI' };

=item Context

A subtype of C<Object>

=cut

subtype Context => as Object;

=item Request

A subtype of C<Object>

=cut

subtype Request => as Object;

=item Iterable

Duck type for an object that can be used in place of a
L<DBIx::Class::ResultSet>

=cut

subtype Iterable => as Object, where {
      $_->can('get_column')
   && $_->can('next')
   && $_->can('pager')
   && $_->can('reset')
   && $_->can('result_source')
   && $_->can('search')
};

=item Options

A subtype of hash reference which can be coerced from an array reference of
keys

=cut

subtype Options => as HashRef;

coerce Options => from ArrayRef, via { { map { $_ => 1 } @{$_} } };

=item ResultRole

A subtype of object which does L<HTML::StateTable::Result::Role>

=cut

subtype ResultRole => as Object, where {
   $_->does('HTML::StateTable::Result::Role')
};

=item ResultObject

A subtype of object which is either a C<DBIxClass> type or a C<ResultRole>
type

=cut

subtype ResultObject => as Object, where { DBIxClass | ResultRole };

=item ResultSet

A subtype of object which is either a C<DBIxClassResultSet> type or an
C<Iterable> type

=cut

subtype ResultSet => as Object, where { DBIxClassResultSet | Iterable };

1;

__END__

=back

=head1 Subroutines/Methods

Defines no functions or methods

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Type::Tiny>

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
