package MyApp::Table::MyTable;

use namespace::autoclean;

use Moo;
use HTML::StateTable::Moo;

extends qw( HTML::StateTable );
with    qw( HTML::StateTable::Role::Downloadable );

set_table_name 'foo';

set_defaults {
   page_size => 50,
};

setup_resultset sub {
   my $self = shift;

   return;
};

has_column 'bar', sortable => 1;

has_column 'baz', displayed => 0, options => { check_all => 1 };

1;
