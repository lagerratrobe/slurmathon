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
