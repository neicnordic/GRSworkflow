#!/bin/bash
# Declare the STEP1 and STEP2 variables as arrays
declare -a STEP1
declare -a STEP2

# Print the time the pipeline started
date

# Path to the directory for the sumstats_info.v2.txt and sample2inputs.csv files
INPUT_PATH=/cluster/projects/p172/oskar/GRSWorkflow/input-definitions

# Enter the number of phenotypes for step 1 and samples for step 2
PHENO_JOBS=2
SAMPLE_JOBS=2

# The bash scripts need to know what the project directory is
PROJ_DIR=/cluster/projects/p172/oskar/GRSWorkflow

# For loop that queues all jobs for step 1 and puts the job id for each job in an array to handle dependencies for step 3 execution
for i in $(seq 1 ${PHENO_JOBS}); do
	STEP1[$i]+="$(sbatch scripts/step1.sbatch $INPUT_PATH $i $PROJ_DIR | awk {'print $4'})"
done

# For loop that queues all jobs for step 2 and puts the job id for each job in an array to handle dependencies for step 3 execution
for j in $(seq 1 ${SAMPLE_JOBS}); do
	STEP2[$j]+="$(sbatch scripts/step2.sbatch $INPUT_PATH $j $PROJ_DIR | awk {'print $4'})"
done

for i in $(seq 1 ${PHENO_JOBS}); do
	for j in $(seq 1 ${SAMPLE_JOBS}); do
			sbatch --dependency=afterok:${STEP1[$i]}:${STEP2[$j]} scripts/step3.sbatch $INPUT_PATH $j $i $PROJ_DIR
	done
done