#! /bin/sh
### BEGIN INIT INFO
# Provides:          javAPRSSrvr
# Required-Start:    $remote_fs $syslog ntp
# Required-Stop:     $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initscript for javAPRSSrvr
# Description:       javAPRSSrvr is a server for APRS
### END INIT INFO

# Author: Owen Duffy
#

# PATH should only include /usr/* if it runs after the mountnfs.sh script
PATH=/sbin:/usr/sbin:/bin:/usr/bin
NAME="javAPRSSrvr"
DESC="javAPRSSrvr"
SCRIPTNAME=/etc/init.d/$NAME
APPDIR=/home/aprs/JAS
DAEMON=$APPDIR/$NAME
DAEMON_ARGS="-jar $NAME.jar"
PIDFILE=/var/run/$NAME.pid
USER=aprs
PORT=ttyUSB0
PORTLOCKFILE=/var/lock/LCK..$PORT

# to install, run these commands substituting values from above to setup the daemon and serial port access
# ln -s /etc/alternatives/java <DAEMON>
# adduser <USER> dialout
# update-rc.d javAPRSSrvr.sh defaults

# Exit if the package is not installed
[ -x "$DAEMON" ] || exit 0

# Read configuration variable file if it is present
[ -r /etc/default/$NAME ] && . /etc/default/$NAME

# Load the VERBOSE setting and other rcS variables
. /lib/init/vars.sh

VERBOSE=yes
# Define LSB log_* functions.
# Depend on lsb-base (>= 3.2-14) to ensure that this file is present
# and status_of_proc is working.
. /lib/lsb/init-functions

#
# Function that starts the daemon/service
#
do_start()
{
	# Return
	#   0 if daemon has been started
	#   1 if daemon was already running
	#   2 if daemon could not be started
	#check that if the port lockfile exists, that it is owned by user
	[ -f $PORTLOCKFILE ] && [ $(stat -c %U $PORTLOCKFILE) != $USER ] && return 2
	##start-stop-daemon --start --pidfile $PIDFILE -b -d $APPDIR --exec $DAEMON --test 
	start-stop-daemon --start --quiet --pidfile $PIDFILE -b -d $APPDIR -c $USER --exec $DAEMON --test > /dev/null \
		|| return 1
	#rm -f $APPDIR/err.log.* 
	#initialise TNC
	if [ -f $APPDIR/tnc-init ]; then
 		$APPDIR/tnc-init /dev/$PORT || return 3
	fi
	start-stop-daemon --start --quiet --pidfile $PIDFILE -m -b -d $APPDIR -c $USER --exec $DAEMON -- \
		$DAEMON_ARGS \
		|| return 2
	# Add code here, if necessary, that waits for the process to be ready
	# to handle requests from services started subsequently which depend
	# on this one.  As a last resort, sleep for some time.
}

#
# Function that stops the daemon/service
#
do_stop()
{
	# Return
	#   0 if daemon has been stopped
	#   1 if daemon was already stopped
	#   2 if daemon could not be stopped
	#   other if a failure occurred
	start-stop-daemon --stop -v --retry=TERM/30/KILL/5 --pidfile $PIDFILE --name $NAME
	RETVAL="$?"
	[ "$RETVAL" = 2 ] && return 2
	# Wait for children to finish too if this is a daemon that forks
	# and if the daemon is only ever run from this initscript.
	# If the above conditions are not satisfied then add some other code
	# that waits for the process to drop all resources that could be
	# needed by services started subsequently.  A last resort is to
	# sleep for some time.
	start-stop-daemon --stop --quiet --oknodo --retry=0/30/KILL/5 --exec $DAEMON
	[ "$?" = 2 ] && return 2
	# Many daemons don't delete their pidfiles when they exit.
	rm -f $PIDFILE
	# daemon doesn't delete port lock file
	rm -f $PORTLOCKFILE
	#reset TNC
	if [ -f $APPDIR/tnc-init ]; then
		$APPDIR/tnc-rst /dev/$PORT || return 3
	fi
	return "$RETVAL"
}

#
# Function that sends a SIGHUP to the daemon/service
#
do_reload() {
	#
	# If the daemon can reload its configuration without
	# restarting (for example, when it is sent a SIGHUP),
	# then implement that here.
	#
	start-stop-daemon --stop --signal 1 --quiet --pidfile $PIDFILE --name $NAME
	return 0
}

case "$1" in
  start)
	[ "$VERBOSE" != no ] && log_daemon_msg "Starting $DESC" "$NAME"
	do_start
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  stop)
	[ "$VERBOSE" != no ] && log_daemon_msg "Stopping $DESC" "$NAME"
	do_stop
	case "$?" in
		0|1) [ "$VERBOSE" != no ] && log_end_msg 0 ;;
		2) [ "$VERBOSE" != no ] && log_end_msg 1 ;;
	esac
	;;
  status)
	status_of_proc "$DAEMON" "$NAME" && exit 0 || exit $?
	;;
  #reload|force-reload)
	#
	# If do_reload() is not implemented then leave this commented out
	# and leave 'force-reload' as an alias for 'restart'.
	#
	#log_daemon_msg "Reloading $DESC" "$NAME"
	#do_reload
	#log_end_msg $?
	#;;
  restart|force-reload)
	#
	# If the "reload" option is implemented then remove the
	# 'force-reload' alias
	#
	log_daemon_msg "Restarting $DESC" "$NAME"
	do_stop
	case "$?" in
	  0|1)
		sleep 3
		do_start
		case "$?" in
			0) log_end_msg 0 ;;
			1) log_end_msg 1 ;; # Old process is still running
			*) log_end_msg 1 ;; # Failed to start
		esac
		;;
	  *)
		# Failed to stop
		log_end_msg 1
		;;
	esac
	;;
  *)
	#echo "Usage: $SCRIPTNAME {start|stop|restart|reload|force-reload}" >&2
	echo "Usage: $SCRIPTNAME {start|stop|status|restart|force-reload}" >&2
	exit 3
	;;
esac

:
