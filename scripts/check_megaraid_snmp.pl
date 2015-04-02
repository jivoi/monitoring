#!/usr/bin/perl -w

#
# $Id: check_megaraid_snmp.pl,v 1.4 2005/08/24 16:37:11 rojer Exp $
#

# checker for LSI MegaRaid adapters,
# using custom MIB exported by LSI's SNMP Extension Agent
# Rojer, 2005/08/24

use strict;
use Getopt::Std;
use POSIX 'strftime';

my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

my $snmpwalk_cmd = '/usr/local/bin/snmpwalk -OQn -c %COMMUNITY -v 1';
# %COMMUNITY gets replaced later

# walk this
my $walk_oid_base = '.1.3.6.1.4.1.3582.1.1';
my $ldstate_oid_base = '.1.3.6.1.4.1.3582.1.1.2.1.3'; # logical disk state [RAID-Adapter-MIB::status => optimal(2)]
my $phstate_oid_base = '.1.3.6.1.4.1.3582.1.1.3.1.4'; # physical disk status [RAID-Adapter-MIB::state => online(3), nonDisk(20)]

my %LDSTATES = (
	0 => 'Offline',
	1 => 'Degraded',
	2 => 'Optimal',
	3 => 'Initializing',
	4 => 'ChkCons'
);

my %PHDSTATES = (
	1  => 'Ready',
	3  => 'Online',
	4  => 'Failed',
	5  => 'Rebuilding',
	6  => 'HotSpare',
	20 => 'NotADisk'
);

my %opts = ();
# -H host, -c - community
getopts('H:c:', \%opts);

unless (exists $opts{'H'} and exists $opts{'c'}) {
	fatal_egor("-H and -c are required parameters.\n");
}

$snmpwalk_cmd =~ s/%COMMUNITY/$opts{'c'}/;

my $H = $opts{'H'};

my $exitstatus = $ERRORS{'OK'};

my $cmd = "$snmpwalk_cmd $H $walk_oid_base";
my @output = `$cmd`;

my $result_string = "";

print "error executing command!" and exit $ERRORS{'UNKNOWN'} unless @output;

# check logical drives

foreach (grep /^\Q$ldstate_oid_base\E/, @output) {
	if (/^\Q$ldstate_oid_base\E\.\d+\.(\d+)\s*=\s*(\d+)/) {
		my ($ldnum, $ldstate) = ($1, $LDSTATES{$2});
		unless ($ldstate eq 'Optimal' or $ldstate eq 'ChkCons') {
			$result_string .= "LD $ldnum is $ldstate. ";

			if ($exitstatus != $ERRORS{'CRITICAL'}) {
				$exitstatus = $ldstate eq 'Offline' ?
					$ERRORS{'CRITICAL'} : $ERRORS{'WARNING'};
			}
		}
	} else {
		$exitstatus = $ERRORS{'UNKNOWN'};
		$result_string = 'could not parse snmpwalk output. (ld) ';
	}
}

if ($exitstatus != $ERRORS{'OK'}) {
	# check physical drives
	foreach (grep /^\Q$phstate_oid_base\E/, @output) {
		if (/^\Q$phstate_oid_base\E\.\d+\.\d+\.(\d+)\.\d+\s*=\s*(\d+)/) {;
			my ($dnum, $dstate) = ($1, $PHDSTATES{$2});
			unless (grep /$dstate/, ('Online', 'Ready', 'HotSpare', 'NotADisk')) {
				$result_string .= "Disk $dnum is $dstate. ";
			}
		} else {
			$exitstatus = $ERRORS{'UNKNOWN'};
			$result_string = 'could not parse snmpwalk output. (pd) ';
		}
	}
}

if ($exitstatus eq $ERRORS{'OK'}) {
	print "Ok.\n";
} else {
	print "NOT ok: $result_string\n";
}

exit $exitstatus;

sub fatal_egor {
	print $_[0];
	exit $ERRORS{'UNKNOWN'};
}

