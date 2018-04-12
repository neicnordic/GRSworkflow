#!/bin/bash
#
#SBATCH --job-name=GRSworkflow
#SBATCH --account=your-accound-id
#SBATCH --time=0-06:00:00 # or an appropriate amount
#SBATCH --ntasks=1
#SBATCH --partition=core

cd /cluster/projects/your-project-folder/GRSworkflow && \
./scripts/start-bash-pipeline.sh
