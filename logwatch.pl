#!/usr/bin/perl

# perl program to watch my javAPRSrvr log port
# and pass through data while expanding the timestamp
# into a nice human-readable form.
#
# Chris Howard  w0ep   July 2005
#

use IO::Socket;
use Getopt::Std;

@DAYS = ('Sun', 'Mon', 'Tue', 'Wed','Thu','Fri','Sat');
@MONTHS = ('JAN', 'FEB', 'MAR', 'APR','MAY','JUN','JUL',
	'AUG','SEP','OCT','NOV','DEC');

getopts('h:p:',\%opts);

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

printf "making connection to host $host  port $port\n";

my $sock = new IO::Socket::INET (
                                  PeerAddr => $host,
                                  PeerPort => $port,
                                  Proto => 'tcp',
                                 );
die "Could not create socket: $!\n" unless $sock;

printf "connected to host $host port $port\n";

while ( $line = $sock->getline() )
{
	$line  =~ m/\[([<>][RI]:)(\d+)\](.*)/;

	$one = $1;
	$two = $2;
	$three = $3;
	$time =  int($two / 1000);
	$milisec = $two - ($time * 1000);

	($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst)
		= localtime($time);

	$stamp = sprintf "%2.2d:%2.2d:%2.2d.%3.3d %s %02.2d-%3.3s-%04.4d",
		$hour,$min,$sec, $milisec,
		$DAYS[$wday],$mday, $MONTHS[$mon], $year+1900;
	printf '['.$one.$stamp.']'.$three."\n";
}
close($sock);

exit(0);
    
sub usage
{
	printf STDERR "usage: $0 -h host -p port\n";
	exit -1;
}
