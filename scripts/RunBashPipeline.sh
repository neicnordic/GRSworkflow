#!/bin/bash
set -e
DIR_PROJ=`pwd`

# list the path of pre-installed python-based tools in the singularity containers
DIR_Python_convert=/python_convert
DIR_LDSC=/ldsc

# Define variables for step1.sh
# Note: always incl. the sample size N/Ncase/Ncon
sumstat=(ckqny.scz2snpres.gz PGC_MDD2018_10kSNPs.gz)
name=(PGC_SCZ_2014_GLB PGC_MDD_2018_GLB)
Ncase=(34241 135458)
Ncont=(45604 344901)


# Check if a file named *.bim exists before pipeline is executed, execute if it exists.
# Note: This only assumes that *.bim exists, if the other files are missing step3.sh will still fail
if [ ! -z data/ref/1kg_p1v3_PLINK_cleaned/*.bim ];
	then
		# If a file named *.tsv exists in the data/sumstats/postqc folder, don't run this step
		if [ -z `find data/sumstats/postqc/ -type f -name "*.tsv" -printf 1 -quit` ];
			then
				echo "Running step1_preparesumstats.sh"
				# need to run this step for each trait - with different parameters
				for i in 0 1; do
					bash code/step1_preparesumstats.sh \
					${DIR_PROJ} \
					${DIR_Python_convert} \
					${DIR_LDSC} \
					${sumstat[i]} \
					${name[i]} \
					${Ncase[i]} \
					${Ncont[i]} \
					> logs/step1_preparesumstats_${name[i]}.log;
				done
		fi

		# Define variables for step2.sh
		MAF=0.01
		INFO=0.6
		STUDY_LIST="s1 s2"

		# If a file named *.fam exists in the data/geno/postqc/s*/ folder, don't run this step
		if [ -z `find data/geno/postqc/s*/ -type f -name "*.fam" -printf 1 -quit` ];
			then
				echo "Running step2_preparingtarget_Ricopili.sh"
				for STUDY in ${STUDY_LIST}; do
					bash code/step2_preparingtarget_Ricopili.sh \
					${DIR_PROJ} \
					${STUDY} \
					${MAF} \
					${INFO} \
					> logs/step2_preparingtarget_Ricopili_${STUDY}.log
				done
		fi

		###### STEP3: calculating the genetic risk score
		# need to run the script for 2 sumstats x 2 studies
		GRS_NAME_LIST="PGC_SCZ_2014_GLB PGC_MDD_2018_GLB"
				echo "Running step3_calculateGRS.sh"
				for STUDY in ${STUDY_LIST}; do
					for GRS_NAME in ${GRS_NAME_LIST}; do
						bash code/step3_calculateGRS.sh \
						${DIR_PROJ} \
						${STUDY} \
						${GRS_NAME} \
						> logs/step3_calculateGRS_${STUDY}_${GRS_NAME}.log 2>&1
					done
				done
else
	echo "1kg reference files are missing, step3_calculateGRS.sh will fail, stopping execution."
fi
