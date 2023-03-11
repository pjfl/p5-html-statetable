package HTML::StateTable::Exception;

use Unexpected::Functions qw( has_exception );
use Moo;

extends q(Unexpected);
with    q(Unexpected::TraitFor::ErrorLeader);
with    q(Unexpected::TraitFor::ExceptionClasses);

my $class = __PACKAGE__;

has '+class' => default => $class;

has_exception $class;

use namespace::autoclean;

1;
