#! /bin/sh

PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin

STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
warn=30
crit=60
null="NULL"
port=3306
usage1="Usage: $0 -H <host> -u user -p password [-w <warn>] [-c <crit>] [-P <port>]"
usage2="<warn> is lag time, in seconds, to warn at.  Default is 30."
usage3="<crit> is lag time, in seconds, to be critical at.  Default is 60."

exitstatus=$STATE_WARNING #default
sbmstatus=0

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


nprocs=`mysql -u $user -p$pass -h $host -P $port -e 'show full processlist' | grep -v Sleep | wc -l`

echo $host has $nprocs mysql threads running

# on the number line, we need to test 6 cases:
# 0-----w-----c----->
# 0, 0<lag<w, w, w<lag<c, c, c<lag
# which we simplify to 
# lag>=c, w<=lag<c, 0<=lag<warn

# if null, critical
if [ $nprocs = $null ]; then 
exit $STATE_CRITICAL;
fi

#w<=lag<c
if [ $nprocs -lt $crit ]; then 
if [ $nprocs -ge $warn ]; then 
exit $STATE_WARNING;
fi
fi

if [ $nprocs -ge $crit ]; then 
exit $STATE_CRITICAL;
fi

# 0<=lag<warn
if [ $nprocs -lt $warn ]; then 
exit $STATE_OK;
fi
