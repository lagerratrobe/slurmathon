# Single node SLURM compute cluster setup
FROM ubuntu:20.04

RUN apt update -y && \
    apt install slurmd slurmctld vim systemd munge libmunge2 libmunge-dev -y

COPY slurm.conf /etc/slurm-llnl/slurm.conf

#ENTRYPOINT service slurmctld start && /bin/bash

COPY start_slurm.sh /start_slurm.sh
RUN chmod 755 /start_slurm.sh

#ENTRYPOINT ["/start_slurm.sh"]