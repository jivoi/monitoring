#!/usr/local/bin/bash

HOSTADDRESS=$1

if /usr/local/bin/mysql -h $HOSTADDRESS -u monitoring -pP@ssw0rd -Be 'select * from dummy' monitoring > /dev/null 2>&1; then
	
	`/usr/local/bin/mysql -h example.ru -u monitoring -pP@ssw0rd --skip-column-names -Be "

		show variables like 'max_connections';
		show status like 'Threads_connected';

		" monitoring | awk '{print "export mysql_"$1"="$2}'` 

	set|grep '^mysql_'
	if (( $mysql_max_connections - $mysql_Threads_connected < 5 )); then
		echo "Too many connections: $mysql_Threads_connected of $mysql_max_connections"
		exit 1
	fi
	
	echo OK
	exit 0
else
	echo NOT OK: Can not conect
	exit 2
fi

