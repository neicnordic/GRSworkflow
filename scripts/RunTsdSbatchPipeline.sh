#!/bin/bash
# Declare the STEP1 and STEP2 variables as arrays
declare -a STEP1
declare -a STEP2

# Print the time the pipeline started
date

source settings/settings.conf

# Enter the number of phenotypes for step 1 and samples for step 2
PHENO_JOBS=$(( $(wc -l $INPUT_PATH/sumstats_info.v2.txt | awk '{ print $1 }') - 1 ))
SAMPLE_JOBS=$(wc -l $INPUT_PATH/step2inputs.csv | awk '{ print $1 }')

# For loop that queues all jobs for step 1 and puts the job id for each job in an array to handle dependencies for step 3 execution
for i in $(seq 1 ${PHENO_JOBS}); do
	STEP1[$i]+="$(sbatch ${S1SETTINGS[@]} scripts/step1.sbatch $i | awk {'print $4'})"
done

# For loop that queues all jobs for step 2 and puts the job id for each job in an array to handle dependencies for step 3 execution
for j in $(seq 1 ${SAMPLE_JOBS}); do
	STEP2[$j]+="$(sbatch ${S2SETTINGS[@]} scripts/step2.sbatch $j | awk {'print $4'})"
done

for i in $(seq 1 ${PHENO_JOBS}); do
	for j in $(seq 1 ${SAMPLE_JOBS}); do
		sbatch ${S3SETTINGS[@]} --dependency=afterok:${STEP1[$i]}:${STEP2[$j]} scripts/step3.sbatch $j $i
	done
done
