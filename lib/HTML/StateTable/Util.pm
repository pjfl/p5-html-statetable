package HTML::StateTable::Util;

use strictures;

use HTML::StateTable::Constants qw( EXCEPTION_CLASS );

use Sub::Exporter -setup => {
   exports => [
      qw( foreign_sort quote_column_name quote_double quote_single quote_string
          throw unquote_string )
   ],
};

sub foreign_sort ($$$) {
   my ($resultset, $sorting, $reverse) = @_;

   my ($join, @order);

   for my $sort (@{$sorting}) {
      my $column = $sort->{column} || $sorting;

      return $resultset unless $column;

      my $order_desc    = $reverse ? !$sort->{desc} : !!$sort->{desc};
      my @relations     = split m{\.}, $column;
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

      my $column_info = eval { $source->column_info($order_column) }
         || { data_type => 'INTEGER' };

      for my $relation (reverse @relations) {
         $join = defined $join ? { $relation => $join } : $relation;
      }

      my $join_column = $join_relation || $resultset->current_source_alias;

      $order_column = quote_column_name($join_column, $order_column);

      my $direction = $order_desc ? '-desc' : '-asc';
      my $type      = $column_info->{data_type};
      my $order_by  = $type && $type eq 'TEXT'
         ? \"LOWER($order_column)" #"
         : \$order_column;

      push @order, { $direction => $order_by };
   }

   return $resultset->search(undef, { join => $join, order_by => \@order });
}

sub quote_column_name {
   my @parts = @_;

   for my $part (@parts) {
      throw('Column must not be empty') unless $part;
      throw('Column name contains invalid double quote') if $part =~ m{ \" }mx;
      $part = quote_double($part);
   }

   return join q(.), @parts;
}

sub quote_double ($) {
   my $string = shift;

   return quote_string('"', $string);
}

sub quote_single ($) {
   my $string = shift;

   return quote_string("'", $string);
}

sub quote_string ($$) {
   my ($quote, $string) = @_;

   unless (defined $quote and length $quote <= 2 and length $quote >= 1) {
      throw('Quote characters [_1] must be a single character, or a pair of '
            . 'characters', [$quote // q()]);
   }

   my ($start_quote, $end_quote) = split //, $quote;

   $end_quote //= $start_quote;

   $string =~ s{
      ( \\                  # backslash
        |  \Q$start_quote\E # start quote
        |  \Q$end_quote\E   # end quote
      )
   }{\\$1}gmsx;

   return "${start_quote}${string}${end_quote}";
}

sub throw (;@) {
   EXCEPTION_CLASS->throw(@_);
}

sub unquote_string ($) {
   my $string = shift;

   return unless defined $string;

   $string =~ s{\A.}{}msx;
   $string =~ s{.\z}{}msx;

   $string =~ s{
      \G
      (?:
         ( [^\\]+ )  # Not a backslash
         | \\(.)     # A backslash-escaped character
         | \\\z      # A single backslash at the end of the string (edge case)
      )
   }{defined $1 ? $1 : $2 || q()}gemsx;

   return $string;
}

1;
