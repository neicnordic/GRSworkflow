#!/bin/bash
#SBATCH --job-name=GRS_Step1
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1

source /cluster/bin/jobsetup
source settings/settings.conf

module purge
module load singularity/2.6.1

# Static variables for sumstats.py
MAF_cf=0.01
INFO_cf=0.6
OR_cf=25

PHENO_ROW=$1

# These lines extract rows and columns from the sumstats_info.v2.txt file and use them as input for step1.sh
INPUTS=$(tail -n +2 ${INPUT_PATH}/sumstats_info.v2.txt | awk -v TI="$PHENO_ROW" 'NR==TI' | cut -f1-5)
PHENO_NAME=$(tail -n +2 ${INPUT_PATH}/sumstats_info.v2.txt | awk -v TI="$PHENO_ROW" 'NR==TI' | cut -f2)

## Run code for the cluster
# Run step1.sh in singularity
time singularity exec \
-B /cluster \
-B /tsd \
-B /net \
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
