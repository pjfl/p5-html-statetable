package HTML::StateTable::Role::Searchable;

use HTML::StateTable::Constants qw( DOT EXCEPTION_CLASS FALSE TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool Column Str );
use Scalar::Util                qw( blessed );
use Unexpected::Functions       qw( throw );
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

has 'searchable_method' => is => 'ro', isa => Str;

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('searchable', __PACKAGE__);

   if (!$self->searchable_method && !$self->has_searchable_columns) {
      $self->searchable(0);
   }

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
      my @search_spec;
      my $search_column = $self->param_value('search_column');

      for my $column (@{$self->searchable_columns}) {
         my $name = $column->value;

         next if $search_column && $search_column ne $column->name;

         my @name_parts = split m{ \. }mx, $name;

         unshift @name_parts, $rs->current_source_alias()
            if scalar @name_parts == 1;

         $name = join DOT, @name_parts[-2,-1];
         push @search_spec, $column->search_query_builder->(
            $column, $name, $search
         );
      }

      return $rs unless scalar @search_spec;

      $rs = $rs->search(\@search_spec);
   }

   return $rs;
};

sub serialise_searchable {
   my $self = shift;

   return $self->has_searchable_columns ? {
      location           => { control => 'TopLeft', messages => 'Title' },
      searchable_columns => [ map { $_->name } @{$self->searchable_columns} ],
      role_name          => 'Searchable',
   } : undef;
}

use namespace::autoclean;

1;
