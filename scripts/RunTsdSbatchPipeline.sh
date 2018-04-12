#!/bin/bash
#
#SBATCH --job-name=GRSworkflow
#SBATCH --account=your-accound-id
#SBATCH --time=0-06:00:00 # or an appropriate amount
#SBATCH --mem-per-cpu=8192
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1

source /cluster/bin/jobsetup

module purge
module load singularity/2.4.4

cd /cluster/projects/your-project-folder/GRSworkflow && \
./scripts/RunTsdSbatchPipeline.sh