#!/bin/bash
wget https://www.percona.com/redir/downloads/percona-release/redhat/latest/percona-release-0.1-4.noarch.rpm
rpm -Uvh percona-release-0.1-4.noarch.rpm
yum install wget sysbench mysql mariadb-server -y
service mariadb start

hostname=$1
database=$2
username=$3
password=$4

#Run the commands below 
mysql -e "CREATE DATABASE $database;"  
mysql -e "CREATE USER '$username'@'$hostname' IDENTIFIED BY '$password';"  
mysql -e "GRANT ALL PRIVILEGES ON *.* TO '$database'@'$hostname' IDENTIFIED  BY '$password';" 
sysbench --test=/usr/share/doc/sysbench/tests/db/oltp.lua --mysql-host=$hostname --mysql-port=3306 --mysql-user=$username --mysql-password=$password --mysql-db=$database --mysql-table-engine=innodb --oltp-table-size=25000 --oltp-tables-count=250 --db-driver=mysql prepare

sysbench --test=tests/db/oltp.lua --mysql-host=$hostname --oltp-tables-count=250 --mysql-user=$username --mysql-password=$password --mysql-port=3306 --db-driver=mysql --oltp-tablesize=25000 --mysql-db=$database --max-requests=0 --oltp-simple-ranges=0 --oltp-distinct-ranges=0 --oltp-sum-ranges=0 --oltp-order-ranges=0 --maxtime=600 --oltp-read-only=on --num-threads=500 run
