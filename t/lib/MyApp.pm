package MyApp;

use HTML::StateTable::Manager;
use Scalar::Util qw( blessed );
use Moo;

BEGIN { extends 'Catalyst' }

__PACKAGE__->setup();

{
	my $table_manager = HTML::StateTable::Manager->new(
		namespace => 'MyApp::Table',
	);

	sub table {
		my ($c, $table_name, $options) = @_;

		$options //= {};
		$options = { resultset => $options } if blessed $options;
		$options->{context} = $c;

		return $table_manager->table($table_name, $options);
	}
}

1;
