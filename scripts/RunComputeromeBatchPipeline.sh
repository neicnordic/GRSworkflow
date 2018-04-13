#!/bin/sh
### Note: No commands may be executed until after the #PBS lines
### Account information
#PBS -W group_list=<your_group> -A <your_account>
### Job name (comment out the next line to get the name of the script used as the job name)
#PBS -N GRSworkflow
### Only send mail when job is aborted or terminates abnormally
#PBS -m n
### Number of nodes
#PBS -l nodes=1:ppn=8
### Memory
#PBS -l mem=120gb
### Requesting time - format is <days>:<hours>:<minutes>:<seconds> (here, 12 hours)
#PBS -l walltime=12:00:00
### Add current shell environment to job (comment out if not needed)
#PBS -V
### Forward X11 connection (comment out if not needed)
#PBS -X
  
# Go to the directory from where the job was submitted (initial directory is $HOME)
echo Working directory is $PBS_O_WORKDIR
cd $PBS_O_WORKDIR
 
# Load all required modules for the job
module load tools
module load singularity/2.4.2
module load <other stuff>
 
# This is where the work is done
# cd to relevant directory if not ${PBS_O_WORKDIR}
#cd <where you keep your stuff>/GRSworkflow && \
./scripts/start-bash-pipeline.sh