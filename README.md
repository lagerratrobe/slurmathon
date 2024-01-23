# SLURMATHON

Exploratory work on using SLURM.  Using [this article](https://drtailor.medium.com/how-to-setup-slurm-on-ubuntu-20-04-for-single-node-work-scheduling-6cc909574365) as a starting point.  

### Goal

> Provision a single node (either EC2 or local docker container in a linux distro of your choice) and install SLURM in a single node setup (compute node = head node). Demonstrate that you both can launch batch and interactive jobs on the one-node cluster via the SLURM CLI (sbatch, scontrol, srun, squeue, scancel, sinfo....) Setting up an accounting DB (using mysql) and/or various queues with different priorities would be a bonus here.

### Notes

Created simple Dockerfile and slurm.conf to use in Container.

```
$ docker build -t slurmathon .

$ docker image ls
REPOSITORY                       TAG       IMAGE ID       CREATED         SIZE
slurmathon                       latest    fdcdaed22ad9   9 minutes ago   251MB

$ docker run -it slurmathon
```

Ok, it runs in interactive mode.  Can I start `slurmctld` and `slurmd` in the container?

```
$ docker run -it slurmathon
root@ca160ab5cb49:/# service start slurmctld
start: unrecognized service
root@ca160ab5cb49:/# service slurmctld start
 * Starting slurm central management daemon slurmctld                                                                                                                      [ OK ] 
root@ca160ab5cb49:/# service slurmd start
 * Starting slurm compute node daemon slurmd                                                                                                                               [ OK ] 
```

Yes, the services start. 

Can I do anything with the slurm queue etc?  In the container...

```
# scontrol update nodename=localhost state=idle
scontrol: error: If munged is up, restart with --num-threads=10
scontrol: error: Munge encode failed: Failed to access "/run/munge/munge.socket.2": No such file or directory
scontrol: error: authentication: Invalid authentication credential
slurm_update error: Protocol authentication error
```

Nope... to Rika's point, we need munge running.  Added it to startup script.

```
# ./start_slurm.sh 
Starting the slurmctld daemon
 * Starting slurm central management daemon slurmctld                                                                                                                      [ OK ] 
Starting the slurmd daemon
 * Starting slurm compute node daemon slurmd                                                                                                                               [ OK ] 
Starting the munge daemon
 * Starting MUNGE munged 
 ```
 
 And checking further...
 
 ```
 # sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
LocalQ*      up   infinite      1  drain localhost
```

So supposedly I now have a queue called LocalQ that you can now submit your work to.

Now what?

## Submitting jobs to SLURM

See https://docs.rc.uab.edu/cheaha/slurm/submitting_jobs/

Run this in the container in an interactive session.

```
#! /usr/bin/bash

# testjob.sh
#SBATCH --job-name=test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --partition=LocalQ
#SBATCH --time=00:10:00
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

echo "Hello World"
echo "Hello Error" 1>&2
```

Submit that testjob with...

```
# sbatch testjob.sh
Submitted batch job 2
```

Checking status...

```
# scontrol show job 2                
JobId=2 JobName=test
   UserId=root(0) GroupId=root(0) MCS_label=N/A
   Priority=4294901759 Nice=0 Account=(null) QOS=(null)
   JobState=PENDING Reason=Nodes_required_for_job_are_DOWN,_DRAINED_or_reserved_for_jobs_in_higher_priority_partitions Dependency=(null)
   Requeue=1 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   RunTime=00:00:00 TimeLimit=00:10:00 TimeMin=N/A
   SubmitTime=2024-01-23T20:05:57 EligibleTime=2024-01-23T20:05:57
   AccrueTime=2024-01-23T20:05:57
   StartTime=Unknown EndTime=Unknown Deadline=N/A
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2024-01-23T20:08:43
   Partition=LocalQ AllocNode:Sid=aed62a670923:1
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=(null)
   NumNodes=1-1 NumCPUs=1 NumTasks=1 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=1,mem=1G,node=1,billing=1
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=1 MinMemoryNode=1G MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=/root/testjob.sh
   WorkDir=/root
   StdErr=/root/test_2.err
   StdIn=/dev/null
   StdOut=/root/test_2.out
   Power=
```
