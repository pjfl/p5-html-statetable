package MyApp::Table::MyTable;

use HTML::StateTable::Constants qw( TABLE_META );
use Moo;
use HTML::StateTable::Moo;

extends qw( HTML::StateTable );
with    qw( HTML::StateTable::Role::Downloadable );

set_table_name 'foo';

set_defaults {
   page_size => 50,
};

has_column 'bar', sortable => 1;

has_column 'baz', displayed => 0, options => { check_all => 1 };

use namespace::autoclean -except => TABLE_META;

1;
