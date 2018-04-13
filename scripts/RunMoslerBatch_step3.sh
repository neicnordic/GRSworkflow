#!/bin/bash
#SBATCH -A bils2016005
#SBATCH -p core
#SBATCH -n 1
#SBATCH -t 8:00:00


# written by Lu Yi (Lu.Yi@ki.se)
# April 04, 2016
# updated: Jan 15, 2018
# updated again: Apr 13, 2018

# This script aims to submit the job of running step3_calculateGRS.sh to Mosler. 


DIR_PROJ=$1

STUDY=$2

GRS_NAME=$3

bash code/step3_calculateGRS.sh \
${DIR_PROJ} \
${STUDY} \
${GRS_NAME} \
> logs/step3_calculateGRS_${STUDY}_${GRS_NAME}.log 2>&1


