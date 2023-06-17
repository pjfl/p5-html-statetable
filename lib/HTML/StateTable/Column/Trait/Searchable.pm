package HTML::StateTable::Column::Trait::Searchable;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool CodeRef Str );
use HTML::StateTable::Util      qw( throw );
use Ref::Util                   qw( is_coderef );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Column::Trait::Searchable - Searches column values

=head1 Synopsis

   use Moo;

   with 'HTML::StateTable::Column::Trait::Searchable';

=head1 Description

Searches column values

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item searchable

=cut

has 'searchable' => is => 'ro', isa => Bool|CodeRef,
   reader => '_get_searchable';

=item search_query

=cut

has 'search_query' =>
   is      => 'lazy',
   isa     => CodeRef,
   default => sub {
      return sub {
         my ($self, $name, $value) = @_;

         my $method = '_build_' . $self->search_type . '_query';

         throw 'Unsupported search type [_1]', [$self->search_type]
            unless $self->can($method);

         return $self->$method($name, $value);
      };
   };

=item search_type

=cut

has 'search_type' => is => 'ro', isa => Str, default => 'string';

=back

=head1 Subroutines/Methods

=over 3

=item searchable( $table )

=cut

sub searchable {
   my ($self, $table) = @_;

   my $searchable = $self->_get_searchable or return FALSE;

   return is_coderef $searchable ? !!$searchable->($table) : TRUE;
}

# Private methods
sub _build_integer_query {
   my ($self, $name, $value) = @_;

   $value =~ s{ \D+ }{}gmx;

   return $name => { '=' => "${value}" || 0 };
}

sub _build_string_query {
   my ($self, $name, $value) = @_; return $name => { 'ilike' => "%${value}%" };
}

sub _build_tag_query {
   my ($self, $name, $value) = @_;

   return '-or' => [
      $name => { 'ilike' => "%|${value}|%"  },
      $name => { 'ilike' => "${value}|%" },
      $name => { 'ilike' => "%|${value}" },
      $name => { 'ilike' => "${value}" },
   ];
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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

Peter Flanigan, C<< <lazarus@roxsoft.co.uk> >>

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
