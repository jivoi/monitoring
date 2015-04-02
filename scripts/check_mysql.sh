#!/bin/sh

usage() {
cat << EOF
Usage: check_mysql.sh [-d database] [-H host] [-P port] [-s socket]
       [-u user] [-p password] [-S]

 -H, --hostname=ADDRESS
    Host name, IP Address, or unix socket (must be an absolute path)
 -P, --port=INTEGER
    Port number (default: 3306)
 -u, --username=STRING
    Connect using the indicated username
 -p, --password=STRING
    Use the indicated password to authenticate the connection
 -S, --check-slave
    Check if the slave thread is running properly.
 -w, --warning
    Exit with WARNING status if slave server is more than INTEGER seconds
    behind master
 -c, --critical
    Exit with CRITICAL status if slave server is more then INTEGER seconds
    behind master
EOF
}

HOSTNAME="localhost"
PORT="3306"
USER="monitoring"
PASS="P@ssw0rd"
CHECK_SLAVE="0"
SLAVE_WARN="300"
SLAVE_CRIT="600"
SBM="0"
while [ $# -gt 0 ]
do
	case $1 in
	-H) HOSTNAME="$2"; shift;;
	-P) PORT="$2"; shift;;
	-u) USER="$2"; shift;;
	-p) PASS="$2"; shift;;
	-S) CHECK_SLAVE=1; ;;
	-w) SLAVE_WARN="$2"; shift;;	
	-c) SLAVE_CRIT="$2"; shift;;
	*) ;;
	esac
	shift
done

MYSQL_COMMAND="mysql -h $HOSTNAME -P $PORT -u $USER -p$PASS"

$MYSQL_COMMAND -e "" 2>&1 || exit 2

LPC=`$MYSQL_COMMAND -e "show full processlist" | grep -v Time | grep -v Sleep | grep -v 'system user' | awk '{if($6>60) print $6}' | wc -l | tr -d " "`
if [ $LPC -gt 25 ]; then
	echo "Too many slow running queries: " $LPC
	exit 2
fi
if [ $CHECK_SLAVE -ne 0 ]; then
	$MYSQL_COMMAND -e "show slave status\G" >/dev/null || exit 2
	SBM=`$MYSQL_COMMAND -e "show slave status\G" | grep -i Seconds_Behind_Master | awk '{print $NF}'`
	if [ $SBM -gt $SLAVE_CRIT ]; then
		echo "CRITICAL: $HOSTNAME is $SBM seconds behind" 
		exit 2
	elif [ $SBM -gt $SLAVE_WARN ]; then
		echo "WARNING: $HOSTNAME is $SBM seconds behind"
		exit 1
	else
		echo "OK: $HOSTNAME is $SBM seconds behind"
		exit 0
	fi
fi
echo "OK: MySQL status is good"
