use t::boilerplate;

use HTTP::Request::Common;
use CatalystX::Test::MockContext;
use HTML::Entities qw( decode_entities );
use JSON::MaybeXS qw( decode_json );
use Test::More;

{  package Test::MockRs;

   use Moo;

   sub current_source_alias { 'me' }
   sub column_info { { data_type => 'TEXT' } }
   sub next {}
   sub pager {}
   sub result_source { shift }
   sub search { shift }
}

my $m       = mock_context('MyApp');
my $c       = $m->(GET '/?foo_download=csv');
my $options = { context => $c, resultset => Test::MockRs->new };
my $table   = $c->new_table('MyTable', $options);

ok $table, 'Creates table';

like $table->render, qr{ class="state-table" }mx, 'Default element class';

my ($data) = $table->render =~ m{ data-table-config="([^"]+)" }mx;
my $config = decode_json(decode_entities($data));

is $config->{properties}->{'data-url'},
   'http://localhost/?foo_download=csv&table_name=foo',
   'Data URL';

is $config->{properties}->{'no-data-message'}, 'No data to display',
   'No data message';

is $config->{roles}->{downloadable}->{filename}, 'foo', 'Download filename';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
