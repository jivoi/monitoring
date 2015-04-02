#!/usr/bin/perl

# (c) 2003, Rojer

$community = 'public';
$default_warn = 20000;
$default_crit = 20000;

use Getopt::Std;

%ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my %OPTS;
if (!getopts('H:C:', \%OPTS)) {
	print "bad command line!\n";
	exit $ERRORS{'UNKNOWN'};
	}

# -H host
# -C community
# -N - NetMRG mode: no range checking
# -m warning,critical - set thresholds 

#while (($k,$v) = each %OPTS) { print "$k = $v\n" }

$community = $OPTS{C} if exists $OPTS{C};

print "you must specify hostname with -H\n" and exit $ERRORS{'UNKNOWN'} unless $host = $OPTS{H};

$_ = `/usr/local/bin/snmpget -Oq -c $community -v 1 -t 20 $host .1.3.6.1.4.1.2021.8.1.123.101.1 2>&1`;

if (/^\S+? "(.+)"/) {
	my $status = $1;
	print "$status\n";
	exit $ERRORS{CRITICAL} unless $status =~ /^ok\s*$/;
	exit $ERRORS{OK};
	} elsif (/timeout/i) {
		print;
		exit $ERRORS{WARNING};
		} else {
			print "parse error: $_\n";
			exit $ERRORS{WARNING};
			}
