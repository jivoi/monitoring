#!/usr/bin/perl
# $Id: psql_replication_check.pl,v 1.3 2005-07-11 22:00:30 cbbrowne Exp $#
# Documentation listed below.
# Credits:
# Afilias Canada
# Original script by jgoddard (2005-02-14)
# Modified by nadx (2005-05-11)
# Packaged by tgoodair (2005-05-12)

use strict;

use Pg;
use Getopt::Std;

our ($opt_h, $opt_d, $opt_p, $opt_U, $opt_w, $opt_c) = '';
my ($conn, $res, $status, @tuple);
my $query = 'SELECT * FROM replication_status' ;
my @rep_time;

# Issue a warning when replication is behind by 20 seconds
my $threshold_warning = 600;

# Issue a critical alert when replication is behind by 40 seconds
my $threshold_critical = 1800;

# Get the command line options
getopt('hdpUwc');
if (not $opt_h or not $opt_d or not $opt_p or not $opt_U)
{
	print("$0 -h <host> -d <db> -p <port> -U <username> -w <warning threshold> -c <critical threshold>\n");
	exit(3);
}

if (($opt_w =~ /^\d+$/) && ($opt_w)) {$threshold_warning = $opt_w};
if (($opt_c =~ /^\d+$/) && ($opt_c)) {$threshold_critical = $opt_c};

if ($threshold_critical < $threshold_warning) { print "Warning: Critical threshold is less than warning threshold.\n"; }

# .pgpass isn't read, so we're putting the password here
my $password = "Vse_puchkom";

# Connect to the database
$conn = Pg::setdbLogin($opt_h, $opt_p, '', '', $opt_d, $opt_U, $password);
$status = $conn->status;

if ($status ne PGRES_CONNECTION_OK)
{
	chomp(my $error = $conn->errorMessage);
	print("$error\n");
	exit(2);
}

# Do the query
$res = $conn->exec($query);
$status = $res->resultStatus;
if ($status ne PGRES_TUPLES_OK)
{
	chomp(my $error = $conn->errorMessage);
	print("$error\n");
	exit(3);
}

# Get the results
# tuple[0]object
# tuple[1]transaction date time
# tuple[2]age in seconds old
@tuple = $res->fetchrow;

# Debugging
# Uncomment the below to swap the second for seconds.  This is to simulate
# crazy replication times for when replication is not falling behind.
#$rep_time[1] = $rep_time[2]

# Check for a warning
if ($tuple[2] >= $threshold_warning and $tuple[2] < $threshold_critical)
{
	print("WARNING: $tuple[0], Created $tuple[1], Behind $tuple[2] seconds\n");
	exit(1);
}
# Or for a critical
elsif ($tuple[2] >= $threshold_critical)
{
	print("CRITICAL: $tuple[0], Created $tuple[1], Behind $tuple[2] seconds\n");
	exit(2);
}
# Otherwise, everything is ok
else
{
	printf("OK: $tuple[0], Created $tuple[1], Behind $tuple[2] second%s\n",$tuple[2] == 1 ? "" : "s" );
	exit(0);
}
