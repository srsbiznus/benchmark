#!/bin/bash

yum install epel-release -y
yum install wget php-cli php-xml bzip2 sysbench fio mariadb-server -y
service mariadb start

#Prepare test files for Sysbench
sysbench --test=fileio --file-total-size=8G prepare 
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
for each in 1 4 8 16 32 64; do sysbench --test=fileio --file-total-size=8G --file-test-mode=rndwr --max-time=240 --max-requests=0 --file-block-size=4K --num-threads=$each --file-extra-flags=direct run; sleep 10; done

sync

#Sysbench Random Read Test
for each in 1 4 8 16 32 64; do sysbench --test=fileio --file-total-size=8G --file-test-mode=rndrd --max-time=240 --max-requests=0 --file-block-size=4K --num-threads=$each --file-extra-flags=direct run; sleep 10; done 

sync
rm -f test_*
sync

#Sysbench OLTP Test
for each in 1 4 8 16 32 64; do sysbench --test=oltp --db-driver=mysql --oltp-table-size=40000000 --mysql-db=sysbench --mysql-user=sysbench --mysql-password=password --max-time=240 --max-requests=0 --num-threads=$each run; sleep 30; done

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
echo ynny | /usr/bin/phoronix-test-suite batch-setup

/usr/bin/phoronix-test-suite batch-benchmark pts/apache
/usr/bin/phoronix-test-suite batch-benchmark pts/nginx
/usr/bin/phoronix-test-suite batch-benchmark pts/phpbench

