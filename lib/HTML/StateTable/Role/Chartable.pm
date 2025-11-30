package HTML::StateTable::Role::Chartable;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool HashRef Str );
use HTML::StateTable::Util      qw( json_bool );
use Moo::Role;

=pod

=encoding utf-8

=head1 Name

HTML::StateTable::Role::Chartable - Draws pretty graphs and charts

=head1 Synopsis

   use Moo;
   extends 'HTML::StateTable';
   with 'HTML::StateTable::Role::Chartable';

=head1 Description

Draws pretty graphs and charts

=head1 Configuration and Environment

Defines the following attributes;

=over 3

=item chartable

A mutable boolean with a true default. If true the chart will be displayed

=cut

has 'chartable' => is => 'rw', isa => Bool, default => TRUE;

=item chartable_columns

An immutable array reference of string with an empty default. The list of
column names that contains chartable/graphable data (numbers)

=cut

has 'chartable_columns' => is => 'ro', isa => ArrayRef[Str],
   default => sub { [] };

=item chartable_config

A lazy immutable hash reference whose default is selected by
C<chartable_type>. Provides configuration data for the client JS chart library

=cut

has 'chartable_config' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift; return $self->_chartable_configs->{$self->chartable_type};
};

=item chartable_type

An immutable string which defaults to 'bar'. The type of chart/graph to draw,
can be one of; 'bar', 'line', or 'pie'

=cut

has 'chartable_type' => is => 'ro', isa => Str, default => 'bar';

has '_chartable_configs' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return {
      bar => {
         chart    => {
            type  => 'bar',
            backgroundColor => 'transparent',
         },
         title    => {
            align => 'left',
            style => { fontWeight => 'normal' },
            text  => $self->chartable_title_text,
            y     => 9,
         },
         subtitle => { align => 'left', text => $self->chartable_subtitle_text},
         xAxis    => { title => { text => $self->chartable_xaxis_title } },
         yAxis    => {
            labels => { overflow => 'justify' },
            min    => 0,
            title  => { align => 'high', text => $self->chartable_yaxis_title },
         },
         accessibility => { enabled => json_bool FALSE },
         legend        => {
            align           => 'right',
            borderWidth     => 1,
            layout          => 'vertical',
            floating        => json_bool TRUE,
            shadow          => json_bool TRUE,
            verticalAlign   => 'top',
            x               => -40,
            y               => 80,
         },
         plotOptions => {
            bar      => { dataLabels => { enabled => json_bool TRUE } },
            %{$self->chartable_plot_options}
         },
         credits     => { enabled => json_bool FALSE },
      },
      line => {
         chart    => {
            type  => 'line',
            backgroundColor => 'transparent',
         },
         title    => {
            align => 'left',
            style => { fontWeight => 'normal' },
            text  => $self->chartable_title_text,
            y     => 9,
         },
         subtitle => { align => 'left', text => $self->chartable_subtitle_text},
         yAxis    => { title => { text => $self->chartable_yaxis_title } },
         xAxis    => { title => { text => $self->chartable_xaxis_title } },
         accessibility => { enabled => json_bool FALSE },
         legend        => {
            align => 'right', layout => 'vertical', verticalAlign => 'middle'
         },
         plotOptions   => $self->chartable_plot_options,
         responsive    => {
            rules => [{
               condition    => { maxWidth => 500 },
               chartOptions => {
                  legend    => {
                     align  => 'center',
                     layout => 'horizontal',
                     verticalAlign => 'bottom'
                  }
               }
            }]
         }
      },
      pie => {
         chart => {
            type => 'pie',
            backgroundColor     => 'transparent',
            plotBackgroundColor => NUL,
            plotBorderWidth     => NUL,
            plotShadow          => json_bool FALSE,
         },
         title    => {
            align => 'left',
            style => { fontWeight => 'normal' },
            text  => $self->chartable_title_text,
            y     => 9,
         },
         subtitle => { align => 'left', text => $self->chartable_subtitle_text},
         accessibility => { enabled => json_bool FALSE },
         plotOptions   => {
            pie => {
               allowPointSelect => json_bool TRUE,
               cursor           => 'pointer',
               dataLabels       => {
                  enabled => json_bool TRUE,
                  format  => '<b>{point.name}</b>: {point.percentage:.1f} %'
               }
            },
            %{$self->chartable_plot_options}
         },
         tooltip => {
            pointFormat => '{series.name}: <b>{point.percentage:.1f}%</b>'
         },
      },
   };
};

=item chartable_location

An immutable string which defaults to 'Left'. Can be one of; 'Bottom', 'Left',
'Right', or 'Top'. The location relative to the table where the chart/graph
will be displayed

=cut

has 'chartable_location' => is => 'ro', isa => Str, default => 'Left';

=item chartable_plot_options

A lazy immutable hash reference with an empty default. This is merged into
the C<plotOptions> attribute of the C<chartable_config> hash reference

=cut

has 'chartable_plot_options' => is => 'lazy', isa => HashRef,
   default => sub { {} };

=item chartable_series

An immutable hash reference which defaults to C<pointStart> zero and
C<pointInterval> true. The client JS merges this with the data supplied
by the table to create the chart libraries data series

=cut

has 'chartable_series' => is => 'ro', isa => HashRef, default => sub {
   return { pointStart => 0, pointInterval => json_bool TRUE };
};

=item chartable_state_attr

An immutable array reference which defaults to; C<filterColumn>,
C<filterValue>, C<searchColumn>, and C<searchValue>. The names of the client JS
state attributes that trigger a repaint of the chart/graph

=cut

has 'chartable_state_attr' => is => 'ro', isa => ArrayRef, default => sub {
   return [ 'filterColumn', 'filterValue', 'searchColumn', 'searchValue' ];
};

=item chartable_subtitle_link

An immutable string with a null default. Displayed by the chart library in
the subtitle

=cut

has 'chartable_subtitle_link' => is => 'lazy', default => NUL;

=item chartable_subtitle_text

An immutable string which defaults to the table name wrapped in a link. The
subtitle displayed by the chart library

=cut

has 'chartable_subtitle_text' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;
   my $uri  = $self->chartable_subtitle_link;
   my $name = ucfirst $self->name;

   return 'Source: <a href="' . $uri . '" target="_blank">' . $name . '</a>';
};

=item chartable_title_text

An immutable string which defaults to the table name combined with the first
column name

=cut

has 'chartable_title_text' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;

   return ucfirst $self->name . ' by ' . $self->chartable_columns->[0];
};

=item chartable_xaxis_title

An immutable string which is displayed as the X axis title text

=cut

has 'chartable_xaxis_title' => is => 'lazy', isa => Str,
   default => 'Range: Low to High';

=item chartable_yaxis_title

An immutable string which is displayed as the Y axis title text

=cut

has 'chartable_yaxis_title' => is => 'lazy', isa => Str, default => sub {
   return 'Number of ' . ucfirst shift->chartable_columns->[0];
};

=back

=head1 Subroutines/Methods

Defines the following methods;

=over 3

=item BUILD

Runs after the table constructs. If C<chartable> is true add C<chartable> to
the list of serialisable table roles

=cut

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('chartable', __PACKAGE__) if $self->chartable;
   return;
};

=item serialise_chartable

Returns a hash reference of keys and values serialised for and sent to the JS
running in the browser. JSON booleans are correctly marked

=cut

sub serialise_chartable {
   my $self = shift;

   return {
      'columns'    => $self->chartable_columns,
      'config'     => $self->chartable_config,
      'figure'     => { location => $self->chartable_location },
      'series'     => $self->chartable_series,
      'state-attr' => $self->chartable_state_attr,
   };
}

use namespace::autoclean;

1;

__END__

=back

=head1 Diagnostics

None

=head1 Dependencies

=over 3

=item L<Moo::Role>

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

Copyright (c) 2024 Peter Flanigan. All rights reserved

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
