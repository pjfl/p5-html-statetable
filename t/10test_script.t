use t::boilerplate;

use HTTP::Request::Common;
use CatalystX::Test::MockContext;
use Test::More;

my $m = mock_context('MyApp');
my $c = $m->(GET '/?foo_download=csv');

my $table = $c->table('MyTable');

ok $table, 'Creates table';

warn $table->render;
warn $table->next_result;
done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
