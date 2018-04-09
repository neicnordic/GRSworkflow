#!/bin/bash/
# written by Lu Yi (lu.yi@ki.se)
# 2018-03-29

## read in parameters
DIR_PROJ=$1
DIR_Python_convert=$2
DIR_LDSC=$3
INPUT=$4
GRS_NAME=$5
NCASE=$6
NCONT=$7


echo "Main directory:" ${DIR_PROJ}
echo "Python_convert and LDSC in:" ${DIR_Python_convert} ${DIR_LDSC}
echo "Input file:" ${DIR_PROJ}/data/sumstats/raw/${INPUT}
echo "GRS of" ${GRS_NAME} "based on Ncase:" ${NCASE} "Ncontrol:" ${NCONT}
echo -e "\n"
echo "check output:" ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.{tsv,tsv.log}
echo "check ldsc h2g results:" ${DIR_PROJ}/results/sumstats_ldsc/${GRS_NAME}.sumstats.h2.log
echo -e "\n"

python ${DIR_Python_convert}/sumstats.py csv \
--sumstats ${DIR_PROJ}/data/sumstats/raw/${INPUT} \
--out ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv \
--force \
--auto \
--head 5 \
--ncase-val ${NCASE} \
--ncontrol-val ${NCONT}
# --chr hg19chrc \  #need this flag for SCZ, but not needed for other traits

python ${DIR_LDSC}/munge_sumstats.py \
--sumstats ${DIR_PROJ}/data/sumstats/postqc/${GRS_NAME}.tsv \
--out ${DIR_PROJ}/intermediate/${GRS_NAME} \
--merge-alleles ${DIR_PROJ}/data/ref/ldsc/eur_w_ld_chr/w_hm3.snplist 

python ${DIR_LDSC}/ldsc.py \
--h2 ${DIR_PROJ}/intermediate/${GRS_NAME}.sumstats.gz \
--ref-ld-chr ${DIR_PROJ}/data/ref/ldsc/eur_w_ld_chr/ \
--w-ld-chr ${DIR_PROJ}/data/ref/ldsc/eur_w_ld_chr/ \
--out ${DIR_PROJ}/results/sumstats_ldsc/${GRS_NAME}.sumstats.h2
