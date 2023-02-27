package HTML::StateTable::Moo::Attribute;

use HTML::StateTable::Types qw( Object );
use Moo;

has 'isa' => is => 'ro', isa => Object;

use namespace::autoclean;

1;
