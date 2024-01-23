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
rstudio/workbench-docker         latest    b0db36ba52c8   4 days ago      8.48GB
rstudio/connect-docker           latest    95a7f156e8d3   2 weeks ago     7.04GB
rstudio/package_manager-docker   latest    86b4af1f0ddb   2 weeks ago     1.55GB
ubuntu                           20.04     f78909c2b360   5 weeks ago     72.8MB
postgis-docker                   latest    03708fc7de78   4 months ago    582MB

$ docker run -it slurmathon
