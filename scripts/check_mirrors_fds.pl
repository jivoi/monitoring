#!/usr/bin/perl -w
#
# $Id: check_mirrors_fds.pl,v 1.4 2006/10/16 16:17:57 tonchik Exp $
#
#
#

use strict;
use IO::Socket;
use Digest::MD5 'md5_hex';
use Net::DNS;
use Net::hostent;
use Time::HiRes qw(gettimeofday);

my %NAGERRORS=('OK'=>0,'WARNING'=>1,'CRITICAL'=>2,'UNKNOWN'=>3,'DEPENDENT'=>4);
my %MRRCHKERRORS=('OK'=>0,'WARNING'=>-1,'CRITICAL'=>-2,'UNKNOWN'=>-3,'DEPENDENT'=>-4 );

my $mrrsstate=$NAGERRORS{'OK'};
my $mrrsstatus="";
my $mrravg=0;

my $timeout = 3;


    my ($host, $port) = @ARGV;
    my ($mirr_name, $addr_ref, @addresses, $hent);

    if ($hent = gethostbyname($host)) {
        $mirr_name  = $hent->name;                # in case different
        $addr_ref   = $hent->addr_list;
        foreach my $mirr_ip (map { inet_ntoa($_) } @$addr_ref) {
            my $mirr_host;
            eval {
                $mirr_host = gethostbyaddr(inet_aton($mirr_ip), AF_INET)->name;
            };
            if ( $@ ) {
                print "no name for $mirr_ip of $host using ip";
                $mirr_host=$mirr_ip;
            };

            my ($msg, $mrrstate) = check_mirr($mirr_ip, $port, $mirr_host);

            if ($mrrstate < $MRRCHKERRORS{'OK'}) {
                #error
                $mrrsstate = $mrrstate if ($mrrsstate > $mrrstate);

            } else {
                #this ok
                $mrravg = $mrrstate if ($mrravg == 0);
                $mrravg = ($mrravg + $mrrstate) /2;
            }
            $mrrsstatus .= " " . $msg;
            #print "$msg $mrrstate\n";
        }
        print "OK, " if ($mrrsstate == $MRRCHKERRORS{'OK'});
        print "avg_time=$mrravg /$mrrsstatus\n";
        exit (-$mrrsstate);
    }
print "Can not resolve $host!!!\n";
exit ($NAGERRORS{'UNKNOWN'});

sub check_mirr {
    my ($host, $port, $name) = @_;
   
    my $mrr=$name . "[" . $host . "]:" . $port;
   
    my $mrrsrv=""; 
    ($mrrsrv = $name) =~ s/\w+-(\w+)\.(.*\.)?(\w+)\.(\w+)$/$1.example.$4/ ;

    my $ss = IO::Socket::INET->new(
    	'PeerAddr'	=> $mrrsrv,
    	'PeerPort'	=> $port,
    	'Proto'		=> 'udp',
    	'Type'		=> SOCK_DGRAM,
    	'Timeout'	=> 5,
    	);
    $mrrsrv="$mrrsrv:$port";
    unless (defined $ss) {
    	return "$mrr UNKNOWN: error creating socket to $mrrsrv", $MRRCHKERRORS{'UNKNOWN'};
    }

    my $hispaddr = sockaddr_in($port, inet_aton($host));

    # ping abc // 56a016b1f91a2d8d8de957c713ca61fa

    my $ping_msg = "ping abc // 56a016b1f91a2d8d8de957c713ca61fa";

    if (defined $ss->send($ping_msg, 0, $hispaddr)) {
        my $t0 = gettimeofday;
    	my $reply = "";
    	eval {
    		alarm $timeout;
    		$SIG{'ALRM'} = sub { die "qq!\n" };
    		$ss->recv($reply, 1500, 0);
    	};
        my $elapsed = sprintf ( "%.3f", gettimeofday - $t0 ) ;
    	alarm 0;
    	if ($@ eq "") {
    		if ($reply ne "") {
    			$reply = $1 if $reply =~ m#^(.+) // .+#;
    			return "$name ($elapsed); " , $elapsed;
    		} else {
    			return "$mrr CRITICAL: refused to $mrrsrv; ", $MRRCHKERRORS{'CRITICAL'};
    		}
    	} else {
    		return "$mrr CRITICAL: timeout($timeout) on $mrrsrv; ", $MRRCHKERRORS{'CRITICAL'};
    	}
    } else {
    	return "$mrr UNKNOWN: error sending packet to $mrrsrv; ", $MRRCHKERRORS{'UNKNOWN'};
    }
}


