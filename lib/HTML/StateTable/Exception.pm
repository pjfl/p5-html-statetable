package HTML::StateTable::Exception;

use Unexpected::Functions qw( has_exception );
use Moo;

extends q(Unexpected);
with    q(Unexpected::TraitFor::ErrorLeader);
with    q(Unexpected::TraitFor::ExceptionClasses);

my $class = __PACKAGE__;

has '+class' => default => $class;

has_exception $class;

has_exception 'UnknownView' => parents => [ $class ],
   error => 'View [_1] unknown';

use namespace::autoclean;

1;
