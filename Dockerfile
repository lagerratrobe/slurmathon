# Single node SLURM compute cluster setup
FROM ubuntu:20.04

RUN apt update -y && \
    apt install slurmd slurmctld -y

COPY slurm.conf /etc/slurm-llnl/slurm.conf