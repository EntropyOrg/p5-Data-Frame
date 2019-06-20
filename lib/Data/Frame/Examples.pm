package Data::Frame::Examples;

# ABSTRACT: Example data sets

use Data::Frame::Setup;

use File::ShareDir qw(dist_dir);
use Module::Runtime qw(module_notional_filename);
use Path::Tiny;

use Data::Frame;
use Data::Frame::Util qw(factor);

use parent qw(Exporter::Tiny);

my %data_setup = (
    airquality => {},
    diamonds   => {
        postprocess => sub {
            my ($df) = @_;
            return _factorize(
                $df,
                cut     => [ 'Fair', 'Good', 'Very Good', 'Premium', 'Ideal' ],
                color   => [ 'D' .. 'J' ],
                clarity => [qw(I1 SI2 SI1 VS2 VS1 VVS2 VVS1 IF)]
            );
        }
    },
    economics      => { params => { dtype => { date => 'datetime' } } },
    economics_long => { params => { dtype => { date => 'datetime' } } },
    faithfuld      => {},
    iris           => { params => { dtype => { Species => 'factor' } } },
    mpg            => {},
    mtcars         => {},
    txhousing      => {},
);
my @data_names = sort keys %data_setup;

our @EXPORT_OK   = ( @data_names, 'dataset_names' );
our %EXPORT_TAGS = (
    datasets => \@data_names,
    all      => \@EXPORT_OK,
);

my $data_raw_dir;

#TODO: Change this dist name when merging this to Data::Frame.
try { $data_raw_dir = dist_dir('Alt-Data-Frame-ButMore'); }
catch {
    # for dev env only
    my $path = path( $INC{ module_notional_filename(__PACKAGE__) } );
    $data_raw_dir =
      path( $path->parent( ( () = __PACKAGE__ =~ /(::)/g ) + 2 ), 'data-raw' )
      . '';
}

for my $name (@data_names) {
    no strict 'refs';
    *{$name} = _make_data( $name, $data_setup{$name} );
}

=func dataset_names

Returns an array of names of the datasets in this module. 

=cut

sub dataset_names { @data_names; }

sub _factorize {
    my ($df, %var_levels ) = @_;

    for my $var (sort keys %var_levels) {
        my $levels = $var_levels{$var};
        $df->set(
            $var,
            factor(
                $df->at($var),
                levels  => $levels,
                ordered => true
            )
        );
    }
    return $df;
};

#TODO: switch from csv to some other format for speed
sub _make_data {
    my ( $name, $setup ) = @_;

    return sub {
        state $df;
        unless ( defined $df ) {
            $df = Data::Frame->from_csv(
                "$data_raw_dir/$name.csv",
                header => true,
                %{ $setup->{params} }
            );
            if (my $postprocess = $setup->{postprocess}) {
                $df = $postprocess->($df);
            }
        }
        return $df;
    };
}

1;

__END__

=head1 SYNOPSIS

    use Data::Frame::Examples qw(:datasets dataset_names);

    my $datasets = dataset_names();    # names of all example datasets

    my $mtcars = mtcars();

=head1 DESCRIPTION

Example datasets as L<Data::Frame> objects.

Checkout C<Data::Frame::Examples::dataset_names()> for an array of
example datasets provided by this module.

=head1 DATASETS

=head2 airquality

A dataset with 154 observations on 6 variables,
for daily readings of the following air quality values for May 1, 1973 to
September 30, 1973.

The variables are,

=for :list
* Ozone
numeric Ozone (ppb)
* Solar_R
numeric Solar R (lang)
* Wind
numeric Wind (mph)
* Temp
numeric Temperature (degrees F)
* Month
numeric Month (1-12)
* Day
numeric Day of month (1-31)

=head2 diamonds

A dataset containing the prices and other attributes of almost 53,940
diamonds on 10 variables.

The variables are,

=for :list
* price
price in US dollars
* carat
weight of the diamond
* cut
quality of the cut (Fair, Good, Very Good, Premium, Ideal)
* color
diamond colour, from J (worst) to D (best)
* clarity
a measurement of how clear the diamond is
(I1 (worst), SI2, SI1, VS2, VS1, VVS2, VVS1, IF (best))
* x
length in mm
* y
width in mm
* z
depth in mm
* depth
total depth percentage = z / mean(x, y) = 2 * z / (x + y) (43–79)
* table
width of top of diamond relative to widest point

=head2 economics

A dataset with 574 rows and 6 variables, 
produced from US economic time series data available from
L<http://research.stlouisfed.org/fred2>.

The variables are,

=for :list
* date
Month of data collection
* psavert
personal saving rate
* pce
personal consumption expenditures, in billions of dollars
* unemploy
number of unemployed in thousands
* uempmed
median duration of unemployment, in weeks
* pop
total population, in thousands

=head2 economics_long

A dataset with 2870 rows and 4 variables.

It's from the same data source as C<economics>, except that C<economics>
is in "wide" format, this C<economics_long> is in "long" format.

=head2 faithfuld

A 2d density estimate of the waiting and eruptions variables data faithful.
5,625 observations and 3 variables.

=head2 iris

A dataset with 150 cases and 5 variables, for 50 flowers from each of 3
species of iris.

The variables are,

=for :list
* Sepal_Length
* Sepal_Width
* Petal_Length
* Petal_Width
* Species
The species are I<setosa>, I<versicolor>, and I<virginica>.

=head2 mpg

A subset of the fuel economy data that the EPA makes available on
L<http://fueleconomy.gov>. 234 rows and 11 variables.

The variables are,

=for :list
* manufacturer
* model
model name
* displ
Engine displacement, in litres
* year
year of manufacture
* cyl
number of cylinders
* trans
type of transmission
* drv
f = front-wheel drive, r = rear wheel drive, 4 = 4wd
* cty
city miles per gallon
* hwy
highway miles per gallon
* fl
fuel type
* class
"type" of car

=head2 mtcars

Data extracted from the 1974 I<Motor Trend US> magazine, for 32 automobiles
(1973-74 models). 32 observations on 11 variables.

The variables are,

=for :list
* mpg
Miles/(US) gallon
* cyl
Number of cylinders
* disp
Displacement (cu.in.)
* hp
Gross horsepower
* drat
Rear axle ratio
* wt
Weight (1000 lbs)
* qseq
1/4 mile time
* vs
V/S
* am
Transmission (0 = automatic, 1 = manual)
* gear
Number of forward gears
* carb
Number of carburetors

=head2 txhousing

Information about the housing market in Texas provided by the TAMU real
estate center, L<http://recenter.tamu.edu/>.
8602 observations and 9 variables.

The variables are,

=for :list
* city
Name of MLS area
* year,month,date
* sales
Number of sales
* volume
Total value of sales
* median
Median sale price
* listings
Total active listings
* inventory
"Months inventory": amount of time it would take to sell all current
listings at current pace of sales.

=head1 SEE ALSO

L<Data::Frame>
