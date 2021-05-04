package HTML::StateTable::Row;

use HTML::StateTable::Constants qw( TRUE );
use HTML::StateTable::Types     qw( ResultObject Table );
use Moo;

has 'result' => is => 'ro', isa => ResultObject, required => TRUE;

has 'table' => is => 'ro', isa => Table, required => TRUE, weak_ref => TRUE;

1;
