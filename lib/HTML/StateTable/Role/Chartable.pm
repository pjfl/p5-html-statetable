package HTML::StateTable::Role::Chartable;

use HTML::StateTable::Constants qw( FALSE NUL TRUE );
use HTML::StateTable::Types     qw( ArrayRef Bool HashRef Str );
use HTML::StateTable::Util      qw( json_bool );
use Moo::Role;

has 'chartable' => is => 'rw', isa => Bool, default => TRUE;

has 'chartable_columns' => is => 'ro', isa => ArrayRef[Str],
   default => sub { [] };

has 'chartable_config' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift; return $self->_chartable_configs->{$self->chartable_type};
};

has 'chartable_type' => is => 'ro', isa => Str, default => 'bar';

has '_chartable_configs' => is => 'lazy', isa => HashRef, default => sub {
   my $self = shift;

   return {
      bar => {
         chart    => { type  => 'bar' },
         title    => { align => 'left', text => $self->chartable_title_text },
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
         chart    => { type  => 'line' },
         title    => { align => 'left', text => $self->chartable_title_text },
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
            plotBackgroundColor => NUL,
            plotBorderWidth     => NUL,
            plotShadow          => json_bool FALSE,
         },
         title    => { align => 'left', text => $self->chartable_title_text },
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

has 'chartable_location' => is => 'ro', isa => Str, default => 'Top';

has 'chartable_plot_options' => is => 'lazy', isa => HashRef,
   default => sub { {} };

has 'chartable_series' => is => 'ro', isa => HashRef, default => sub {
   return { pointStart => 0, pointInterval => json_bool TRUE };
};

has 'chartable_subtitle_link' => is => 'lazy', default => NUL;

has 'chartable_subtitle_text' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;
   my $uri  = $self->chartable_subtitle_link;
   my $name = ucfirst $self->name;

   return 'Source: <a href="' . $uri . '" target="_blank">' . $name . '</a>';
};

has 'chartable_title_text' => is => 'lazy', isa => Str, default => sub {
   my $self = shift;

   return ucfirst $self->name . 's by ' . $self->chartable_columns->[0];
};

has 'chartable_xaxis_title' => is => 'lazy', isa => Str,
   default => 'Range: Low to High';

has 'chartable_yaxis_title' => is => 'lazy', isa => Str, default => sub {
   return 'Number of ' . ucfirst shift->chartable_columns->[0];
};

after 'BUILD' => sub {
   my $self = shift;

   $self->add_role('chartable', __PACKAGE__) if $self->chartable;
   return;
};

sub serialise_chartable {
   my $self = shift;

   return {
      columns => $self->chartable_columns,
      config  => $self->chartable_config,
      figure  => { location => $self->chartable_location },
      series  => $self->chartable_series
   };
}

use namespace::autoclean;

1;
