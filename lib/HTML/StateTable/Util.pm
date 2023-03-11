package HTML::StateTable::Util;

use strictures;

use HTML::Entities              qw( encode_entities );
use HTML::StateTable::Constants qw( COL_INFO_TYPE_ATTR EXCEPTION_CLASS );
use Module::Runtime             qw( require_module );
use Unexpected::Functions       qw( is_class_loaded );
use Try::Tiny;

use Sub::Exporter -setup => { exports => [
   qw( dquote encode_only_entities ensure_class_loaded escape_formula
       foreign_sort json_bool quote_column_name quote_string squote throw
       trim unquote_string )
]};

sub dquote ($) {
   my $string = shift;

   return quote_string('"', $string);
}

sub encode_only_entities {
   my $html = shift;

   # Encode control chars and high bit chars, but leave '<', '&', '>', ''' and
   # '"'. Encode as decimal rather than hex, to keep Lotus Notes happy.
   $html =~ s{([^<>&"'\n\r\t !\#\$%\(-;=?-~])}{ #"emacs
      $HTML::Entities::char2entity{$1} || '&#' . ord($1) . ';'
   }ge;

   return $html;
}

sub ensure_class_loaded ($;$) {
   my ($class, $opts) = @_;

   $opts //= {};

   return 1 if !$opts->{ignore_loaded} && is_class_loaded $class;

   try { require_module($class) } catch { throw($_) };

   throw( 'Class [_1] loaded but package undefined', [$class] )
      unless is_class_loaded $class;

   return 1;
}

sub escape_formula (@) {
   my @args = @_;

   return
      map { my $s = $_; $s =~ s{ \A ( [+\-=\@] ) }{\t$1}mx if defined $s; $s }
      @args;
}

sub foreign_sort ($$$) {
   my ($resultset, $sorting, $reverse) = @_;

   my ($join, @order);

   for my $sort (@{$sorting}) {
      my $column = $sort->{column} || $sorting;

      return $resultset unless $column;

      my @relations     = split m{ \. }mx, $column;
      my $order_column  = pop @relations;
      my $join_relation = $relations[-1];
      my $source        = $resultset->result_source;

      for my $relation_name (@relations) {
         my $relation_info  = $source->relationship_info($relation_name);
         my $relation_class = $relation_info->{class};
         my $accessor       = $relation_info->{attrs}{accessor};

         throw('Relationship [_1] -> [_2] must be single, not [_3]',
            (ref($source) || $source), $relation_class, $accessor
         ) unless $accessor eq 'single' or $accessor eq 'filter';

         $source = $relation_class;
      }

      my $column_info = _get_column_info($source, $order_column);
      my $join_column = $join_relation || $resultset->current_source_alias;
      my $order_by    = _get_order($column_info, $join_column, $order_column);
      my $order_desc  = $reverse ? !$sort->{desc} : !!$sort->{desc};
      my $direction   = $order_desc ? '-desc' : '-asc';

      push @order, { $direction => $order_by };

      for my $relation (reverse @relations) {
         $join = defined $join ? { $relation => $join } : $relation;
      }
   }

   return $resultset->search(undef, { join => $join, order_by => \@order });
}

sub _get_column_info {
   my ($source, $order_column) = @_;

   my $info = eval { $source->column_info($order_column) };
   my $attr = COL_INFO_TYPE_ATTR;

   return { $attr => 'INTEGER' } unless $info;

   return $info;
}

sub _get_order {
   my ($column_info, $join_column, $order_column) = @_;

   my $attr = COL_INFO_TYPE_ATTR;
   my $type = $column_info->{$attr} // q();

   $order_column = quote_column_name($join_column, $order_column);

   return \$order_column unless $type =~ m{ \A text \z }imx;

   return \"LOWER($order_column)"; #"
}

sub json_bool ($) {
   return (shift) ? \1 : \0;
}

sub quote_column_name (;@) {
   my @parts = @_;

   for my $part (@parts) {
      throw('Column must not be empty') unless $part;
      throw('Column name contains invalid double quote') if $part =~ m{ \" }mx;
      $part = dquote($part);
   }

   return join q(.), @parts;
}

sub quote_string ($$) {
   my ($quote, $string) = @_;

   unless (defined $quote and length $quote <= 2 and length $quote >= 1) {
      throw('Quote characters [_1] must be a single character, or a pair of '
            . 'characters', [$quote // q()]);
   }

   my ($start_quote, $end_quote) = split m{}mx, $quote;

   $end_quote ||= $start_quote;
   $string =~ s{
      ( \\                 # backslash
        | \Q$start_quote\E # start quote
        | \Q$end_quote\E   # end quote
      )
   }{\\$1}gmsx;

   return "${start_quote}${string}${end_quote}";
}

sub squote ($) {
   my $string = shift;

   return quote_string("'", $string);
}

sub throw (;@) {
   EXCEPTION_CLASS->throw(@_);
}

sub trim (;$$) {
   my $chars = $_[1] // " \t";
   (my $value = $_[0] // q()) =~ s{ \A [$chars]+ }{}mx;

   chomp $value;
   $value =~ s{ [$chars]+ \z }{}mx;
   return $value;
}

sub unquote_string ($) {
   my $string = shift;

   return unless defined $string;

   $string =~ s{\A.}{}msx; $string =~ s{.\z}{}msx;

   $string =~ s{
      \G
      (?:
         ( [^\\]+ )  # Not a backslash
         | \\(.)     # A backslash-escaped character
         | \\ \z     # A single backslash at the end of the string (edge case)
      )
   }{defined $1 ? $1 : $2 || q()}egmsx;

   return $string;
}

1;
