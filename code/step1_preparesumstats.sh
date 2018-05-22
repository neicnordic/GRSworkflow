#!/bin/bash/
# written by Lu Yi (lu.yi@ki.se)
# 2018-05-14

## read in parameters
DIR_PROJ=$1
DIR_Python_convert=$2
DIR_LDSC=$3
INPUT=$4
GRS_NAME=$5
NCASE=$6
NCONT=$7
NTOT=$8
MAF_cf=$9
INFO_cf=${10}
OR_cf=${11}

echo "Main directory:" ${DIR_PROJ}
echo "Python_convert and LDSC in:" ${DIR_Python_convert} ${DIR_LDSC}
echo "Input file:" ${DIR_PROJ}/data/sumstats/raw/${INPUT}
echo "GRS of" ${GRS_NAME} "based on Ncase:" ${NCASE} "Ncontrol:" ${NCONT} or "Ntotal:" ${NTOT}
echo -e "\n"
echo "check output:" ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.{qced.tsv.gz,tsv.log}
echo "check ldsc h2g results:" ${DIR_PROJ}/results/sumstats_ldsc/${GRS_NAME}.sumstats.h2.log
echo -e "\n"

# use python_convert to make standardised file format & QC

if [[ "${NCASE}" != 'NA' && "${NCONT}" != 'NA' ]]
then 
	# run the following for disease trait if NCASE/NCONTROL are provided
	# note: I have removed '[ ${NTOT} == "NA" ]'
	# because Ncase/Ncont should be given priority even if Ntot is provided

	gunzip -c ${DIR_PROJ}/data/sumstats/raw/${INPUT} |\
	python ${DIR_Python_convert}/sumstats.py csv \
	--auto  --force --head 5 \
	--ncase-val ${NCASE} \
	--ncontrol-val ${NCONT} \
	> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv 2> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv.log

	cat ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv |\
	python ${DIR_Python_convert}/sumstats.py qc \
	--require-cols SNP A1 A2 PVAL EFFECT \
	--snps-only --just-acgt --drop-strand-ambiguous-snps --just-rs-variants \
	--maf ${MAF_cf} \
	--info ${INFO_cf} \
	--max-or ${OR_cf} \
	--qc-substudies \
	> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv 2>> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv.log
	
elif [ ${NTOT} != "NA" ]
then
	# run the following if only total sample size NTOT is provided

	gunzip -c ${DIR_PROJ}/data/sumstats/raw/${INPUT} |\
	python ${DIR_Python_convert}/sumstats.py csv \
	--auto  --force --head 5 \
	--n-val ${NTOT} \
	> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv 2> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv.log

	cat ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv |\
	python ${DIR_Python_convert}/sumstats.py qc \
	--require-cols SNP A1 A2 PVAL EFFECT \
	--snps-only --just-acgt --drop-strand-ambiguous-snps --just-rs-variants \
	--maf ${MAF_cf} \
	--info ${INFO_cf} \
	--max-or ${OR_cf} \
	--qc-substudies \
	> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv 2>> ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv.log

else 
	echo "Warning: require total N for quantitative trait and Ncase/Ncont for disorders"
fi

# to view the log file in the step1.log
cat ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv.log

# check whether there is OR column
# if so, replace OR with BETA column = log(OR) in the sumstats
tmp=`head -1 ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv | grep -iw OR | wc -l`
if [ $tmp -eq 1 ]
then
	cat ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv |\
	awk -v or=OR '
	BEGIN {FS=OFS="\t"}
	NR==1 {for (i=1; i<=NF; i++) {var[$i] = i} ; print $0}
	NR > 1 {$var[or]=log($var[or]); print $0}
	' |sed "s/OR/BETA/g" > ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv.tmp
	mv ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv.tmp ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv
	echo -e "\nNote: Replaced OR column with BETA(=logOR) for ${GRS_NAME}.qced.tsv\n"
else 
	echo -e "\n"
fi



# LDSC 

python ${DIR_LDSC}/munge_sumstats.py \
--sumstats ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.qced.tsv \
--out ${DIR_PROJ}/intermediate/${GRS_NAME} \
--merge-alleles ${DIR_PROJ}/data/ref/ldsc/eur_w_ld_chr/w_hm3.snplist 

python ${DIR_LDSC}/ldsc.py \
--h2 ${DIR_PROJ}/intermediate/${GRS_NAME}.sumstats.gz \
--ref-ld-chr ${DIR_PROJ}/data/ref/ldsc/eur_w_ld_chr/ \
--w-ld-chr ${DIR_PROJ}/data/ref/ldsc/eur_w_ld_chr/ \
--out ${DIR_PROJ}/results/sumstats_ldsc/${GRS_NAME}.sumstats.h2
