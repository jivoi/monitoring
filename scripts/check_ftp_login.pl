#!/usr/bin/perl -w

use strict;
use Net::FTP;
use Getopt::Std;
use Time::HiRes qw(gettimeofday);

my %OPTS;
getopts('H:u:p:t:P:', \%OPTS);


my $server = $OPTS{H};
my $username = $OPTS{u} || "anonymous";
chomp(my $password = $OPTS{p} || '-anonymous' );
my $timeout = $OPTS{t} || 60;
my $port = $OPTS{P} || 21;
my %ERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
my $befor = gettimeofday;
sub usage($) {
        print qq{
check_ftp_login v 0.1 Copyright (c) 2007 Khomyakov Aleksandr <airo\@airo.com.ru>
Check status ftp and possibility ftp logins \n
Usage: check_ftp_login.pl -H <host> -u <user> -p <password> [-t timeout -P port]\n
-H\n\tHostname or IP address
-u\n\tusername (default -u anonymous)
-p\n\tpassword (default -p  -anonymous\@
-t\n\tSeconds before connection times out (default : 60 second)
-p\n\tport number (default 21)
};
exit(shift);
}
print usage($ERRORS{UNKNOWN}) unless defined($OPTS{H});

my $ftp=Net::FTP->new($server, Debug => 0, Timeout => $timeout, Port => $port);
print "Unable to connect to FTP server after $timeout second\n $!" and exit($ERRORS{CRITICAL})
        unless defined($ftp);

if(!$ftp->login($OPTS{u}, $OPTS{p})) {
        print STDERR "Cannot login: " . $ftp->message . "\n";
        exit($ERRORS{CRITICAL});
        }

$ftp->quit;

my $elapsed = gettimeofday - $befor;

print(sprintf "FTP_LOGIN OK -  %.3f second response\n", $elapsed);
exit($ERRORS{OK});

