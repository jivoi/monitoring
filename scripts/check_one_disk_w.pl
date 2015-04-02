#!/usr/bin/perl

use strict;
use Getopt::Std;

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my %opt;

getopts('W:C:H:', \%opt);

my $disk = uc pop @ARGV;

exit usage() unless $opt{H} and $opt{C} and $disk and $opt{W} > 0;

$disk .= ':' unless $disk =~ /:$/ or $disk =~ /virtual/i;

my @lines = `/usr/local/bin/snmpwalk -On -v 1 -c $opt{C} $opt{H} 1.3.6.1.2.1.25.2.3.1`;

my $exitcode = $? >> 8;

print "snmpwalk returned exit code: $exitcode\n" and exit $ERRORS{UNKNOWN} if $exitcode != 0;

my $index;
my %oids;
for (my $i = 0; $i < scalar @lines; $i++) {
	$index = $1 if $lines[$i] =~ /\.([\d+]) = STRING: \"*$disk/i;
	$oids{$1} = $2 if $lines[$i] =~ /\.([\d+]\.[\d+]) = .+?: (.+)[\r\n]*$/;
	}

if (defined $index) {
	my $total = $oids{"5.$index"};
	my $used = $oids{"6.$index"};
	my $blocksize = $oids{"4.$index"};
	my $avail = ($total-$used)*$blocksize;
	my $availkb = $avail / 1024;

	if ($avail < 1024) {
		print "CRITICAL: $disk $avail available\n";
		exit $ERRORS{CRITICAL};
		}
	if ($availkb < $opt{W}) {
		print "WARNING: $disk ".nifty_number($avail)." available\n";
		exit $ERRORS{WARNING};
		}
	print "$disk ", nifty_number($avail), " available, ", nifty_number($opt{W}*1024), " threshold.\n";
	} else { print @lines,"index not found. bad disk name ($disk)?\n" and exit $ERRORS{UNKNOWN} };

#print @lines;

print "\n";

sub nifty_number {

	my $amount = shift;

	my $kilobyte = 1024;
	my $megabyte = $kilobyte*1024;
	my $gigabyte = $megabyte*1024;
	my $terabyte = $gigabyte*1024;

	my $test = $amount / $terabyte;
	return sprintf("%.2fT", $test) if ($test > 1);
	my $test = $amount / $gigabyte;
	return sprintf("%.2fG", $test) if ($test > 1);
        my $test = $amount / $megabyte;
        return sprintf("%.2fM", $test) if ($test > 1);
        my $test = $amount / $kilobyte;
        return sprintf("%.2fK", $test) if ($test > 1);
	return $amount;
	}

sub usage {

	print "Usage: $0 -H host -C community -W threshold\n\n";

	}
