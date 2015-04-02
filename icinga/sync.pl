#!/usr/bin/env perl
use lib "/www/icinga/htdocs";
use strict;
use Mysql;
use sync::main;
use sync::subs;
$|=1;

my $action = shift;
my @hosts = @ARGV;
die usage() unless (($action eq 'fix' or $action eq 'add' or $action eq 'del') and scalar @hosts > 0);

my @configs = get_confs();
#my @configs = "/usr/local/etc/nagios/hosts_and_services.cfg";
$sync::subs::action = $action; # bebebe uncompat!

foreach my $config (@configs){
  open(CONFIG, $base_dir."/".$config) or die "cannot open $config: $!\n";
  #open(CONFIG, $config);
  my (%hosts, %object);
  my ($nparsed, $nparserr, $nlines) = (0,0,0);
  my ($seq);

  my $cfg_parsed = 0;

  while (<CONFIG>) {
	chomp;
	$nlines++;
	next if (/^\s*$/ or /^\s*#/);
	if ($seq = /^\s*define\s*(\S+)[\s{]/ .. /}/) {
		$object{type} = lc $1	if /^\s*define\s*(\S+)[\s{]/;
		$object{hostname} = $1	if (/^\s*host_name\s+(.*)\s*$/);
		$object{alias} = $1	if (/^\s*alias\s+(.*)\s*$/);
		$object{address} = $1	if (/^\s*address\s+(.*)\s*$/);
		$object{register} = $1	if (/^\s*register\s+(.*)\s*$/);
		if ($seq =~ /E0/) {
			if ($object{type} eq 'host' and
			    $object{hostname} and $object{alias} and $object{address} and
			    (not defined $object{register} or $object{register} > 0)) {
#				print "+ parsed: $object{hostname}, $object{alias}, $object{address}\n";
                                if ((@hosts == 0) or grep(/^$object{hostname}$/i, @hosts)) {
					print "+++++++++++++++++++++++++++++++++\n";
					$cfg_parsed++;
					if ($action eq 'add') {
	                                        add(\%object);
					}
					elsif ($action eq 'del') {
						remove(\%object);
					}
					elsif ($action eq 'fix') {
						my $retval = fix(\%object);
						if ($retval == -10) {
							print "\a <- $object{hostname} is not defined in DB\n\t\aPlease use `add' option\n\n";
						} else {
							$nparserr++;
						}
					}
				}
                                $object{address} = $object{alias} = $object{hostname} = $object{register} = $object{type} = undef;
                                $nparsed++;
				} else {
					if ($object{type} and $object{type} ne 'host') {
#						print ". definition of $object{type} skipped near $nlines.\n";
						} elsif (defined $object{register} and $object{register} == 0) {
							print ". template definition skipped near $nlines\n";
						} else {
							print "- $object{hostname} is defined incorrectly.\n" if ($object{hostname});
							print "- parser error near $nlines\n";
							$nparserr++;
							}
					}
			$object{address} = $object{alias} = $object{hostname} = $object{register} = $object{type} = undef;
			}
		} else {
			print "- parser error near line $nlines in file '$config'\n";
			$nparserr++;
			}
	}

print ". $config: $nlines lines read, $nparsed host definitions parsed ($nparserr errors).\n\n" if (defined($cfg_parsed) && $cfg_parsed > 0);

close CONFIG;
}
