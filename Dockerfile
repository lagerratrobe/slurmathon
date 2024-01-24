# Single node SLURM compute cluster setup
FROM ubuntu:20.04

RUN apt update -y && \
    apt install -y \
    slurmd \
    slurmctld \
    slurm-client \
    munge \
    vim \
    systemd \
    libmunge2 \
    libmunge-dev

# Move some conf siles and setup scripts into container
COPY slurm.conf /etc/slurm-llnl/slurm.conf
COPY testjob.sh /testjob.sh
COPY start_slurm.sh /start_slurm.sh
RUN chmod 755 /start_slurm.sh

# Open the slurmctld and slurmd ports
EXPOSE 6817 6818

ENTRYPOINT ["/start_slurm.sh"]