#!/bin/bash

#Prepare test files for Sysbench
nohup sysbench --test=fileio --file-total-size=8G prepare
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

IOPS=$(grep -a "Requests/sec executed" ./randWrite-results | awk -vORS=, '{print $1}' | sed 's/,$/\n/')
LATENCY=$(grep -a "approx.  95 percentile:" ./randWrite-results | awk -vORS=, '{print $4}'| sed 's/,$/\n/')

echo $IOPS >> ./randWrite-summary
echo "" >> ./randWrite-summary
echo $LATENCY >> ./randWrite-summary

echo "###IOPS Result Random Writes###"
echo $IOPS

echo

echo "###Latency Result Random Writes###"
echo $LATENCY

sync
