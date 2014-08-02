#!/usr/bin/perl

# perl program to watch my javAPRSrvr log port
# and pass through data while expanding the timestamp
# into a nice human-readable form.
#
# Chris Howard  w0ep   July 2005
#
# Fixes for javAPRSSrvr 4.1
# Owen Duffy  VK2OMD  Aug 2014
#

use IO::Socket;
use Getopt::Std;

getopts('ah:l:p:',\%opts);

if( defined($opts{'h'}) )
{
	$host = $opts{'h'};
}
else { usage(); }

if( defined($opts{'p'}) )
{
	$port = $opts{'p'};
}
else { usage(); }


if( defined($opts{'l'}) )
{
	$outfile = $opts{'l'};
  if( defined($opts{'a'}) ){
    open $OUT5,">>",$outfile or die "cannot open > $outfile: $!";
  }
  else{
  open $OUT5,">",$outfile or die "cannot open > $outfile: $!";
  }
  autoflush $OUT5 1;
}

#so that it works properly in pipelines
#$|=1;
autoflush STDOUT 1;

printf "making connection to host $host  port $port\n";
printf(OUT "making connection to host $host  port $port\n");

my $sock = new IO::Socket::INET (
                                  PeerAddr => $host,
                                  PeerPort => $port,
                                  Proto => 'tcp',
                                 );
die "Could not create socket: $!\n" unless $sock;

printf "connected to host $host port $port\n";

while ( $line = $sock->getline() )
{
	$line  =~ m/([<>])\t(\d+)\t(.*)/;
	$one = $1;
	$two = $2;
	$three = $3;
	$time =  int($two / 1000);
	$milisec = $two - ($time * 1000);

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
		= gmtime($time);

	$stamp = sprintf "%04.4d%02.2d%02.2d %2.2d:%2.2d:%2.2d.%3.3d",
		$year+1900,$mon,$mday,$hour,$min,$sec,$milisec;
	printf $one.$stamp."\t".$three."\n";
  if($OUT5){
	  printf($OUT5 $one.$stamp."\t".$three."\n");
    }
}
close($sock);
exit(0);
    
sub usage
{
	printf STDERR "usage: $0 -h host -p port [-l outputfile -a]\n";
	exit -1;
}
