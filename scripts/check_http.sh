#!/bin/sh

while getopts I:H:u:p:w:c:t:f:m: o
do case "$o" in
    I) IP="$OPTARG";;
    H) HOST="$OPTARG";;
    u) URL="$OPTARG";;
    p) PORT="$OPTARG";;
    w) WARN="$OPTARG";;
    c) CRIT="$OPTARG";;
    t) TIMEOUT="$OPTARG";;
    f) FOLLOW="$OPTARG";;
    m) SIZE="$OPTARG";;
    \?)  echo "Usage: $0 -I <IP> -H <HOST> -u <URL> -w <WARNING TIME> -c <CRITICAL TIME> -t <TIMEOUT> -f <follow> -m <SIZE>" && exit 1;;
esac
done

#echo $IP $HOST $URL $PORT $WARN $CRIT $TIMEOUT $FOLLOW $SIZE
RES=`curl -s -o /dev/null -H "Host: $HOST" -L "http://$IP:$PORT$URL" --connect-timeout $TIMEOUT -w '%{http_code} %{size_download} %{time_total}'` || echo "CRITICAL: Can't connect to http://$HOST$URL within $TIMEOUT seconds"
rcode=`echo $RES | cut -d " " -f1`
rsize=`echo $RES | cut -d " " -f2`
rtime=`echo $RES | cut -d " " -f3 | tr -d '.' | sed 's/^[0]*//g'`

if [ $rcode -eq 200 -a $rtime -lt $WARN -a $rsize -gt 256 ]; then
	echo "HTTP OK: http://$HOST$URL - HTTP $rcode - $rsize bytes in $rtime milliseconds"
	exit 0	
elif [ $rcode -le 600 -a $rcode -ge 400 ]; then #hahaha, 400-600
	echo "CRITICAL: http://$HOST$URL - HTTP $rcode in $rtime milliseconds"
	exit 2
elif [ $rcode -eq 204 ]; then
	echo "CRITICAL: http://$HOST$URL - HTTP 204 No Content in $rtime milliseconds"
	exit 2
fi

if [ $rsize -le 256 ]; then
	echo "CRITICAL: http://$HOST$URL too small: $rsize bytes"
	exit 2
fi

if [ $rtime -gt $CRIT ]; then
	echo "CRITICAL: http://$HOST$URL too slow: $rsize bytes in $rtime milliseconds"
	exit 2
elif [ $rtime -gt $WARN ]; then
	echo "WARNING: http://$HOST$URL too slow: $rsize bytes in $rtime milliseconds"
	exit 1
fi

echo "CRITICAL: unknown error on http://$HOST$URL"
exit 2
