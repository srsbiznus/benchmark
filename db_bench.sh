#!/bin/bash

yum install epel-release -y
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
sysbench --test=oltp --db-driver=mysql --oltp-table-size=40000000 --mysql-host=$hostname --mysql-db=$database --mysql-user=$username --mysql-password=$password prepare 
