#!/bin/bash

yum install epel-release -y
yum install wget php-cli php-xml bzip2 sysbench fio mariadb-server -y
service mariadb start

#Prepare test files for Sysbench
nohup sysbench --test=fileio --file-total-size=8G prepare 
sleep 10 
sync

#Prepare database for Sysbench
mysql -e "CREATE DATABASE sysbench;"  
mysql -e "CREATE USER 'sysbench'@'localhost' IDENTIFIED BY 'password';"  
mysql -e "GRANT ALL PRIVILEGES ON *.* TO 'sysbench'@'localhost' IDENTIFIED  BY 'password';" 
sysbench --test=oltp --db-driver=mysql --oltp-table-size=40000000 --mysql-db=sysbench --mysql-user=sysbench --mysql-password=password prepare 
sleep 10
sync

#Sysbench Random Write Test
echo "Starting Random Write Sysbench Test"
for each in 1 4 8 16 32 64; 
	do 
		echo "Starting $each thread Random Write"
		sysbench --test=fileio --file-total-size=8G --file-test-mode=rndwr --max-time=300 --max-requests=0 --file-block-size=4K --num-threads=$each --file-extra-flags=direct run >> ./randWrite-results; 
		sleep 10; 
	done
	
echo "###IOPS Result Random Writes###"
grep "Requests/sec executed" randWrite-results | awk '{print $1}'

echo

echo "###Latency Result Random Writes###"
grep "approx.  95 percentile:" randWrite-results | awk '{print $4}'| cut -d'm' -f1

sync

#Sysbench Random Read Test
echo "Starting Random Read Sysbench Test"
for each in 1 4 8 16 32 64; 
	do 
		echo "Starting $each thread Random Read"
		sysbench --test=fileio --file-total-size=8G --file-test-mode=rndrd --max-time=300 --max-requests=0 --file-block-size=4K --num-threads=$each --file-extra-flags=direct run >> ./randRead-results; 
		sleep 10; 
	done 
	
echo "###IOPS Result Random Read###"
grep "Requests/sec executed" randRead-results | awk '{print $1}'

echo

echo "###Latency Result Random Read###"
grep "approx.  95 percentile:" randRead-results | awk '{print $4}'| cut -d'm' -f1

sync
sysbench --test=fileio --file-total-size=8G cleanup
sync

#Sysbench OLTP Test
for each in 1 4 8 16 32 64; 
	do 
		sysbench --test=oltp --db-driver=mysql --oltp-table-size=40000000 --mysql-db=sysbench --mysql-user=sysbench --mysql-password=password --max-time=300 --max-requests=0 --num-threads=$each run >> ./oltp-results; 
		sleep 30; 
	done

sync

fio --time_based --name=benchmark --size=8G --runtime=300 --filename=rand --ioengine=libaio --randrepeat=0 --iodepth=32 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=4 --rw=randwrite --blocksize=4k --group_reporting

sleep 10
sync
rm -f rand
sleep 10

fio --time_based --name=benchmark --size=8G --runtime=300 --filename=rand --ioengine=libaio --randrepeat=0 --iodepth=32 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=4 --rw=randread --blocksize=4k --group_reporting

sleep 10
sync
rm -f rand
sleep 10

wget http://www.phoronix-test-suite.com/download.php?file=phoronix-test-suite-6.2.2 -O phoronix-test-suite_6.2.2.tar.gz
tar xvf phoronix-test-suite_6.2.2.tar.gz
cd phoronix-test-suite/
./install-sh
echo "net.ipv6.conf.all.disable_ipv6 = 1" >> /etc/sysctl.conf
sysctl -p
echo nn | /usr/bin/phoronix-test-suite batch-setup
/usr/bin/phoronix-test-suite install pts/apache
/usr/bin/phoronix-test-suite install pts/nginx
/usr/bin/phoronix-test-suite install pts/phpbench

/usr/bin/phoronix-test-suite batch-run pts/apache
/usr/bin/phoronix-test-suite batch-run pts/nginx
/usr/bin/phoronix-test-suite batch-run pts/phpbench

