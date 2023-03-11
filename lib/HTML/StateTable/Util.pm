package HTML::StateTable::Util;

use strictures;

use HTML::Entities              qw( encode_entities );
use HTML::StateTable::Constants qw( COL_INFO_TYPE_ATTR DOT EXCEPTION_CLASS );
use Module::Runtime             qw( require_module );
use Unexpected::Functions       qw( is_class_loaded );
use Try::Tiny;

use Sub::Exporter -setup => { exports => [
   qw( dquote encode_only_entities ensure_class_loaded escape_formula
       foreign_sort json_bool quote_column_name quote_string squote throw
       trim unquote_string )
]};

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Util - Utility functions

=head1 Synopsis

   use HTML::StateTable::Util;

=head1 Description

Utility functions

=head1 Configuration and Environment

None

=head1 Subroutines/Methods

Defines the following functions;

=over 3

=item throw( @args )

Calls the C<throw> method on the C<EXCEPTION_CLASS> passing the supplied
arguments into the exception class constructor call. Raises an exception
(dies on the exception class object reference)

=cut

sub throw (;@) {
   EXCEPTION_CLASS->throw(@_);
}

=item dquote( string )

Wraps and returns the supplied string in double quotes

=cut

sub dquote ($) {
   my $string = shift;

   return quote_string('"', $string);
}

=item encode_only_entities( html )

Encode control chars and high bit chars, but leave '<', '&', '>', ''' and
'"'. Encode as decimal rather than hex, to keep Lotus Notes happy

=cut

sub encode_only_entities {
   my $html = shift;

   $html =~ s{([^<>&"'\n\r\t !\#\$%\(-;=?-~])}{ #"emacs
      $HTML::Entities::char2entity{$1} || '&#' . ord($1) . ';'
   }ge;

   return $html;
}

=item ensure_class_loaded( class_name, options )

Loads the specified C<class_name> at runtime. The optional has reference of
options includes; C<ignore_loaded> which if true will load the class again.
Raises an exception if the class loads but the expected package remains
undefined

=cut

sub ensure_class_loaded ($;$) {
   my ($class, $opts) = @_;

   $opts //= {};

   return 1 if !$opts->{ignore_loaded} && is_class_loaded $class;

   try { require_module($class) } catch { throw $_ };

   throw 'Class [_1] loaded but package undefined', [$class]
      unless is_class_loaded $class;

   return 1;
}

=item escape_formula( @args )

Prefixes lines begining plus, minus, equals and @ with a tab character. Used
in the production of CSV files

=cut

sub escape_formula (@) {
   my @args = @_;

   return
      map { my $s = $_; $s =~ s{ \A ( [+\-=\@] ) }{\t$1}mx if defined $s; $s }
      @args;
}

=item foreign_sort( resultset, sorting, reverse )

Applies the order by clause to the supplied resultset and the returns it.
The C<sorting> argument is an array reference of hash references containing
the attributes C<column> and C<desc>. The C<reverse> argument is a boolean
which reverses the order of the sort

=cut

sub foreign_sort ($$$) {
   my ($resultset, $sorting, $reverse) = @_;

   my ($join, @order);

   for my $sort (@{$sorting}) {
      my $column = $sort->{column};

      return $resultset unless $column;

      my @relations     = split m{ \. }mx, $column;
      my $order_column  = pop @relations;
      my $join_relation = $relations[-1];
      my $source        = $resultset->result_source;

      for my $relation_name (@relations) {
         my $relation_info  = $source->relationship_info($relation_name);
         my $relation_class = $relation_info->{class};
         my $accessor       = $relation_info->{attrs}{accessor};

         throw 'Relationship [_1] -> [_2] must be single, not [_3]',
            (ref($source) || $source), $relation_class, $accessor
            unless $accessor eq 'single' or $accessor eq 'filter';

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

=item json_bool( scalar )

Evaluates the scalar value provided and returns references to true/false values
for serialising to JSON

=cut

sub json_bool ($) {
   return (shift) ? \1 : \0;
}

=item quote_column_name( @args )

Takes a list of strings, wraps each in double quotes and joins together with
a dot character. Returns the string

=cut

sub quote_column_name (;@) {
   my @parts = @_;

   for my $part (@parts) {
      throw 'Column must not be empty' unless $part;
      throw 'Column name contains invalid double quote' if $part =~ m{ \" }mx;
      $part = dquote($part);
   }

   return join DOT, @parts;
}

=item quote_string( quote, string )

Wraps the supplied string in the quote characters and insert backslashes into
the string if contains the quote characters

=cut

sub quote_string ($$) {
   my ($quote, $string) = @_;

   unless (defined $quote and length $quote <= 2 and length $quote >= 1) {
      throw 'Quote characters [_1] must be a single character, or a pair of '
          . 'characters', [$quote // q()];
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

=item squote( string )

Wraps and returns the supplied string in single quotes

=cut

sub squote ($) {
   my $string = shift;

   return quote_string("'", $string);
}

=item trim( string, characters )

Trims whitespace characters from both ends of the supplied string and returns
it. The list of C<characters> to remove is optional and defaults to space and
tab. Newlines at the end of the string are also removed

=cut

sub trim (;$$) {
   my $chars = $_[1] // " \t";
   (my $value = $_[0] // q()) =~ s{ \A [$chars]+ }{}mx;

   chomp $value;
   $value =~ s{ [$chars]+ \z }{}mx;
   return $value;
}

=item unquote_sting( string )

Removes the first and last characters from the supplied string. Also removes
one level of backslashes from within the string which it returns

=cut

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

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo>

=back

=head1 Incompatibilities

There are no known incompatibilities in this module

=head1 Bugs and Limitations

There are no known bugs in this module. Please report problems to
http://rt.cpan.org/NoAuth/Bugs.html?Dist=HTML-StateTable.
Patches are welcome

=head1 Acknowledgements

Larry Wall - For the Perl programming language

=head1 Author

Peter Flanigan, C<< <pjfl@cpan.org> >>

=head1 License and Copyright

Copyright (c) 2023 Peter Flanigan. All rights reserved

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself. See L<perlartistic>

This program is distributed in the hope that it will be useful,
but WITHOUT WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE

=cut

# Local Variables:
# mode: perl
# tab-width: 3
# End:
# vim: expandtab shiftwidth=3:
