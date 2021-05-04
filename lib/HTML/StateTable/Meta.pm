package HTML::StateTable::Meta;

use mro;
use namespace::autoclean;

use HTML::StateTable::Types qw( ArrayRef CodeRef Column HashRef
                                NonEmptySimpleStr );
use Moo;
use MooX::HandlesVia;

has 'columns' =>
   is            => 'rw',
   isa           => ArrayRef[Column],
   default       => sub { [] },
   handles_via   => 'Array',
   handles       => {
      add_column    => 'push',
      all_columns   => 'elements',
      clear_columns => 'clear',
      grep_column   => 'grep',
      has_column    => 'count',
   };

has 'default_options' => is => 'rwp', isa => HashRef, default => sub { {} };

has 'filters' =>
   is          => 'rw',
   isa         => HashRef,
   handles_via => 'Hash',
   handles     => { add_filter => 'set' },
   default     => sub { {} };

has 'resultset_callback' =>
   is        => 'rwp',
   isa       => CodeRef,
   predicate => 'has_resultset_callback';

has 'table_name' => is => 'rwp', isa => NonEmptySimpleStr;

1;
