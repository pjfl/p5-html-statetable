package HTML::StateTable::Cell;

use namespace::autoclean;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( Column Row );
use Moo;

has 'column' => is => 'ro', isa => Column, required => TRUE;

has 'row' => is => 'ro', isa => Row, required => TRUE;

1;
