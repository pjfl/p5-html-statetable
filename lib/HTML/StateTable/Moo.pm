package HTML::StateTable::Moo;

use mro;
use strictures;

use HTML::StateTable::Constants qw( COLUMN_TRAIT_PREFIX FALSE TABLE_META TRUE );
use HTML::StateTable::Util      qw( throw );
use Ref::Util                   qw( is_arrayref );
use Sub::Install                qw( install_sub );
use HTML::StateTable::Column;
use HTML::StateTable::Meta;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Moo - Table meta class installer

=head1 Synopsis

   use HTML::StateTable::Moo;

=head1 Description

Table meta class installer

=head1 Configuration and Environment

Defines no attributes

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=cut

my $auto_column_traits = {
   filterable => 'Filterable',
   searchable => 'Searchable',
   title      => 'Title',
};
my @banished_keywords  = ( TABLE_META );
my $column_class       = 'HTML::StateTable::Column';

=item import

A custom importer which will install an instance of L<HTML::StateTable::Meta>
into the consuming class. It also installs the subroutines;

=over 3

=item C<has_column>

When called creates a new instance of L<HTML::StateTable::Column> to which it
automatically applies these column traits; C<Filterable>, C<Searchable>, and
C<Title>. Calls C<add_column> on the meta class object

=item C<has_filter>

Calls C<add_filter> on the meta class object

=item C<set_defaults>

Calls the private setter for C<default_options> on the meta class object

=item C<set_table_name>

Calls the private setter for C<table_name> on the meta class object

=item C<setup_resultset>

Calls the private setter for C<resultset_callback> on the meta class object

=back

=cut

sub import {
   my ($class, @args) = @_;

   my $target = caller;
   my @target_isa  = @{ mro::get_linear_isa($target) };
   my $method   = TABLE_META;
   my $meta;

   if (@target_isa) {
      # Don't add this to a role. The ISA of a role is always empty!
      if ($target->can($method)) { $meta = $target->$method }
      else {
         my $attr = { target => $target, @args };

         $meta = HTML::StateTable::Meta->new($attr);
         install_sub { as => $method, into => $target, code => sub {
            return $meta;
         }};
      }
   }
   else {
      throw 'No meta object' unless $target->can($method);

      $meta = $target->$method;
   }

   my $rt_info_key = 'non_methods';
   my $info = $Role::Tiny::INFO{$target};
   my $has_column = sub ($;%) {
      my ($name, %attributes) = @_;

      my $names  = is_arrayref $name ? $name : [$name];
      my $traits = delete $attributes{traits} // [];

      for my $key (keys %{$auto_column_traits}) {
         push @{$traits}, COLUMN_TRAIT_PREFIX.'::'.$auto_column_traits->{$key}
            if exists $attributes{$key};
      }

      if (exists $attributes{cell_traits}) {
         $attributes{serialised} //= FALSE
            if grep { $_ eq 'Checkbox' } @{$attributes{cell_traits}};
      }

      for my $name (@{$names}) {
         _assert_no_banished_keywords($target, $name);

         my $column = $column_class->new_with_traits(
            name   => $name,
            traits => $traits,
            %attributes
         );

         $meta->add_column($column);
      }

      return;
   };

   $info->{$rt_info_key}{$has_column} = $has_column if $info;

   install_sub { as => 'has_column', into => $target, code => $has_column };

   my $has_filter = sub ($) { $meta->add_filter(@_) };

   $info->{$rt_info_key}{$has_filter} = $has_filter if $info;

   install_sub { as => 'has_filter', into => $target, code => $has_filter };

   my $defaults = sub ($) { $meta->_set_default_options(shift) };

   $info->{$rt_info_key}{$defaults} = $defaults if $info;

   install_sub { as => 'set_defaults', into => $target, code => $defaults };

   my $table_name = sub ($) { $meta->_set_table_name(shift) };

   $info->{$rt_info_key}{$table_name} = $table_name if $info;

   install_sub { as => 'set_table_name', into => $target, code => $table_name };

   my $resultset = sub ($) { $meta->_set_resultset_callback(shift) };

   $info->{$rt_info_key}{$resultset} = $resultset if $info;

   install_sub { as => 'setup_resultset', into => $target, code => $resultset };

   return;
}

sub _assert_no_banished_keywords {
   my ($target, $name) = @_;

   for my $ban (grep { $_ eq $name } @banished_keywords) {
      throw 'Method [_1] used by class [_2] as an attribute', [$ban, $target];
   }

   return;
}

1;

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Sub::Install>

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
