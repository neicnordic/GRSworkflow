#!/bin/bash/
# written by Lu Yi (lu.yi@ki.se)
# version 4 2018-03-29 

# AIM: prepare GRS input of target data
 
# NOTE: This script takes the datasets that have been processed through Ricopilli pipeline 
# i.e., imputed data should have a specific directory structure qc1(minimum requirement)/info/bg/bgs/etc.
# For descriptions of the folder structure containing Ricopilli imputed data: 
# see https://sites.google.com/a/broadinstitute.org/ricopili/imputation

############################################################################
####################### IMPUTED DOSAGE DATA IN TARGET ######################
############################################################################

# STEPs:
# 1. Prepare the list of post-imputation QC'ed SNPs (need the two alleles!)
# [** Note:
# this list will be merged with SNPs in the discovery set before clumping. 
# Failing to do so, the SNPs after clumping, if poor quality in the target set, 
# will be missed when generating the risk scores!]
# 1.1 if 'info' folder is available, then apply post-imputation QC 
# 	(similar to the ones applied to the discovery set):
#	SNPs only (with rsIDs & no strand-ambiguous alleles)
#	info >= pre-specified cutoff
#	MAF >= pre-specified cutoff
# 1.2 or when 'bgs' folder is available, just use SNPs in all bim files (select SNP only), 
# 	as they have been cleaned to have 
#	missing rate < 0.01 for bestguess geno calls with highest probability > 0.8
#	MAF > 5%
# 1.3 when neither of the two folders available, cannot apply post-imputation QC, 
# 	just extract the SNPs and two alleles from the dosage files in 'qc1' folder. 
# 	not a disaster even if the post-imputation QC cannot be applied, 
# 	bz the dosage scores will reflect the uncertainty in imputation quality. 
# 2. Generate dosage file.list and 1 fam file - required when generating GRS in PLINK.


############################################################################

## read in parameters
DIR_PROJ=$1

STUDY=$2
IMP_DIR=${DIR_PROJ}/data/geno/raw/${STUDY}  # directory holding 'raw' imputed data

MAF_cf=$3
# MAF filter 5% is default in /bgs data; if change as MAF=0.01, need to change to /bg and calculate MAF
INFO_cf=$4

mkdir -p ${DIR_PROJ}/data/geno/postqc/${STUDY}  # directory holding 'postqc' imputed data
OUT_DIR=${DIR_PROJ}/data/geno/postqc/${STUDY}
cd ${OUT_DIR} 

OUT_SNPFILE=${OUT_DIR}/postimp.SNPs
OUT_DOSELIST=${OUT_DIR}/dosefile.list
OUT_FAM=${OUT_DIR}/dose.fam

# remove the existing outfile
rm -f ${OUT_SNPFILE} ${OUT_DOSELIST}

############################################################################

echo -e "\nStart running the script to prepare the target set at `date`"

# STEP1:
# 1.1 check whether the 'info' folder is available
if test -d ${IMP_DIR}/info 
then 
	echo -e "\nSuccessfully located 'info' folder, will perform post-imputation QC"
	FILES=`ls ${IMP_DIR}/info/*.info`
	for FILE in ${FILES}
		do
		awk -v out=${OUT_SNPFILE} -v maf=${MAF_cf} -v info=${INFO_cf} '
		BEGIN {FS=OFS="\t"}
		# check whether correct columns
		NR==1 {
			if ($2!="SNP" || $5!="info" || $6!="freq" || $7!="a1" || $8!="a2") {
				print "ERROR: Unexpected column header!" > "/dev/stderr"; exit 1 
				}
			}
		NR>1 {
			alleles=toupper($7$8)
			# QC filters
			if (($5 >= info) && ($6>=maf && $6<=1-maf) && ($2 ~ /^rs/) && (alleles == "AC" || alleles == "AG" || alleles == "TC" || alleles == "TG" || alleles == "CA" || alleles == "CT" || alleles == "GA" || alleles == "GT")) {
				print $2, $7, $8 >> out
				}
			}' ${FILE}
		done
	echo "After post-imputation QC (SNPs with rsIDs only; MAF>=`echo ${MAF_cf}`; INFO>=`echo ${INFO_cf}`), `wc -l < ${OUT_SNPFILE}` imputed SNPs were available."
# 1.2 if cannot locate 'info', check whether the 'bgs' folder is available
elif test -d ${IMP_DIR}/bgs
then
	echo -e "\nSuccessfully located 'bgs' folder, will extract SNPs there."
	cat ${IMP_DIR}/bgs/*.bim | awk '
		BEGIN {OFS="\t"} {
			alleles=toupper($5$6)
			if ( ($2 ~ /^rs/) && (alleles == "AC" || alleles == "AG" || alleles == "TC" || alleles == "TG" || alleles == "CA" || alleles == "CT" || alleles == "GA" || alleles == "GT") ) {
				print $2,$5,$6
				}
			}' >> ${OUT_SNPFILE}
	echo "After post-imputation QC (SNPs with rsIDs only; genoprob > 0.8; missing rate > 0.99; MAF>0.05), `wc -l < ${OUT_SNPFILE}` imputed SNPs were available."
# 1.3 if cannot locate 'info' or 'bgs', then hopefully 'qc1' folder is available
elif test -d ${IMP_DIR}/qc1
then 
	echo -e "\nDid not find 'info' or 'bgs', thus cannot perform post-imputation QC! Will just extract SNPs and alleles."
	FILES=`ls ${IMP_DIR}/qc1/*.dosage.gz`
	for FILE in ${FILES}
		do
		gunzip -c ${FILE} | awk -v out=${OUT_SNPFILE} '
			BEGIN {OFS="\t"}
			NR>1 {
			# excl. the header, and extract first three columns (SNP,A1,A2) for SNP only
				alleles=toupper($2$3)
				if ( ($1 ~ /^rs/) && (alleles == "AC" || alleles == "AG" || alleles == "TC" || alleles == "TG" || alleles == "CA" || alleles == "CT" || alleles == "GA" || alleles == "GT") ) {
					print $1, $2, $3 >> out
					}
			}' 
		done
	echo "Without post-imputation QC, `wc -l < ${OUT_SNPFILE}` imputed SNPs were available."
else 	
# Error msg if cannot find any of the imputation folders
	echo -e "\nERROR: Did not find any of the following folders: info/bgs/qc1. Exaction of SNPs unsuccessful."
fi 

# STEP2:
if test -d ${IMP_DIR}/qc1
then 
	ls ${IMP_DIR}/qc1/*.dosage.gz > tmp
	# later when using PLINK to generate PRS, the list of dosage files is required in this format: #,dosefile
	awk '{print NR, $0}' tmp > ${OUT_DOSELIST}
	rm tmp
	# copy one fam file over
	FAM=`ls ${IMP_DIR}/qc1/*.dosage.fam | head -1`
	cp ${FAM} ${OUT_FAM}
	echo -e "\nHave written dosage files into ${OUT_DOSELIST}; and copied one fam file as ${OUT_FAM}."
else 
	echo -e "\nERROR: Cannot locate the directory containing imputation dosage data."
fi

echo -e "\nCompleted STEP2 at `date`"
