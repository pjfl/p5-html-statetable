package HTML::StateTable::Role::Tag;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool Int Str );
use HTML::StateTable::Util      qw( json_bool );
use Type::Utils                 qw( class_type );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Tag - Uses column data as tags on another column

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Tag';

=head1 Description

Uses column data as tags on another column. Tags can be displayed inline, as a
list, or as section headings.

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item tag_all

A lazy L<DBIx::Class> resultset. Will return all of the allowed tag results

=cut

has 'tag_all' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::ResultSet'),
   default => sub {
      my $self   = shift;
      my $schema = $self->resultset->result_source->schema;

      return $schema->resultset($self->tag_rs_name)->search(
         { id       => { -in  => $self->tag_allowed_ids->as_query } },
         { order_by => { -asc => $self->tag_column_name },
           rows     => $self->tag_display_limit }
      );
   };

=item tag_allowed_ids

A lazy L<DBIx::Class> resultset column

=cut

has 'tag_allowed_ids' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::ResultSetColumn'),
   default => sub {
      my $self = shift;
      my $rs   = $self->resultset;

      $rs = $rs->active
         if !$self->param_value('show_inactive') && $rs->can('active');

      $rs = $rs->search_related($self->tag_result . $self->tag_result_suffix);

      return $rs->get_column($self->tag_id_column_name);
   };

=item tag_breadcrumbs

A boolean which defaults false. By default tags render as text but if set to
true tags will render as links

=cut

has 'tag_breadcrumbs' => is => 'ro', isa => Bool, default => FALSE;

=item tag_column_name

An immutable string which defaults to C<name>. The tag attribute name containing
the tags display value

=cut

has 'tag_column_name' => is => 'ro', isa => Str, default => 'name';

=item tag_control_location

An immutable string which defaults to C<TopLeft>. The location of the list of
tags (if displayed as such)

=cut

has 'tag_control_location' => is => 'ro', isa => Str, default => 'TopLeft';

=item tag_direction

An immutable string which defaults to C<left>. Determines the direction of
the pointer indicator on the tag list display

=cut

has 'tag_direction' => is => 'ro', isa => Str, default => 'left';

=item tag_display_limit

An immutable integer which defaults to 20. The maximum number of tags to display
in a list

=cut

has 'tag_display_limit' => is => 'ro', isa => Int, default => 20;

=item tag_enable

Immutable boolean which defaults true. If false tags will not be displayed

=cut

has 'tag_enable' => is => 'ro', isa => Bool, default => TRUE;

=item tag_enable_popular

Boolean which defaults false. By default all tags are displayed, if true this
causes only "popular" tags to be displayed

=cut

has 'tag_enable_popular' => is => 'ro', isa => Bool, default => FALSE;

=item tag_id_column_name

String defaults to C<tag_id>

=cut

has 'tag_id_column_name' => is => 'ro', isa => Str, default => 'tag_id';

=item tag_names

A lazy array reference of selected tag names

=cut

has 'tag_names' =>
   is      => 'lazy',
   isa     => ArrayRef,
   default => sub {
      my $self = shift;
      my $name = $self->tag_column_name;
      my @tags = ();

      if ($self->tag_enable_popular) {
         while (my $tag = $self->tag_popular->next) { push @tags, $tag->$name }
      }
      else {
         while (my $tag = $self->tag_all->next) { push @tags, $tag->$name }
      }

      return \@tags;
   };

=item tag_popular

A lazy L<DBIx::Class> resultset which will return the "popular" tags

=cut

has 'tag_popular' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::ResultSet'),
   default => sub {
      my $self   = shift;
      my $schema = $self->resultset->result_source->schema;
      my $column = $self->tag_result . $self->tag_popular_suffix;

      return $schema->resultset($self->tag_rs_name)->search(
         { id       => { -in   => $self->tag_allowed_ids->as_query },
           $column  => { '!='  => 0 } },
         { order_by => { -desc => $column },
           rows     => $self->tag_display_limit }
      );
   };

=item tag_popular_suffix

Immutable string which defaults to C<_popularity>. It is appended to
C<tag_result> and used as the column name to order the C<tag_popular> resultset

=cut

has 'tag_popular_suffix' => is => 'ro', isa => Str, default => '_popularity';

=item tag_result

A lazy string. The result source source name

=cut

has 'tag_result' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { lc shift->resultset->result_source->source_name };

=item tag_result_suffix

String which defaults to C<_tags>

=cut

has 'tag_result_suffix' => is => 'ro', isa => Str, default => '_tags';

=item tag_rs_name

String which defaults to C<Tag>. The name of the tag resultset

=cut

has 'tag_rs_name' => is => 'ro', isa => Str, default => 'Tag';

=item tag_search_column

A string which defaults to C<tags>. The name of the column containing the tags

=cut

has 'tag_search_column' => is => 'ro', isa => Str, default => 'tags';

=item tag_section

Boolean defaults false. If C<tag_search_column> does not exist or does not set
the C<append_to> attribute and this is true then displays tags as section
headings, otherwise display tags in a list

=cut

has 'tag_section' => is => 'ro', isa => Bool, default => FALSE;

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. If C<tag_enabled> and we have some
C<tag_names> add C<tagable> to the list of serialisable table roles

=cut

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->tag_enable && 0 < @{$self->tag_names};

   $self->add_role('tagable', __PACKAGE__);
   return;
};

=item serialise_tagable

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_tagable {
   my $self = shift;

   my $data = {
      'breadcrumbs'    => json_bool $self->tag_breadcrumbs,
      'direction'      => $self->tag_direction,
      'enable-popular' => json_bool $self->tag_enable_popular,
      'location'       => { control => $self->tag_control_location },
      'search-column'  => $self->tag_search_column,
      'section'        => json_bool $self->tag_section,
      'tags'           => $self->tag_names,
   };

   if (my $append_col = $self->get_column($self->tag_search_column)) {
      $data->{'append-to'} = $append_col->append_to;
   }

   return $data;
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
