package HTML::StateTable::Moo;

use mro;
use strictures;

use HTML::StateTable::Constants qw( FALSE TABLE_META_ATTR
                                    TABLE_META_CONFIG TRUE );
use HTML::StateTable::Column;
use HTML::StateTable::Meta;
use HTML::StateTable::Util      qw( throw );
use Ref::Util                   qw( is_arrayref );
use Sub::Install                qw( install_sub );

my @banished_keywords = qw( TABLE_META_ATTR has_column table_name );
my $column_class      = 'HTML::StateTable::Column';
my @required_symbols  = qw( has );

sub import {
   my ($class, @args) = @_;

   my $target = caller;

   for my $want (grep { not $target->can($_) } @required_symbols) {
      throw 'Symbol [_1] not found in class [_2]', [$want, $target];
   }

   my @target_isa  = @{ mro::get_linear_isa($target) };
   my $meta_config = { TABLE_META_CONFIG, target => $target, @args };
   my $meta_attr   = TABLE_META_ATTR;
   my $meta;

   if (@target_isa) {
      # Don't add this to a role. The ISA of a role is always empty!
      if ($target->can($meta_attr)) { $meta = $target->$meta_attr }
      else {
         $meta = HTML::StateTable::Meta->new($meta_config);
         install_sub { as => $meta_attr, into => $target, code => sub {$meta} };
      }
   }
   else {
      $target->can($meta_attr) or throw 'No meta object';
      $meta = $target->$meta_attr;
   }

   my $has  = $target->can('has');
   my $info = $Role::Tiny::INFO{$target};

   my $has_column = sub ($;%) {
      my ($name, %attributes) = @_;
      my $names = is_arrayref $name ? $name : [$name];

      for my $name (@{$names}) {
         _assert_no_banished_keywords($target, $name);

         my $column_attr = [ $column_class->_get_meta->get_all_attributes ];

         $has->($name => _filter_out_column_attr($column_attr, %attributes));

         my $column = $column_class->new({
            name => $name,
            _validate_and_filter_column_attr($column_attr, %attributes)
         });

         $meta->add_column($column);
      }

      return;
   };

   $info->{not_methods}{$has_column} = $has_column if $info;

   install_sub { as => 'has_column', into => $target, code => $has_column };

   my $has_filter = sub ($) { $meta->add_filter(@_) };

   $info->{not_methods}{$has_filter} = $has_filter if $info;

   install_sub { as => 'has_filter', into => $target, code => $has_filter };

   my $defaults = sub ($) { $meta->_set_default_options(shift) };

   $info->{not_methods}{$defaults} = $defaults if $info;

   install_sub { as => 'set_defaults', into => $target, code => $defaults };

   my $table_name = sub ($) { $meta->_set_table_name(shift) };

   $info->{not_methods}{$table_name} = $table_name if $info;

   install_sub { as => 'set_table_name', into => $target, code => $table_name };

   my $resultset = sub ($) { $meta->_set_resultset_callback(shift) };

   $info->{not_methods}{$resultset} = $resultset if $info;

   install_sub { as => 'setup_resultset', into => $target, code => $resultset };

   return;
}

sub _assert_no_banished_keywords {
   my ($target, $name) = @_;

   for my $ban (grep { $_ eq $name } @banished_keywords) {
      throw 'Method [_1] used by class [_2] as an attribute', [$ban, $target];
   }

   return;
}

sub _filter_out_column_attr {
   my ($column_attr, %attributes) = @_;

   my %filter_key = map { $_ => 1 } @{$column_attr};

   $attributes{is} //= 'ro';

   return map { ( $_ => $attributes{$_} ) }
         grep { not exists $filter_key{$_} } keys %attributes;
}

sub _validate_and_filter_column_attr {
   my ($column_attr, %attributes) = @_;

   my %filtered = map { ($_ => $attributes{$_}) }
                 grep { exists $attributes{$_} } @{$column_attr};

   return %filtered;
}

1;
