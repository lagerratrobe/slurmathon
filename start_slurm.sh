#! /usr/bin/bash

set -e

echo "Starting the slurmctld daemon"
service slurmctld start

echo "Starting the slurmd daemon"
service slurmd start

echo "Starting the munge daemon"
service munge start