#!/bin/bash
#SBATCH --job-name=GRS_Step2
#SBATCH --ntasks=1
#SBATCH --ntasks-per-node=1

source /cluster/bin/jobsetup
source settings/settings.conf

module purge
module load singularity/2.6.1

SAMPLE_ROW=$1

# These lines extract rows and columns from the sumstats_info.v2.txt file and use them as input for step1.sh
INPUT=$(awk -v TI="$SAMPLE_ROW" 'NR==TI' ${INPUT_PATH}/step2inputs.csv)

# Static variables for step2.sh
MAF_cf=0.01
INFO_cf=0.6

## Run code for the cluster
# Run step2.sh in singularity
time singularity exec \
-B /cluster \
-B /tsd \
-B /net \
--home ${PROJ_DIR}:/srv \
singularity/GRSworkflow.simg \
bash code/step2_preparingtarget_Ricopili.sh \
${PROJ_DIR} \
${INPUT} \
${MAF_cf} \
${INFO_cf} \
> logs/step2_preparingtarget_Ricopili-${INPUT}.log 2>&1
