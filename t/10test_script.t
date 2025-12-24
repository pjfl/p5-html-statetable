use t::boilerplate;

use English        qw( -no_match_vars );
use HTML::Entities qw( decode_entities );
use JSON::MaybeXS  qw( decode_json );
use HTTP::Request::Common;
use Plack::Test;
use Test::More;

if ($ENV{TEST_MEMORY}) {
   eval "use Test::Memory::Cycle";

   plan skip_all => 'Test::Memory::Cycle required but not installed'
      if $EVAL_ERROR;
}

{  package Test::Result;

   use Moo;

   has 'bar' => is => 'ro';
   has 'baz' => is => 'ro';
}

{  package Test::Pager;

   use Moo;

   has 'total_entries' => is => 'ro';
}

my $max_rows = 3;
my $count = 0;

{  package Test::MockRs;

   use Moo;

   sub current_source_alias { 'me' }
   sub column_info {
      return { bar => { data_type => 'TEXT' }, baz => { data_type => 'TEXT' } };
   }
   sub next {
      return unless $count++ < $max_rows;
      return Test::Result->new({ bar => "bar${count}", baz => "baz${count}" });
   }
   sub pager { Test::Pager->new({ total_entries => $max_rows }) }
   sub reset { $count = 0 }
   sub result_source { shift }
   sub search { shift }
}

my $output = '';

{  package Test::TypeWriter;

   use Moo;

   sub close {}
   sub write { my $self = shift; $output .= $_[0] }
}

use HTML::StateTable::Util qw( ensure_class_loaded );

sub mock_context {
  my ($class, $response_cb) = @_;

  ensure_class_loaded 'Catalyst::Middleware::Stash';
  ensure_class_loaded $class;
  $response_cb //= sub { };

  return sub {
    my $req = shift;
    my $c;
    my $app = sub {
        my $env = shift;
        $c = $class->prepare( env => $env, response_cb => $response_cb );
        return [ 200, [ 'Content-type' => 'text/plain' ], ['Created mock OK'] ];
    };

    $app = Catalyst::Middleware::Stash->wrap($app);
    test_psgi app => $app, client => sub { shift->($req) };

    return $c;
  };
}

my $factory = mock_context('MyApp', sub { Test::TypeWriter->new });
my $req     = GET '/?foo_download=csv';
my $context = $factory->($req);
my $options = { context => $context, resultset => Test::MockRs->new };
my $table   = $context->new_table('MyTable', $options);

ok $table, 'Creates table';

like $table->render, qr{ class="state-table" }mx, 'Default element class';

my ($json) = $table->render =~ m{ data-table-config="([^"]+)" }mx;
my $data   = decode_json(decode_entities($json));

is $data->{columns}->[0]->{name}, 'bar', 'First column name';

is $data->{columns}->[1]->{name}, 'baz', 'Second column name';

is $data->{name}, 'foo', 'Table name';

is $data->{properties}->{'data-url'},
   'http://localhost/?foo_download=csv&table_name=foo',
   'Data URL';

is $data->{properties}->{'max-page-size'}, 100, 'Page size';

is $data->{properties}->{'no-data-message'}, 'No data to display',
   'No data message';

is $data->{properties}->{'page-size'}, 20, 'Page size';

is $data->{roles}->{downloadable}->{location}->{control}, 'BottomRight',
   'Default downloadable location';

is $data->{roles}->{downloadable}->{method}, 'csv',
   'Default downloadable method';

is $data->{roles}->{pageable}->{location}->{control}, 'BottomLeft',
   'Default pageable location';

is $data->{roles}->{pagesize}->{location}->{control}, 'BottomRight',
   'Default pagesize location';

$req = GET '/?table_name=foo';
$req->headers->header('X-Requested-With', 'XMLHttpRequest');
$context = $factory->($req);
$options = { context => $context, resultset => Test::MockRs->new };
$table   = $context->new_table('MyTable', $options);

ok $table, 'Creates table for row data';

is $context->stash->{_serialise_table}->{format}, 'json',
   'Serialise data format';

is $context->stash->{view}, 'SerialiseTable', 'Serialise table view';

ensure_class_loaded 'MyApp::View::SerialiseTable';

my $serialiser = MyApp::View::SerialiseTable->new;

$serialiser->process($context);

$data = decode_json($output);

is $data->{'row-count'}, $max_rows, 'Data row count';

is $data->{'records'}->[0]->{bar}, 'bar1', 'First row first column';

is $data->{'records'}->[2]->{baz}, 'baz3', 'Last row last column';

if ($ENV{TEST_MEMORY}) {
   memory_cycle_ok( $req, 'Request has no memory cycles' );

   memory_cycle_ok( $context, 'Context has no memory cycles' );

   memory_cycle_ok( $table, 'Table has no memory cycles' );

   memory_cycle_ok( $serialiser, 'Serialiser has no memory cycles' );
}

done_testing;

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:use strict;
