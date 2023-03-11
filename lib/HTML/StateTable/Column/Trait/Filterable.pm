package HTML::StateTable::Column::Trait::Filterable;

use HTML::StateTable::Constants qw( DOT FALSE TRUE );
use HTML::StateTable::Types     qw( Bool CodeRef HashRef Str );
use HTML::StateTable::Util      qw( throw );
use Ref::Util                   qw( is_coderef is_scalarref );
use Moo::Role;

has 'filter_column' => is => 'rwp', isa => Str,
   predicate => 'has_filter_column';

has 'filter_relation' => is => 'rwp', isa => Str,
   predicate => 'has_filter_relation';

has 'filter_use_pkey' => is => 'ro', isa => Bool, default => TRUE;

has 'filter_value_map' => is => 'ro', isa => CodeRef|HashRef,
   predicate => 'has_filter_value_map';

has 'filterable' => is => 'ro', isa => Bool, default => FALSE;

before 'BUILD' => sub {
   my $self = shift;

   return if $self->has_filter_relation || $self->has_filter_column;

   throw 'Column [_1] not a plain scalar value', [$self->name]
      if is_coderef $self->value or is_scalarref $self->value;

   if ($self->value =~ m{ \. }mx) {
      my ($column, @relations) = split m{ \. }mx, $self->value;

      $self->_set_filter_column($column);
      $self->_set_filter_relation(join DOT, @relations);
   }
   else { $self->_set_filter_column($self->value) }

   return;
};

use namespace::autoclean;

1;

__END__

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Column::Trait::Filterable - One-line description of the modules purpose

=head1 Synopsis

   use HTML::StateTable::Column::Trait::Filterable;
   # Brief but working code examples

=head1 Description

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=back

=head1 Subroutines/Methods

=head1 Diagnostics

=head1 Dependencies

=over 3

=item L<Class::Usul>

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
