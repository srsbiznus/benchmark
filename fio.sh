#!/bin/bash

echo "Starting Random Write fio Test"

fio --time_based --name=benchmark --size=8G --runtime=300 --filename=rand --ioengine=libaio --randrepeat=0 --iodepth=32 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=4 --rw=randwrite --blocksize=4k --group_reporting >> fio-randWrite.txt

sleep 10
sync
rm -f rand
sleep 10

echo "Starting Random Read fio Test"

fio --time_based --name=benchmark --size=8G --runtime=300 --filename=rand --ioengine=libaio --randrepeat=0 --iodepth=32 --direct=1 --invalidate=1 --verify=0 --verify_fatal=0 --numjobs=4 --rw=randread --blocksize=4k --group_reporting >> fio-randRead.txt

sleep 10
sync
rm -f rand
sleep 10

FIORW=$(grep '95.00th' fio-randWrite.txt | awk '{print $9}' | cut -d] -f1)
FIORR=$(grep '95.00th' fio-randRead.txt | awk '{print $9}' | cut -d] -f1)

echo "### fio Rand Write Results ###" >> fio-summary.txt
echo $FIORW >> fio-summary.txt
echo "### fio Rand Read Results ###" >> fio-summary.txt
echo $FIORR >> fio-summary.txt

echo "### fio Rand Write Results ###"
echo $FIORW

echo

echo "### fio Rand Read Results ###"
echo $FIORR
