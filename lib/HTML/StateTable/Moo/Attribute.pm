package HTML::StateTable::Moo::Attribute;

use namespace::autoclean;

use HTML::StateTable::Types qw( Object );
use Moo;

has 'isa' => is => 'ro', isa => Object;

1;
