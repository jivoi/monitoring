#! /bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

DATE=`date +%H`

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
STATE_DEPENDENT=4
warn=30
crit=60
null="NULL"
port=3306
usage1="Usage: $0 -H <host> -u user -p password [-w <warn>] [-c <crit>] [-P <port>]"
usage2="<warn> is lag time, in seconds, to warn at.  Default is 30."
usage3="<crit> is lag time, in seconds, to be critical at.  Default is 60."

exitstatus=$STATE_WARNING #default
sbmstatus=0



if  [ $DATE -lt 16 ]; then
echo "before 16:00 don't monitoring"
exit $STATE_OK;
fi


if [ -z "$1" ] ; then
            echo $usage1;
            echo
            echo $usage2;
            echo $usage3;
            exit $STATE_UNKNOWN
fi

while test -n "$1"; do
    case "$1" in
        -P)
            port=$2
            shift
            ;;
        -c)
            crit=$2
            shift
            ;;
        -w)
            warn=$2
            shift
            ;;
        -u)
            user=$2
            shift
            ;;
        -p)
            pass=$2
            shift
            ;;
        -h)
            echo $usage1;
	    echo 
            echo $usage2;
            echo $usage3;
            exit $STATE_UNKNOWN
	    ;;
	-H)
            host=$2
            shift
            ;;
        *)
            echo "Unknown argument: $1"
            echo $usage1;
	    echo 
            echo $usage2;
            echo $usage3;
            exit $STATE_UNKNOWN
            ;;
    esac
    shift
done

seconds=`mysql -u $user -p$pass -h $host -P $port -e 'show slave status\G' | grep Seconds_Behind_Master | cut -f2 -d:`
lasterror=`mysql -u $user -p$pass -h $host -P $port -e 'show slave status\G' | grep Last_Error`
echo $seconds | egrep '[0-9]+' >/dev/null 2>&1|| sbmstatus=1

if [ "$sbmstatus" != "0" ] ; then
  echo $lasterror
  echo "Can't get Seconds_Behind_Master"
  exit $STATE_CRITICAL
fi

echo $host is $seconds seconds behind

# on the number line, we need to test 6 cases:
# 0-----w-----c----->
# 0, 0<lag<w, w, w<lag<c, c, c<lag
# which we simplify to 
# lag>=c, w<=lag<c, 0<=lag<warn

# if null, critical
if [ $seconds = $null ]; then 
exit $STATE_CRITICAL;
fi

#w<=lag<c
if [ $seconds -lt $crit ]; then 
if [ $seconds -ge $warn ]; then 
exit $STATE_WARNING;
fi
fi

if [ $seconds -ge $crit ]; then 
exit $STATE_CRITICAL;
fi

# 0<=lag<warn
if [ $seconds -lt $warn ]; then 
exit $STATE_OK;
fi


