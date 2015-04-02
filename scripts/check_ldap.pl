#!/usr/bin/perl -w

#
# $Id: check_ldap.pl,v 1.3 2005/09/07 08:06:31 rojer Exp $
#
# Nagios/NetMRG LDAP checker
#

use strict;

use Net::LDAP;
use Getopt::Std;
use Time::HiRes qw( gettimeofday tv_interval );

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my %O = ();
# -h LDAP host, -p - LDAP port, -t - timeout
# -D - bind DN, -w - bind password
# -b - search base, -f - search filter
# -N - NetMRG output mode
getopts('h:p:t:D:w:b:f:T:N', \%O);

my $port = exists $O{'p'} ? $O{'p'} : 389;
my $timeout = exists $O{'t'} ? $O{'t'} : 5;
my $N = exists $O{'N'} ? 1 : 0;

unless (exists $O{'h'}) {
	print "no hostname provided.\n";
	exit $ERRORS{'UNKNOWN'};
}

my $t0 = [gettimeofday];

my $ldap = Net::LDAP->new( $O{'h'},
			'port' => $port,
			'timeout' => $timeout
			);

unless (defined $ldap) {
	print $N ? "U" : "could not connect: $@\n";
	exit $ERRORS{'CRITICAL'};
}

unless (exists $O{'D'} and exists $O{'w'}) {
	my $elapsed = tv_interval ($t0, [gettimeofday]);
	print $N ? $elapsed : "Ok, $elapsed sec. (no bind or search performed)\n";
	exit $ERRORS{'OK'};
}

$SIG{'ALRM'} = sub { print $N ? "U" : "Timeout.\n"; exit $ERRORS{'CRITICAL'}; };
alarm $timeout;

my $mesg = $ldap->bind(	$O{'D'}, 'password' => $O{'w'} );

if ($mesg->code()) {
	print $N ? "U" : ("could not bind: ", $mesg->error(), "\n");
	exit $ERRORS{'CRITICAL'};
}

unless (exists $O{'b'} and exists $O{'f'}) {
	my $elapsed = tv_interval ($t0, [gettimeofday]);
        print $N ? $elapsed : "Ok, $elapsed sec. (no search performed)\n";
        exit $ERRORS{'OK'};
}

$mesg = $ldap->search(	base => $O{'b'},
			filter => $O{'f'}
			);

if ($mesg->code()) {
	print $N ? "U" : ("search failed: ", $mesg->error(), "\n");
	exit $ERRORS{'CRITICAL'};
} elsif ($mesg->entries == 0) {
	print $N ? "U" : "search returned no results.\n";
	exit $ERRORS{'WARNING'};
}

my $elapsed = tv_interval ($t0, [gettimeofday]);

print $N ? $elapsed : "Ok, $elapsed sec.\n";
exit $ERRORS{'OK'};

END { $ldap->unbind() if defined $ldap; };
