#!/usr/bin/env perl
package cluster;

sub gen_meth {
  foreach my $sub (sort keys %{$main}){
   (my $rsub = $sub) =~ s/^_//;
   *$rsub = sub {
     my $self = shift;
     my $arg = shift;
     $self->{$sub} = $arg if defined $arg;
     return $self->{$sub};
   };
  }
}

sub new {
  my $class = shift;
  my $self = {
    _host => undef,
    _cluster => undef,
    _disks => undef,
    _disk_status => 0,
    _status => undef
  };
  $main = $self;
  gen_meth();
  return bless $self, $class;
}

sub diskinfo {
  my $self = shift;
  my $arg = shift;
  push @{ $self->{_disks} }, $arg if defined $arg;
  return @{ $self->{_disks} };
}

1;

package main;
use warnings;
use strict;

use Getopt::Std;
my %opts;
# W - warning state, C - critical state, n - cluster, c - community
getopt('c:n:W:C:', \%opts);

my @nodes = ();

die "check options\n" if (!exists $opts{c} or !exists $opts{n});
die "bogus states: $opts{W} - warn, $opts{C} - critical\n"
  if ((exists $opts{C} and $opts{C}!~/\:\d+\:/) or
      (exists $opts{W} and $opts{W}!~/\:\d+\:/));
# defaults for alerts:
# 2:1:95 - means 2 machines with 1 disk on each, available space below 95% (free)
# 1:1:95 - means 1 machine with 1 disk, available space below 95% (free)
!defined $opts{C} and $opts{C} = "1:1:95"; # 1 machine with 1 disk from cluster
!defined $opts{W} and $opts{W} = "2:1:95"; # 2 machines with 1 disk from cluster
print "W:$opts{W},C:$opts{C}";

# see no good for this. FIXME
my @crit_state = split /:/, $opts{C};
my @warn_state = split /:/, $opts{W};

my @cluster_hosts = sort @ARGV;

for (;;) {

  last if $#cluster_hosts < 0;
  my $n = new cluster();
  my $host = shift @cluster_hosts;
  my $shortname = ($host =~ /^([^.]+)/)[0];
  $n->host($shortname);
  
  my $cmd = '/usr/bin/host -t txt ' . $host . '|';
  open TXT, $cmd or next;
   for(;;) {
     $_ = <TXT>;
     last if !defined $_;
     chomp;
     my $cl = (/\"(\w+[^"])/)[0];
     $n->cluster($cl) and last if defined $cl;
     $n->cluster('unkn');
   }
  close TXT;

  # skip other cluster machine. depends on TXT record!!!
  print " " . $n->host . " skipped" and next if ($n->cluster eq 'unkn' or $n->cluster ne $opts{n}); 
# skip if not needed cluster in DNS->TXT
  
  $cmd = '/usr/local/bin/snmpwalk -v1 -c ' . $opts{c} . ' ' . $host . ' .1.3.6.1.2.1.25.2.3.1 |';
  open SNMPINFO, $cmd or next;
  my %disk_obj;
   for(;;) {
     $_ = <SNMPINFO>;
     last if !defined $_;
     chomp;

     if (/Descr/) { # getting labels
       my ( $diskindex, $disklabel ) = (/Descr\.(\d{1,2}).+\/(disk\d+)$/);
       $disk_obj{$diskindex} = $disklabel if (defined $disklabel and defined $diskindex);
       undef $diskindex; undef $disklabel;
     }

     if (/StorageSize/) { # getting total sizes
       my ($sndx, $size) = (/Size\.(\d{1,2}).+\:\s+?(\d+)$/);
       if (exists $disk_obj{$sndx}) {
         $disk_obj{$sndx} .= " ".$size;
       }
       undef $sndx; undef $size;
     }

     if (/StorageUsed/) { # getting used sizes and calculating
      my ($sndx, $size) = (/Used\.(\d{1,2}).+\:\s+?(\d+)$/);
      my $prcnt = 100;
      if (exists $disk_obj{$sndx} and defined $size and $sndx ne '') {
        my ($disklabel, $total) = split / /, $disk_obj{$sndx};
        $prcnt = int( (100 * $size) / ($total * 0.95) ) if $total != 0;
        # see disks method
        $n->diskinfo($disklabel . ' ' . $prcnt);
        undef $prcnt; undef $disklabel;
      }
     }
   }
  close SNMPINFO;

  # calculate node status
  my $disk_cnt = 0; my @disk_cnt_t = $n->diskinfo;
  foreach my $line ( $n->diskinfo ) {
    my ( $label, $av ) = split / /, $line;
    undef $line;
    if ( $av <=$warn_state[2] or $av < $crit_state[2] ) {
      $disk_cnt++;
    }
    $n->status($disk_cnt);
  }

  push @nodes, $n;

}

my ( $d_count, $m_count, $exi_status ) = ( 0, 0, 0 );

foreach my $node ( @nodes ) {
 print ' [' . $node->host . ': ' . $node->status . ' rmn]';

  if ( $node->status >= $warn_state[1] ) {
    $m_count++; $d_count += $node->status;
  }

}

if ( $m_count >= $warn_state[0] and $d_count > ($warn_state[1] * $warn_state[0]) ) {
  $exi_status = 0;
} elsif ( $m_count == $warn_state[0] ) {
  $exi_status = 1;
} else {
  $exi_status = 2;
}

print "\n"; # all print are now done

exit $exi_status;
