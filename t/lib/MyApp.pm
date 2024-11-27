package MyApp;

use HTML::StateTable::Manager;
use Scalar::Util qw( blessed );
use Moo;

BEGIN { extends 'Catalyst' }

__PACKAGE__->setup();

{
   my $table_manager = HTML::StateTable::Manager->new(
      namespace => 'MyApp::Table', view_name => 'SerialiseTable'
   );

   sub new_table {
      my ($self, $table_name, $options) = @_;

      return $table_manager->new_with_context($table_name, $options);
   }

   sub verification_token {
      return 'Love';
   }
}

1;
