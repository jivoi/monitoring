#!/usr/bin/env bash

# v. 0.1

#FILE="/tmp/check.traf"
FILE="/tmp/check_traf.$(whoami)"

# command-line arguments
if [[ $# -lt 2 ]]; then
    echo "usage: $0 <server> <interface> <warn> <crit>"
    exit 1
fi

SERVER=$1
IF=$2
WARN=$3
CRIT=$4

# get available interfaces
AVAILABLE_IF=$(snmpwalk -v2c -c SNMPEXAMPLE -Oqv $SERVER ifDescr)

# check if out is existed
id=0
for i in $AVAILABLE_IF; do
    id=$((id+1))

    if [[ $IF == $i ]]; then
	# get old values for timestamp and traffic from file
	OLD_TIME=$(sed -n "/^"$SERVER" "$IF"/ p" $FILE | awk '{print $3}')
	OLD_OCTET=$(sed -n "/^"$SERVER" "$IF"/ p" $FILE | awk '{print $4}')
	OCTET=$(snmpwalk -v2c -c SNMPEXAMPLE -Oqv $SERVER ifHCOutOctets.$id)

    if [[ $? != 0 ]]; then
        echo "UNKNOWN: snmpd doesn't answer"
        exit 3
    fi

	TIME=$(date +%s)

	if [[ -z $OLD_OCTET ]]; then
	    echo "$SERVER $IF $TIME $OCTET" >> $FILE
	    echo "checking"
        exit 0
	fi

	# replace old values to new
    sed -i -e "/^"$SERVER" "$IF"/ s/^.*$/"$SERVER" "$IF" "$TIME" "$OCTET"/" $FILE
    DELTA_TIME=$((TIME-OLD_TIME))
	DELTA_OCTET=$((OCTET-OLD_OCTET))

	if [[ $DELTA_OCTET -eq 0 ]]; then
	    echo "CRITICAL - $i on $SERVER: $SPEED mbit/s (fast)"
	    exit 2
	fi
		
	SPEED=$(((DELTA_OCTET)*8/(DELTA_TIME*1024**2)))

	if [[ $SPEED -le $CRIT ]]; then
	    echo "CRITICAL: $IF: $SPEED mbit/s"
	    exit 2
	elif [[ $SPEED -le $WARN ]]; then
	    echo "WARNING: $IF $SPEED mbit/s"
	    exit 1
	else
	    echo "OK: $IF $SPEED mbit/s"
	    exit 0
	fi
    fi

done

echo "CRITICAL: $IF not found!"
exit 2
