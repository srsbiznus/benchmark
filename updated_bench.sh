#!/bin/bash

#If using **Debian / Ubuntu**, uncomment below to install sysbench and fio
#curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.deb.sh | sudo bash
#sudo apt -y install sysbench fio

#If running **CentOS 7 with/without cpanel**, uncomment below to install sysbench and fio
#yum install epel-release -y
#curl -s https://packagecloud.io/install/repositories/akopytov/sysbench/script.rpm.sh | sudo bash
#yum install fio sysbench -y


#Prepare test files for Sysbench
nohup sysbench fileio --file-total-size=8G prepare 
sleep 10 
sync

#Prepare database for Sysbench
mysql -e "CREATE DATABASE sysbench;"  
mysql -e "CREATE USER 'sysbench'@'localhost' IDENTIFIED BY 'password';"  
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'sysbench'@'localhost' IDENTIFIED  BY 'password';" 
sysbench /usr/share/sysbench/oltp_read_write.lua prepare --db-driver=mysql --table-size=40000000 --mysql-db=sysbench --mysql-user=sysbench --mysql-password=password
sleep 10
sync

#Sysbench Random Write Test
echo "Starting Random Write Sysbench Test"
for each in 1 4 8 16 32 64; 
	do 
		echo "Starting $each thread Random Write"
		sysbench fileio --file-total-size=8G --file-test-mode=rndwr --time=300 --file-block-size=4K --threads=$each --file-extra-flags=direct run >> ./randWrite-results; 
		sleep 10; 
	done
	
echo "###IOPS Result Random Writes###"
grep "writes/s:" randWrite-results | awk '{print $2}'

echo

echo "###95% Response Times - Random Writes###"
grep "95th percentile:" randWrite-results | awk '{print $3}'

sync

#Sysbench Random Read Test
echo "Starting Random Read Sysbench Test"
for each in 1 4 8 16 32 64; 
	do 
		echo "Starting $each thread Random Read"
		sysbench fileio --file-total-size=8G --file-test-mode=rndrd --time=300 --file-block-size=4K --threads=$each --file-extra-flags=direct run >> ./randRead-results; 
		sleep 10; 
	done 
	
echo "###IOPS Result Random Read###"
grep "reads/s:" randRead-results | awk '{print $2}'

echo

echo "###95% Response Times - Random Read###"
grep "95th percentile:" randRead-results | awk '{print $3}'

sync
rm -f test_*
sync

#Sysbench OLTP Test
for each in 1 4 8 16 32 64; 
	do 
		sysbench /usr/share/sysbench/oltp_read_write.lua --db-driver=mysql --table-size=40000000 --mysql-db=sysbench --mysql-user=sysbench --mysql-password=password --time=300 --threads=$each run >> ./oltp-results; 
		sleep 30; 
	done

echo "###Queries Per Second###"
grep "queries:" oltp-results | awk '{print $3}' | sed 's/(//'

echo

echo "###Transactions Per Second###"
grep "transactions::" oltp-results | awk '{print $3}' | sed 's/(//'

echo

echo "###95% Response Times - Queries###"
grep "95th percentile:" oltp-results | awk '{print $3}'

echo

sync

fio --time_based --name=benchmark --size=8G --runtime=300 --filename=rand --ioengine=libaio --randrepeat=0 --iodepth=32 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=4 --rw=randwrite --blocksize=4k --group_reporting > fio-rw

sleep 10
sync
rm -f rand
sleep 10

fio --time_based --name=benchmark --size=8G --runtime=300 --filename=rand --ioengine=libaio --randrepeat=0 --iodepth=32 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=4 --rw=randread --blocksize=4k --group_reporting > fio-rr

sleep 10
sync
rm -f rand
sleep 10

151.101.44.133
