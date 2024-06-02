package HTML::StateTable::Role::Searchable;

use HTML::StateTable::Constants qw( DOT FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool Column Str );
use HTML::StateTable::Util      qw( throw );
use Scalar::Util                qw( blessed );
use Moo::Role;
use MooX::HandlesVia;

has 'searchable' => is => 'rw', isa => Bool, default => TRUE;

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

has 'searchable_control_location' => is => 'ro', isa => Str,
   default => 'TopLeft';

has 'searchable_method' => is => 'ro', isa => Str;

has 'searchable_message_all' => is => 'ro', isa => Str,
   default => 'All Columns';

has 'searchable_message_label' => is => 'ro', isa => Str,
   default => 'Searching for';

has 'searchable_message_location' => is => 'ro', isa => Str,
   default => 'Title';

has 'searchable_placeholder' => is => 'ro', isa => Str,
   default => 'Search table...';

has 'searchable_remove_label' => is => 'ro', isa => Str,
   default => 'Show all';

after 'BUILD' => sub {
   my $self = shift;

   if (!$self->searchable_method && !$self->has_searchable_columns) {
      $self->searchable(FALSE);
   }

   $self->add_role('searchable', __PACKAGE__) if $self->searchable;

   return;
};

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
