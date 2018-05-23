#!/bin/bash
#SBATCH --job-name=GRS_Step2
#SBATCH --account=p172
#SBATCH --time=00-06:00:00
#SBATCH --mem-per-cpu=8192
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1

source /cluster/bin/jobsetup

module purge
module load singularity/2.5.0

## Input variables
# Input variables from the sbatch workflow file
INPUT_PATH=$1
SAMPLE_ROW=$2

# This is both the home directory for singularity on TSD and the project directory for for the workflow
PROJ_DIR=$3

# These lines extract rows and columns from the sumstats_info.v2.txt file and use them as input for step1.sh
INPUT=$(cat ${INPUT_PATH}/step2inputs.csv | awk -v TI="$SAMPLE_ROW" 'NR==TI')

# Static variables for step2.sh
MAF_cf=0.01
INFO_cf=0.6

## Run code for the cluster
# Run step2.sh in singularity
time singularity exec \
-B /cluster \
-B /tsd \
-B /net \
-B /work \
--home ${PROJ_DIR}:/srv \
singularity/GRSworkflow.simg \
bash code/step2_preparingtarget_Ricopili.sh \
${PROJ_DIR} \
${INPUT} \
${MAF_cf} \
${INFO_cf} \
> logs/step2_preparingtarget_Ricopili-${INPUT}.log 2>&1