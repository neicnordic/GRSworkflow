#!/bin/bash
#SBATCH --job-name=GRS_Step1
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

# This needs to be increased by 1 since it needs to begin with the second row in the sumstats_info.v2.txt file, otherwise it would start with the header row
let "PHENO_ROW = $2 + 1"

# This is both the home directory for singularity on TSD and the project directory for for the workflow
PROJ_DIR=$3

# Static variables for sumstats.py
MAF_cf=0.01
INFO_cf=0.6
OR_cf=25

# These lines extract rows and columns from the sumstats_info.v2.txt file and use them as input for step1.sh
INPUTS=$(cat ${INPUT_PATH}/sumstats_info.v2.txt | awk -v TI="$PHENO_ROW" 'NR==TI' | cut -f1-5)
PHENO_NAME=$(cat ${INPUT_PATH}/sumstats_info.v2.txt | awk -v TI="$PHENO_ROW" 'NR==TI' | cut -f2)

## Run code for the cluster
# Run step1.sh in singularity
time singularity exec \
-B /cluster \
-B /tsd \
-B /net \
-B /work \
--home ${PROJ_DIR}:/srv \
singularity/GRSworkflow.simg \
bash code/step1_preparesumstats.sh \
${PROJ_DIR} \
/python_convert \
/ldsc \
${INPUTS} \
${MAF_cf} \
${INFO_cf} \
${OR_cf} \
> logs/step1_preparesumstats_${PHENO_NAME}.log 2>&1