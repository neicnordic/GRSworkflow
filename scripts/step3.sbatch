#!/bin/bash
#SBATCH --job-name=GRS_Step3
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

# This needs to be increased by 1 since it needs to begin with the second row in the sumstats_info.v2.txt file, otherwise it would start with the header row
let "PHENO_ROW = $3 + 1"

# This is both the home directory for singularity on TSD and the project directory for for the workflow
PROJ_DIR=$4

# These lines extract rows and columns from the sumstats_info.v2.txt file and use them as input for step1.sh
SAMPLE_NAME=$(cat ${INPUT_PATH}/step2inputs.csv | awk -v TI="$PHENO_ROW" 'NR==TI')
PHENO_NAME=$(cat ${INPUT_PATH}/sumstats_info.v2.txt | awk -v TI="$PHENO_ROW" 'NR==TI' | cut -f2)

## Run code for the cluster
# Run step3.sh in singularity
time singularity exec \
-B /cluster \
-B /tsd \
-B /net \
-B /work \
--home ${PROJ_DIR}:/srv \
singularity/GRSworkflow.simg \
bash code/step1_preparesumstats.sh \
${PROJ_DIR} \
${SAMPLE_NAME} \
${PHENO_NAME} \
> logs/step1_preparesumstats_${PHENO_NAME}.log 2>&1