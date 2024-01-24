# SLURMATHON

## Goal

> Provision a single node (either EC2 or local docker container in a linux distro of your choice) and install SLURM in a single node setup (compute node = head node). Demonstrate that you both can launch batch and interactive jobs on the one-node cluster via the SLURM CLI (sbatch, scontrol, srun, squeue, scancel, sinfo....) Setting up an accounting DB (using mysql) and/or various queues with different priorities would be a bonus here.

## How to use this repo

### Step 1: Clone the repo
Needs at least 4 CPU cores and 4 GB of RAM avail.

### Step 2: Build the docker image
```
$ docker build -t slurmathon .
```

### Step 3: Run the image in interactive mode
```
$ docker run -it --privileged slurmathon
```

### Step 4: Start the slurm and munge daemons
```
$ ./start_slurm.sh 
Starting the slurmctld daemon
 * Starting slurm central management daemon slurmctld                                                                                                                      [ OK ] 
Starting the slurmd daemon
 * Starting slurm compute node daemon slurmd                                                                                                                               [ OK ] 
Starting the munge daemon
 * Starting MUNGE munged
 ```
 
### Step 5: Check your partition
Check that you have a 1 node partition up and available.

```
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
LocalQ*      up   infinite      1   idle localhost
```

### Step 6: Submit a job to the partition

```
$ sbatch testjob.sh
Submitted batch job 2
```

### Step 7: Verify that job ran properly

See https://docs.rc.uab.edu/cheaha/slurm/submitting_jobs/ for additional info.

```
$ scontrol show job 2 

JobId=2 JobName=test
   UserId=root(0) GroupId=root(0) MCS_label=N/A
   Priority=4294901759 Nice=0 Account=(null) QOS=(null)
   JobState=COMPLETED Reason=None Dependency=(null)  <--------------- look for "COMPLETED"
   Requeue=1 Restarts=0 BatchFlag=1 Reboot=0 ExitCode=0:0
   RunTime=00:00:00 TimeLimit=00:10:00 TimeMin=N/A
   SubmitTime=2024-01-23T21:19:19 EligibleTime=2024-01-23T21:19:19
   AccrueTime=2024-01-23T21:19:19
   StartTime=2024-01-23T21:19:20 EndTime=2024-01-23T21:19:20 Deadline=N/A
   SuspendTime=None SecsPreSuspend=0 LastSchedEval=2024-01-23T21:19:20
   Partition=LocalQ AllocNode:Sid=ea2dc023785a:1
   ReqNodeList=(null) ExcNodeList=(null)
   NodeList=localhost
   BatchHost=localhost
   NumNodes=1 NumCPUs=1 NumTasks=1 CPUs/Task=1 ReqB:S:C:T=0:0:*:*
   TRES=cpu=1,node=1,billing=1
   Socks/Node=* NtasksPerN:B:S:C=0:0:*:* CoreSpec=*
   MinCPUsNode=1 MinMemoryNode=1G MinTmpDiskNode=0
   Features=(null) DelayBoot=00:00:00
   OverSubscribe=OK Contiguous=0 Licenses=(null) Network=(null)
   Command=//testjob.sh
   WorkDir=/
   StdErr=//test_2.err <------ Check this was written
   StdIn=/dev/null
   StdOut=//test_2.out  <----- Check this was written
   Power=
   
$ ls -l test*
-rw-r--r-- 1 root root  12 Jan 23 21:19 test_2.err
-rw-r--r-- 1 root root  12 Jan 23 21:19 test_2.out
```

## To Do:
* [X] - Get slurm and munge daemons started when container is run
* [ ] - Figure out how to submit a job from the host machine to the SLURM queue/partition in the container
* ~~"accounting DB" use-case or something similar~~

## Making the service accessible from Host

"The default port used by slurmctld to listen for incoming requests is 6817. This port can be changed with the SlurmctldPort slurm. conf parameter."  Looks like 6818 is also needed by slurmd.  Opened those ports in the DOCKERFILE, need to also run the container and map the ports

```
docker run -d --privileged slurmathon -p 6817:6817 -p 6818:6818 --name slurm
```

Ok, it's running in the container and ostensibly accessible.  How to I access the job queue from my host?

> If you install the Slurm client on Server B . Copy your slurm.conf to it and then ensure it has the correct authentication (i.e the correct Munge key) , it should work.

Ok, so assuming that my host machine is "Server B" in this case, I need the `slurm.conf` and munge key.

```
# On host
sudo apt install slurm-client munge
sudo chmod 444 /etc/munge/munge.key
sudo cp /etc/munge/munge.key ./
sudo chown randre:randre munge.key

# ADD to Dockerfile
COPY munge.key /etc/munge/munge.key
RUN chmod 400 /etc/munge/munge.key
RUN chown 102:102 /etc/munge/munge.key
```

Ran `docker inspect` on the container:

```
$ docker inspect f98d8d113a06

IP = 172.17.0.6
```

Ran nc against that Ip and port 6818...

```
$ nc 172.17.0.6 6818
�"A���e�MUNGE:AwQFAABl8v1Ihj6iM+IoXZbVo6zCSGsXSK010B28FzxRu6Ud6sPAxj8OfI2VrwYXHJpxUw2pCRo8OkRz7ReN9r7jWyNAecoKrHLGi0zMMyNAJDwN9RkdaUhC7CO3vY8RBTfBKaY=:�
```
...promising.

Update slurm.conf on host to use that container IP...

```
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
LocalQ*      up   infinite      1   idle localhost
```

- Updated the `/etc/slurm-llnl/slurm.conf` so that SlurmctldHost=172.17.0.6

- ran `sinfo` and could see the partition
```
$ sinfo
PARTITION AVAIL  TIMELIMIT  NODES  STATE NODELIST
LocalQ*      up   infinite      1   idle localhost
```

- Submited a test job:
`$ sbatch testjob.sh
Submitted batch job 2
`

- Checked status... not completed
```
$ scontrol show job 2 
JobId=2 JobName=test
   UserId=randre(1000) GroupId=randre(1000) MCS_label=N/A
   Priority=4294901759 Nice=0 Account=(null) QOS=(null)
   JobState=PENDING Reason=BeginTime Dependency=(null)
```
- Checked the queue to see why pending...
```
$ squeue --format="%.18i %.9P %.30j %.8u %.8T %.10M %.9l %.6D %R" --partition="LocalQ" --states="PENDING,RUNNING"
             JOBID PARTITION                           NAME     USER    STATE       TIME TIME_LIMI  NODES NODELIST(REASON)
                 2    LocalQ                           test   randre  PENDING       0:00     10:00      1 (BeginTime)
```
- Checked my testjob to see what it says...
```
$ cat testjob.sh 
#! /usr/bin/bash

# testjob.sh
#SBATCH --job-name=test
#SBATCH --nodes=1
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem=1G
#SBATCH --partition=LocalQ
#SBATCH --time=00:10:00 <----------- problem
#SBATCH --output=%x_%j.out
#SBATCH --error=%x_%j.err

echo "Hello World"
echo "Hello Error" 1>&2
```
- Changed job to have a --begin directive instead of --time
```
#SBATCH --begin=now+5
```

- Canceled the job
```
$ scancel 2
```

- Resubmitted the testjob.sh 
```
$ sbatch testjob.sh
Submitted batch job 3
```

- Rechecked the status:

```
scontrol show job 3
JobState=PENDING Reason=BeginTime
```

- Pretty sure I have a time mismatch of some sort between host and container.  Good enough for now though.


## Additional info
- https://drtailor.medium.com/how-to-setup-slurm-on-ubuntu-20-04-for-single-node-work-scheduling-6cc909574365 (sorta works, but has missing info)
- slurm.conf parameters ( https://slurm.schedmd.com/slurm.conf.html)
- https://slurm.schedmd.com/quickstart.html  (Really the foundational place for info)
- https://medium.com/analytics-vidhya/slurm-cluster-with-docker-9f242deee601 (overview of Dockerized setup with separate control and worker nodes.  Probably more realistic)
- http://docs.nanomatch.de/technical/SimStackRequirements/SingleNodeSlurm.html (good generic info on single node)
- https://southgreenplatform.github.io/trainings/hpc/slurminstallation/ (Slurm Admin training)
- https://ecs.rutgers.edu/slurm_commands.html  (another univ how-to)

