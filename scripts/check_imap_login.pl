#!/usr/bin/perl 

# Copyright (C) 2007 Khomyakov Aleksandr <airo@airo.com.ru>

use strict;
use Net::IMAP::Simple;
use Email::Simple;
use Getopt::Std;
use Time::HiRes qw(gettimeofday);


my %OPTS;
getopts('H:u:p:t:', \%OPTS);
my $server = $OPTS{H};
my $user = $OPTS{u};
my $pass = $OPTS{p};
my $timeout = $OPTS{t} || 10; # default timeout
my $befor = gettimeofday;
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);

sub usage($) {
    print qq{Usage: check_imap_login.pl -H <host>  -u <user> -p <password> [-t timeout ]\n};
    exit(shift);
}


print usage($ERRORS{UNKNOWN}) unless defined($OPTS{H}) and defined($OPTS{u}) and defined($OPTS{p});

my $imap = Net::IMAP::Simple->new($server,timeout=>$timeout);
print "Unable to connect to IMAP after $timeout sec\n" and exit($ERRORS{CRITICAL})
        unless defined($imap);

if(!$imap->login($user,$pass)){
	print STDERR "Login failed: " . $imap->errstr . "\n";
        exit($ERRORS{CRITICAL});
    }

my $nm = $imap->select('INBOX');

$imap->quit;

my $elapsed = gettimeofday - $befor;

print(sprintf "IMAP_LOGIN OK - %.3f second response\n", $elapsed);
exit($ERRORS{OK});




