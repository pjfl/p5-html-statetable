package HTML::StateTable::Column::Trait::Searchable;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS FALSE TRUE );
use HTML::StateTable::Types     qw( Bool CodeRef Str );
use Ref::Util                   qw( is_coderef );
use Unexpected::Functions       qw( throw );
use Moo::Role;

has 'searchable' => is => 'ro', isa => Bool|CodeRef,
   reader => '_get_searchable';

has 'search_query' =>
   is      => 'lazy',
   isa     => CodeRef,
   default => sub {
      return sub {
         my ($self, $name, $value) = @_;

         my $method = '_build_' . $self->search_type . '_query';

         if ($self->can($method)) { $self->$method($name, $value) }
         else { throw 'Unsupported search type [_1]', [$self->search_type] }
      };
   };

has 'search_type' => is => 'ro', isa => Str, default => 'string';

sub searchable {
   my ($self,$table) = @_;

   my $searchable = $self->_get_searchable or return FALSE;

   return is_coderef $searchable ? !!$searchable->($table) : TRUE;
}

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
