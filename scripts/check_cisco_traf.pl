#!/usr/bin/perl

my $WARN=950;
my $CRIT=980;

my $ifnumber, $ifname, $inoctet, $outoctet;

my @ints = `snmpwalk -v2c -c SNMPEXAMPLE @ARGV IF-MIB::ifDescr | grep -v Port-channel`;
my @inoctets = `snmpwalk -v2c -c SNMPEXAMPLE @ARGV IF-MIB::ifHCInOctets`;
my @outoctets = `snmpwalk -v2c -c SNMPEXAMPLE @ARGV IF-MIB::ifHCOutOctets`;

my %inttable;
my %inoctetstable;
my %outoctetstable;
my %inoctetstable_5s;
my %outoctetstable_5s;

my $STATE_CRITICAL=0;
my $STATE_WARNING=0;

foreach $int(@ints) {
	($ifnumber, $ifname) = $int =~ /^IF-MIB::ifDescr.([0-9]+) = STRING: (.*)/;
	$inttable{$ifnumber} = $ifname;
}
foreach $int(@inoctets) {
	($ifnumber, $inoctet) = $int =~ /^IF-MIB::ifHCInOctets.([0-9]+) = Counter64: (.*)/;
	$inoctetstable{$ifnumber} = $inoctet;
}
foreach $int(@outoctets) {
        ($ifnumber, $outoctet) = $int =~ /^IF-MIB::ifHCOutOctets.([0-9]+) = Counter64: (.*)/;
        $outoctetstable{$ifnumber} = $outoctet;
}

sleep(5);
@inoctets = `snmpwalk -v2c -c SNMPEXAMPLE @ARGV IF-MIB::ifHCInOctets`;
@outoctets = `snmpwalk -v2c -c SNMPEXAMPLE @ARGV IF-MIB::ifHCOutOctets`;

foreach $int(@inoctets) {
        ($ifnumber, $inoctet) = $int =~ /^IF-MIB::ifHCInOctets.([0-9]+) = Counter64: (.*)/;
        $inoctetstable_5s{$ifnumber} = $inoctet;
}
foreach $int(@outoctets) {
        ($ifnumber, $outoctet) = $int =~ /^IF-MIB::ifHCOutOctets.([0-9]+) = Counter64: (.*)/;
        $outoctetstable_5s{$ifnumber} = $outoctet;
}

foreach $ifnumber (sort keys %inttable){
	my $in_mbits=($inoctetstable_5s{$ifnumber}-$inoctetstable{$ifnumber})/5*8/1048576;
	my $out_mbits=($outoctetstable_5s{$ifnumber}-$outoctetstable{$ifnumber})/5*8/1048576;
	#print $inttable{$ifnumber}, " ", ($inoctetstable_5s{$ifnumber}-$inoctetstable{$ifnumber})/5*8/1048576, "Mbit/s ", ($outoctetstable_5s{$ifnumber}-$outoctetstable{$ifnumber})/5*8/1048576, "Mbit/s\n";
	if(($in_mbits>$CRIT) || ($out_mbits>$CRIT)) {
		printf("%s: %d Mbit/s in, %d Mbit/s out. ", $inttable{$ifnumber}, $in_mbits, $out_mbits);
		$STATE_CRITICAL=1;
	}
        if(($in_mbits>$WARN) || ($out_mbits>$WARN)) {
                printf("%s: %d Mbit/s in, %d Mbit/s out. ", $inttable{$ifnumber}, $in_mbits, $out_mbits);
                $STATE_WARNING=1;
        }

}
if(($STATE_CRITICAL == 0) && ($STATE_WARNING == 0)) {
	print "All interfaces has less than $WARN Mbit/s input and output.";
}
print "\n";
if ($STATE_CRITICAL) {
	exit 2;
}
if ($STATE_WARNING) {
        exit 1;
}
exit 0;
