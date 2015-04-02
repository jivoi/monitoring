#!/usr/bin/perl -w

#use strict;
use Getopt::Std;

my $community = 'SNMPEXAMPLE';


my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my %OPTS;
if (!getopts('hH:C:c:', \%OPTS)) {
        print "bad command line!\n";
        exit $ERRORS{'UNKNOWN'};
        }

# -H host
# -C community
# -c command

$community = $OPTS{C} if exists $OPTS{C};
my $cmd = $OPTS{c} if exists $OPTS{c};

if ($OPTS{c}) {
        $cmd = $OPTS{c};
} else {
        print "Usage: -H <host> -C <community> -c <command>\n" and exit $ERRORS{'UNKNOWN'};
}

print "you must specify hostname with -H\n" and exit $ERRORS{'UNKNOWN'} unless my $host = $OPTS{H};


my @lines = `/usr/local/bin/snmpwalk -On -c $community -v 1 $host enterprises.ucdavis.extTable.extEntry.extNames`;

while ($_ = shift @lines and not /$cmd/) {};

if ($_ =~ /\.(\d+) /) {
        my $index = $1;
        $_ = `/usr/local/bin/snmpget -OvQ -c $community -v 1 $host enterprises.ucdavis.extTable.extEntry.extOutput.$index`;


        if ($_ =~ /OK/) { print $_; exit 0;}
        elsif ($_ =~ /WARNING/) { print $_; exit 1;}
        elsif ($_ =~ /CRITICAL/) { print $_; exit 2;}
        else {
                print "could not get extOutput (index=$index).\n";
                exit $ERRORS{'UNKNOWN'};
        }
} else {
        print  "$cmd record not found!\n" and exit $ERRORS{'UNKNOWN'};
}
