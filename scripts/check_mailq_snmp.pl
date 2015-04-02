#!/usr/bin/perl

# (c) 2003, Rojer

$community = 'public';
$cmd = 'mailq';
$default_warn = 20000;
$default_crit = 20000;


use Getopt::Std;

%ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my %OPTS;
if (!getopts('hH:C:m:e:N', \%OPTS)) {
	print "bad command line!\n";
	exit $ERRORS{'UNKNOWN'};
	}

# -H host
# -C community
# -N - NetMRG mode: no range checking
# -m warning,critical - set thresholds 
# -e mailq check command

#while (($k,$v) = each %OPTS) { print "$k = $v\n" }

$community = $OPTS{C} if exists $OPTS{C};
$cmd = $OPTS{e} if exists $OPTS{e};

print "you must specify hostname with -H\n" and exit $ERRORS{'UNKNOWN'} unless $host = $OPTS{H};

if ($OPTS{N} and $OPTS{m}) {
	print "-m and -N are incompatible.\n";
	exit $ERRORS{'UNKNOWN'};
	}
if ($OPTS{m} =~ /([\d-]+),([\d-]+)/ and not ($1 <= $2 or $1 < 0 or $2 < 0)) {
	print "Given threshold values are incorrect.\n";
	exit $ERRORS{'UNKNOWN'};
	}

$warn = $1; $crit = $2;

@lines = `/usr/local/bin/snmpwalk -On -c $community -v 1 $host enterprises.ucdavis.extTable.extEntry.extNames`;

while ($_ = shift @lines and not /$cmd/) {};

if ($_) {
	/\.(\d+) / or exit $ERRORS{'UNKNOWN'};
	$index = $1;
	$_ = `/usr/local/bin/snmpget -Oq -c $community -v 1 $host enterprises.ucdavis.extTable.extEntry.extOutput.$index`;
	chomp;
	if (/(\d+)-(\d+)$/) {
		$warn = $crit = $2 if $warn == 0;
		$_ = $1;
		}
	if (/(\d+)$/) {
		print "$1\n" and exit(0) if ($OPTS{N});
		$warn = $warn || $default_warn; $crit = $crit || $default_crit;
		print "mailq=$1\n" and exit $ERRORS{'OK'} if ($warn < 0 or $crit < 0); # no check
		print "OK: mailq=$1, ".($warn==$crit?"WT=CT=$warn":"WT=$warn,CT=$crit")."\n" and exit $ERRORS{'OK'} if ($1 < $warn);
		print "CRIT: mailq=$1, ".($warn==$crit?"WT=CT=$warn":"WT=$warn,CT=$crit")."\n" and exit $ERRORS{'CRITICAL'} if ($1 >= $crit);
		print "WARN: mailq=$1, ".($warn==$crit?"WT=CT=$warn":"WT=$warn,CT=$crit")."\n" and exit $ERRORS{'WARNING'};
		} else {
			print "could not get extOutput (index=$index).\n";
			exit $ERRORS{'UNKNOWN'};
			}
	} else {
		print "U\n" and exit(-1) if ($OPTS{N});
		print "mailq record not found!\n";
		exit $ERRORS{'UNKNOWN'};
		}
