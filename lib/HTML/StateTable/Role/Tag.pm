package HTML::StateTable::Role::Tag;

use HTML::StateTable::Constants qw( FALSE TRUE );
use HTML::StateTable::Types     qw( Bool Int Str );
use Type::Utils                 qw( class_type );
use Moo::Role;

has 'tag_all' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::ResultSet'),
   default => sub {
      my $self   = shift;
      my $schema = $self->resultset->result_source->schema;

      return $schema->resultset($self->tag_rs_name)->search(
         { id => { -in => $self->tag_allowed_ids->as_query } },
         { order_by => { -asc => $self->tag_column_name }}
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

has 'tag_column_name' => is => 'ro', isa => Str, default => 'name';

has 'tag_control_location' => is => 'ro', isa => Str, default => 'TopLeft';

has 'tag_display_limit' => is => 'ro', isa => Int, default => 20;

has 'tag_enable' => is => 'rw', isa => Bool, lazy => TRUE, default => TRUE;

has 'tag_id_column_name' => is => 'ro', isa => Str, default => 'tag_id';

has 'tag_popular' =>
   is      => 'lazy',
   isa     => class_type('DBIx::Class::ResultSet'),
   default => sub {
      my $self   = shift;
      my $schema = $self->resultset->result_source->schema;
      my $column = $self->tag_result . $self->tag_popular_suffix;

      return $schema->resultset($self->tag_rs_name)->search(
         { id       => { -in   => $self->allowed_tag_ids->as_query },
           $column  => { '!='  => FALSE } },
         { order_by => { -desc => $column },
           rows     => $self->tag_display_limit }
      );
   };

has 'tag_popular_suffix' => is => 'ro', isa => Str, default => '_popularity';

has 'tag_result' =>
   is      => 'lazy',
   isa     => Str,
   default => sub {
      my $self = shift;

      return lc $self->resultset->result_source->source_name;
   };

has 'tag_result_suffix' => is => 'ro', isa => Str, default => '_tags';

has 'tag_rs_name' => is => 'ro', isa => Str, default => 'Tag';

has 'tag_search_column' => is => 'ro', isa => Str, default => 'tags';

after 'BUILD' => sub {
   my $self = shift;

   return unless $self->tag_enable && $self->tag_all->count > 0;

   $self->add_role('table_tags', __PACKAGE__);
   return;
};

sub serialise_table_tags {
   my $self     = shift;
   my $name     = $self->tag_column_name;
   my @all_tags = ();

   while (my $tag = $self->tag_all->next) { push @all_tags, $tag->$name }

   my @popular_tags = ();

   while (my $tag = $self->tag_popular->next) { push @popular_tags, $tag->$name}

   return {
      all_tags      => \@all_tags,
      location      => { control => $self->tag_control_location },
      popular_tags  => \@popular_tags,
      search_column => $self->tag_search_column,
   };
}

use namespace::autoclean;

1;
