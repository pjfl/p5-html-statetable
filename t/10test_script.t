use t::boilerplate;

use HTTP::Request::Common;
use CatalystX::Test::MockContext;
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

my $m = mock_context('MyApp');
my $c = $m->(GET '/?foo_download=csv');

my $table = $c->table('MyTable', Test::MockRs->new);

ok $table, 'Creates table';

like $table->render, qr{ class="state-table" }mx, 'Default output';

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
