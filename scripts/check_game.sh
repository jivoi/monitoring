#!/usr/local/bin/bash
PATH=/bin:/sbin:/usr/bin:/usr/sbin:/usr/local/bin:/usr/local/sbin
STATE_OK=0
STATE_WARNING=1
STATE_CRITICAL=2
STATE_UNKNOWN=3
#STATE_DEPENDENT=4
#warn=30
#crit=60
#null="NULL"
#port=3306

usage="Usage: $0 <host> [port]"

if [ $# -gt 2 ]; then
	   echo $usage;
   	   exit 1
fi

if [ -z "$1" ] ; then
            echo $usage;
	    exit 1
fi

HOSTADDRESS=$1
PORT=$2

if [ -z "$2" ] ; then
    PORT=28513;
fi

bytes="13 00 09 01 00 00 00 00 00 00 00"
getbytes=$(nc $HOSTADDRESS $PORT << EOF | hexdump -C | awk '{print $2,$3,$4,$13,$14,$15,$16,$17,""}' | tr -d "\n" |  awk '{print $1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11}')
#echo ">$getbytes<"
#echo ">$bytes<"

if [ "${bytes}" == "${getbytes}" ]
then
  echo "OK"
  exit $STATE_OK
else 
  echo "CRITICAL"
  exit $STATE_CRITICAL
fi
