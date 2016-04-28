# benchmark

This program should be pretty set it and forget it.

Example output:

root@host [~]# ./newbench.sh 
Beginning Setup
nohup: ignoring input and appending output to `nohup.out'
Starting Random Write Sysbench Test
Starting 1 thread Random Write
Starting 4 thread Random Write
Starting 8 thread Random Write
Starting 16 thread Random Write
Starting 32 thread Random Write
Starting 64 thread Random Write
###IOPS Result Random Writes###
458.35
459.52
456.33
457.15
434.42
302.45

###Latency Result Random Writes###
0.42
12.82
20.29
39.33
102.09
484.60
Starting Random Read Sysbench Test
Starting 1 thread Random Read
Starting 4 thread Random Read
Starting 8 thread Random Read
Starting 16 thread Random Read
Starting 32 thread Random Read
Starting 64 thread Random Read
###IOPS Result Random Read###
103.39
322.78
467.55
540.57
566.66
767.85

###Latency Result Random Read###
18.92
26.74
39.43
67.16
111.12
222.79
sysbench 0.5:  multi-threaded system evaluation benchmark

Removing test files...
