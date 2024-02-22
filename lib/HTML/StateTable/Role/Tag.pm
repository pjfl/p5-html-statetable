package HTML::StateTable::Role::Tag;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool Int Str );
use HTML::StateTable::Util      qw( json_bool );
use Type::Utils                 qw( class_type );
use Moo::Role;

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

has 'tag_breadcrumbs' => is => 'ro', isa => Bool, default => FALSE;

has 'tag_column_name' => is => 'ro', isa => Str, default => 'name';

has 'tag_control_location' => is => 'ro', isa => Str, default => 'TopLeft';

has 'tag_direction' => is => 'ro', isa => Str, default => 'left';

has 'tag_display_limit' => is => 'ro', isa => Int, default => 20;

has 'tag_enable' => is => 'ro', isa => Bool, default => TRUE;

has 'tag_enable_popular' => is => 'ro', isa => Bool, default => FALSE;

has 'tag_id_column_name' => is => 'ro', isa => Str, default => 'tag_id';

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

has 'tag_popular_suffix' => is => 'ro', isa => Str, default => '_popularity';

has 'tag_result' =>
   is      => 'lazy',
   isa     => Str,
   default => sub { lc shift->resultset->result_source->source_name };

has 'tag_result_suffix' => is => 'ro', isa => Str, default => '_tags';

has 'tag_rs_name' => is => 'ro', isa => Str, default => 'Tag';

has 'tag_search_column' => is => 'ro', isa => Str, default => 'tags';

has 'tag_section' => is => 'ro', isa => Bool, default => FALSE;

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->tag_enable && 0 < @{$self->tag_names};

   $self->add_role('tagable', __PACKAGE__);
   return;
};

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
