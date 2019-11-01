#!/bin/bash
#SBATCH --job-name=GRS_Step3
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1

source /cluster/bin/jobsetup
source settings/settings.conf

module purge
module load singularity/2.6.1

SAMPLE_ROW=$1
PHENO_ROW=$2

# These lines extract rows and columns from the sumstats_info.v2.txt file and use them as input for step1.sh
SAMPLE_NAME=$(awk -v TI="$SAMPLE_ROW" 'NR==TI' ${INPUT_PATH}/step2inputs.csv)
PHENO_NAME=$(tail -n +2 ${INPUT_PATH}/sumstats_info.v2.txt | awk -v TI="$PHENO_ROW" 'NR==TI' | cut -f2)

## Run code for the cluster
# Run step3.sh in singularity
time singularity exec \
-B /cluster \
-B /tsd \
-B /net \
--home ${PROJ_DIR}:/srv \
singularity/GRSworkflow.simg \
bash code/step3_calculateGRS.sh \
${PROJ_DIR} \
${SAMPLE_NAME} \
${PHENO_NAME} \
> logs/step3_calculateGRS_${SAMPLE_NAME}_${PHENO_NAME}.log 2>&1
