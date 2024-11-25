package HTML::StateTable::Role::Searchable;

use HTML::StateTable::Constants qw( DOT FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool Column Str );
use HTML::StateTable::Util      qw( throw );
use Scalar::Util                qw( blessed );
use Moo::Role;
use MooX::HandlesVia;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Searchable - Searches rows for matching column values

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Searchable';

=head1 Description

Searches rows for matching column values

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item searchable

Mutable boolean which defaults true. If set to false searching is disabled

=cut

has 'searchable' => is => 'rw', isa => Bool, default => TRUE;

=item searchable_columns

A lazy array reference of column objects. Contains on searchable columns

=cut

has 'searchable_columns' =>
   is          => 'lazy',
   isa         => ArrayRef[Column],
   handles_via => 'Array',
   handles     => { has_searchable_columns => 'count' },
   default     => sub {
      my $self    = shift;
      my $trait   = 'HTML::StateTable::Column::Trait::Searchable';
      my @columns = grep {
         $_->does($trait) && !$_->hidden($self) && $_->searchable($self)
      } @{$self->columns};

      for my $column (@columns) {
         throw 'Table [_1] column [_2]: Cannot search - value not a field name',
            [blessed $self, $column->name] if ref $column->value;
      }

      return \@columns;
   };

=item searchable_control_location

A string which defaults to C<TopLeft>. The location of the search input field

=cut

has 'searchable_control_location' => is => 'ro', isa => Str,
   default => 'TopLeft';

=item searchable_method

Immutable string with no default. The name of a method to call on the
resultset. Passed the C<search> parameter when called

=cut

has 'searchable_method' => is => 'ro', isa => Str;

=item searchable_message_all

Immutable string which defaults to "All Columns". Used in search messages

=cut

has 'searchable_message_all' => is => 'ro', isa => Str,
   default => 'All Columns';

=item searchable_message_label

Immutable string which defaults to C<Searching for>. Used in search messages

=cut

has 'searchable_message_label' => is => 'ro', isa => Str,
   default => 'Searching for';

=item searchable_message_location

Immutable string which defaults to C<Title>. The location for search related
messages

=cut

has 'searchable_message_location' => is => 'ro', isa => Str,
   default => 'Title';

=item searchable_placeholder

Immutable string which defaults to "Search table...". Placeholder text for the
search input field

=cut

has 'searchable_placeholder' => is => 'ro', isa => Str,
   default => 'Search table...';

=item searchable_remove_label

Immutable string which defaults to "Show all". The text to display so as to
cancel the search

=cut

has 'searchable_remove_label' => is => 'ro', isa => Str,
   default => 'Show all';

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. If C<searchable> is true and we have either a
C<searchable_method> or C<has_searchable_columns> add to the list of
serialisable table roles

=cut

after 'BUILD' => sub {
   my $self = shift;

   if (!$self->searchable_method && !$self->has_searchable_columns) {
      $self->searchable(FALSE);
   }

   $self->add_role('searchable', __PACKAGE__) if $self->searchable;

   return;
};

=item build_prepared_resultset

Executes around the method in the consuming class. Applies the search query
parameters to the resultset

=cut

around 'build_prepared_resultset' => sub {
   my ($orig, $self) = @_;

   my $rs     = $orig->($self);
   my $search = $self->param_value('search');

   return $rs unless $search;

   $self->is_filtered(TRUE);

   if (my $method = $self->searchable_method) {
      throw 'Cannot have searchable columns and method'
         if $self->has_searchable_columns;
      $rs = $rs->$method($search);
   }
   else {
      my @search_params;
      my $search_column = $self->param_value('search_column');

      for my $column (@{$self->searchable_columns}) {
         my $name = $column->value;

         next if $search_column && $search_column ne $column->name;

         my @name_parts = split m{ \. }mx, $name;

         unshift @name_parts, $rs->current_source_alias()
            if scalar @name_parts == 1;

         $name = join DOT, @name_parts[-2, -1];
         push @search_params, $column->search_query->($column, $name, $search);
      }

      $rs = $rs->search(\@search_params) if scalar @search_params;
   }

   return $rs;
};

=item serialise_searchable

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_searchable {
   my $self = shift;

   return unless $self->has_searchable_columns;

   return {
      'location' => {
         control  => $self->searchable_control_location,
         messages => $self->searchable_message_location,
      },
      'message-all'   => $self->searchable_message_all,
      'message-label' => $self->searchable_message_label,
      'placeholder'   => $self->searchable_placeholder,
      'remove-label'  => $self->searchable_remove_label,
      'searchable-columns' => [ map { $_->name } @{$self->searchable_columns} ],
   };
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
