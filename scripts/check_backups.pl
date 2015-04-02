#!/usr/bin/env perl
use Getopt::Std;
%opt = ();
getopt('NH:c:I:W:C', \%opt);
die "Not enough parameters\n".usage() unless ($opt{H} and $opt{c} and $opt{I});

$value_cmd = "snmpwalk -v2c -c $opt{c} $opt{H} .1.3.6.1.4.1.2021.8.1.101.$opt{I} |";
$name_cmd = "snmpwalk -v2c -c $opt{c} $opt{H} .1.3.6.1.4.1.2021.8.1.3.$opt{I} |";

open SNMPINFO, $value_cmd or die "U\n";
my $response =();
while ($stop == 0)
{
  $response = <SNMPINFO>;
  $stop = 1 if ($response !~ /filesystem/i);
}
close SNMPINFO;

if (exists $opt{N}) # netmrg
{
  my $outp = (split /\s+/, $response)[-3];
  print $outp, "\n";
  exit 0;
}
else # nagios
{
  open SNMPINFO, $name_cmd or die "Cannot pipe to get name of monitored service\n";
  my $name = (split /\s/, <SNMPINFO>)[-1];
  my $outp = (split /\s/, $response)[-2];
  $outp =~ s/\%//g;
  print "[ $name: $outp% ]\n";
  exit 2 if ($outp >= $opt{C}); # critical
  exit 1 if ($outp >= $opt{W}); # warning
  exit 0 if ($outp < $opt{W} or $outp < $opt{C}); # normal
}

exit 255;

sub usage
{
  return <<EOF;
 usage: $0 -H hostname -c SNMP_COMMUNITY -I index [-N] [-W warn] [-C crit]

	-N - netmrg style, no -W or -C needed
EOF
}
