#!/usr/bin/env bash
#date >>/tmp/xxcc
#id >>/tmp/xxcc

TMPFILE="/home/mnt/nagios-output/out"
TMPFILE2="/tmp/out-named-checkconf"

rm -f $TMPFILE2 2>/dev/null 1>/dev/null

EL="0"

#error level
#echo "<pre>" >> $TMPFILE2 
if [ -f "$TMPFILE.err" ]; then
	EL="2"
	cat $TMPFILE.err >> $TMPFILE2
	cat $TMPFILE >> $TMPFILE2
	else
	LINES="`cat $TMPFILE |wc -l`"
#        echo $TMPFILE $LINES $TMPFILE2 >> /tmp/xxcc
	if [ $LINES -eq 0 ]; then
            #echo -OK- >> /tmp/xxcc
	    EL="0"
	    echo "OK" >> $TMPFILE2
	    else
            #echo -WARN- >> /tmp/xxcc
	    EL="1"
	    echo "WARNING:" >> $TMPFILE2
	    cat $TMPFILE >> $TMPFILE2
	    fi
	fi;

cat $TMPFILE2 | sed -E 's/(.*)/\1<br>/' | tr '\n' ' '

rm -f $TMPFILE2 2>/dev/null 1>/dev/null
exit $EL
