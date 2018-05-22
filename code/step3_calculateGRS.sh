#!/bin/bash/
# written by Lu Yi (lu.yi@ki.se)
# version5: 2018-05-14

# AIM: Perform clumping and generating PRS 


############################################################################
######### JOINING DISCOVERY RESULTS AND TARGET DATA TO GENERATE PRS ########
############################################################################

# Data required for running this script: 
# 1. cleaned reference dataset <- here 1KG EUR set in PLINK binary format 
# 2. cleaned discovery set GWAS results 
# 3. cleaned SNP list (& a list of dosage files & one fam file) in the target set!! 

# STEPs:
# STEP1: Check overlap SNPs and strand/allele consistency in discovery and target set 
# NOTE: Failing to do so, the SNPs with strand flip will be missed when generating the risk scores!

# STEP2: Clumping (r2<0.1 in 1MB window), 
# **forcing the SNPs in overlap.passORstrand.snps in, so that all clumped SNPs are in the target! 

# STEP3: Make score/pval file for clumped SNPs only, flip strand in score file for any clumped snps with strand issue

# STEP4: Generating PRS 

# STEP5: Formatting

# STEP6: Standardise the scores

############################################################################
#********** setting up script parameters *************

DIR_PROJ=$1

STUDY=$2

GRS_NAME=$3


# cleaned reference dataset in PLINK format:
REF_PLINK=${DIR_PROJ}/data/ref/1kg_p1v3_PLINK_cleaned/1kgEUR.noATCG.nomhc  # PLINK binary format

# cleaned discovery set GWAS results:
SUMSTAT_DIR=${DIR_PROJ}/data/sumstats/postqc
IN_SUMSTAT=${SUMSTAT_DIR}/${GRS_NAME}.qced.tsv

# genetic data directory
GENO_DIR=${DIR_PROJ}/data/geno/postqc/${STUDY}

# cleaned SNP list in the target set (including tab-delim SNP, A1, A2):
IN_TARGETSNP=${GENO_DIR}/postimp.SNPs
# & dosage file list in the target set (#, dosagefile):
IN_DOSELIST=${GENO_DIR}/dosefile.list
# & one fam file
IN_DOSEFAM=${GENO_DIR}/dose.fam

Intermediate_DIR=${DIR_PROJ}/intermediate
mkdir -p ${Intermediate_DIR}/${STUDY}_GRS_${GRS_NAME}

cd ${Intermediate_DIR}/${STUDY}_GRS_${GRS_NAME}

# clumped score & pval file
OUT_SCOREFILE=${GRS_NAME}.clumped.score
OUT_PVALFILE=${GRS_NAME}.clumped.pval

# installed PLINK 
PLINK=plink

############################################################################

echo -e "\nStart running the script to 1) perform LD clumping on discovery results of $GRS_NAME and 2) to generate its risk scores in $STUDY at `date`"

# STEP1: Check overlap SNPs and strand/allele consistency in discovery and target set 

echo -e "\nSTEP1. check overlap SNPs and strand/allele consistency in discovery and target set\n"

# make some empty files in case no such SNPs
touch overlap.pass.snps overlap.PROB.snps overlap.PROB.snps.alleleissue overlap.PROB.snps.strandissue 

awk -v n_overlap=0 -v n_fail=0 -v snp=SNP -v a1=A1 -v a2=A2 '
NR==FNR {a[$1]=$2$3}
NR!=FNR {
# first index column names in the sumstats 
if (FNR==1) {for (i=1; i<=NF; i++) {var[$i] = i} }
else {
# check overlap SNPs
if ($var[snp] in a) {
	# $var[snp] refers to the column with name "SNP"
	# $var[a1] & $var[a2] refers to the column with name "A1", "A2"
	# however, a[$var[snp]] refers to the two alleles in IN_TARGETSNP file
	n_overlap+=1
	# check strand and allele consistency	
	b1=$var[a1]$var[a2]; b2=$var[a2]$var[a1]
		if (b1==a[$var[snp]] || b2==a[$var[snp]]) { print $var[snp] > "overlap.pass.snps" }
		else {
		n_fail+=1
		print $var[snp],b1,a[$var[snp]] > "overlap.PROB.snps"
		}
	}
} 
}
END {print "Number of overlap SNPs in discovery and target set: " n_overlap "\n" "Among which, " n_fail " has either strand or allele inconsistency. Check the file: overlap.PROB.snps"}
' ${IN_TARGETSNP} ${IN_SUMSTAT}


# Separate strand and allele issue
awk '{
a1=substr($2,1,1); a2=substr($2,2,1); b1=substr($3,1,1); b2=substr($3,2,1); 
if (a1==b1 || a2==b1 || a1==b2 || a2==b1) { print $0 > "overlap.PROB.snps.alleleissue"} 
else {print $0 > "overlap.PROB.snps.strandissue" }
} ' overlap.PROB.snps

wc -l overlap.PROB.snps*

# for the SNPs with strand issue, add back in overlap.pass.snps (b/c can flip the strand)
awk '{print $1}' overlap.PROB.snps.strandissue > tmp
cat overlap.pass.snps tmp > overlap.passORstrand.snps
rm tmp


# STEP2: Clumping (r2<0.1 in 1MB window), **forcing the SNPs in overlap.passORstrand.snps in, so that all clumped SNPs are in the target! 
echo -e "\nSTEP2. Clumping (r2<0.1 in 1MB window), **forcing the SNPs in overlap.pass.snps in, so that all clumped SNPs are well imputed in the target!\n"

# before running clumping, also check the overlap snps with 1kg reference
${PLINK} \
 --bfile ${REF_PLINK} \
 --extract overlap.passORstrand.snps \
 --make-bed \
 --out tmpref

nsnps=`wc -l < tmpref.bim`
echo -e "\n${nsnps} SNPs overlapped in all three sets: discovery, target, and 1kg reference (phase1r3_2011.05).\n"


${PLINK} \
 --bfile tmpref \
 --clump ${IN_SUMSTAT} \
 --clump-field PVAL \
 --clump-p1 1 \
 --clump-p2 1 \
 --clump-r2 0.1 \
 --clump-kb 1000 \
 --out ${GRS_NAME}

rm tmpref.*

# STEP3: Make score/pval file for clumped SNPs only & flip strand 
echo -e "\nSTEP3: Make score/pval file for clumped SNPs only.\n"
awk -v out1=${OUT_SCOREFILE} -v out2=${OUT_PVALFILE} -v snp=SNP -v a1=A1 -v beta=BETA -v p=PVAL ' 
# The 3rd column in the output "${GRS_NAME}.clumped" are the clumped SNPs, extract these in the 2 results files
  NR==FNR {a[$3]++} 
  NR!=FNR {
# first index column names in the sumstats 
if (FNR==1) {for (i=1; i<=NF; i++) {var[$i] = i} }
 
# check overlap SNPs
if ($var[snp] in a) {

	# $var[snp] refers to the column with name "SNP"
	# $var[a1] refers to the column with name "A1"
	# $var[beta] is the BETA column
	# $var[p] is the PVAL column

# output score file should contain SNP, A1, BETA (beta|logOR)
print $var[snp], $var[a1], $var[beta] > out1
# output pvalue file should contain SNP, Pval 	
print $var[snp], $var[p] > out2
}
}' ${GRS_NAME}.clumped ${IN_SUMSTAT}  

# Flip strand (with effect stay the same) for any clumped snps with strand issue 
awk -v out=${OUT_SCOREFILE}.tmp -v n=0 '
NR==FNR {a[$1]++}
NR!=FNR {OFS="\t";
	if ($1 in a) {
		n+=1
		if ($2=="A") {print $1,"T",$3 > out}; 
		if ($2=="T") {print $1,"A",$3 > out}; 
		if ($2=="C") {print $1,"G",$3 > out}; 
		if ($2=="G") {print $1,"C",$3 > out}; 
		}
	else {print $1,$2,$3 > out}
	}
END {print "Flipped strand for " n " SNPs"}' overlap.PROB.snps.strandissue ${OUT_SCOREFILE}  

if test -f ${OUT_SCOREFILE}.tmp 
then mv ${OUT_SCOREFILE}.tmp ${OUT_SCOREFILE} 
fi

wc -l ${OUT_SCOREFILE} ${OUT_PVALFILE}

# record the number of clumped SNPs (rm header)
N1=`sed '1d' ${OUT_PVALFILE} | wc -l`


# STEP4: Generating PRS 
# when dosage files are used, risk scores will be the sum by default; add 'include-cnt' to know how many SNPs were counted in the risk scores.
echo -e "\nSTEP4: Generating PRS.\n"
echo -e "S1\t0.00\t1e-3\nS2\t0.00\t0.01\nS3\t0.00\t0.05\nS4\t0.00\t0.1\nS5\t0.00\t0.2\nS6\t0.00\t0.3\nS7\t0.00\t0.5\nS8\t0.00\t1" > pval.range

${PLINK} \
 --dosage ${IN_DOSELIST} list format=2 \
 --fam ${IN_DOSEFAM} \
 --score ${OUT_SCOREFILE} header include-cnt \
 --q-score-range pval.range ${OUT_PVALFILE} header \
 --out ${GRS_NAME}

# Test whether all of the clumped SNPs are used in generating risk scores (S8 with all SNPs)
N2=`awk 'NR > 1 {print $(NF-1)}' ${GRS_NAME}.S8.profile | sort | uniq` # given dosage data, should just be 1 value

if [ $N2 -eq $N1 ]
then echo -e "\nThe number of SNPs used to generate risk scores is the same as the number of clumped SNPs."
else echo -e "\nERROR: The number of SNPs used to generate risk scores DOES NOT EQUAL TO the number of clumped SNPs."
fi

# STEP5: Formatting
echo -e "\nSTEP5: Gathering all risk scores in ${GRS_NAME}.S1-8.profile.\n"
SETS="S1 S2 S3 S4 S5 S6 S7 S8"
awk 'BEGIN {OFS="\t"} NR==1 {print $1,$2,$3} NR > 1 {print $1,$2,$3}' ${GRS_NAME}.S1.profile > ${GRS_NAME}.profile.tmp
for SET in ${SETS}
	do
	awk -v set=${SET} 'NR == 1 {print set} NR > 1 {print $NF}' ${GRS_NAME}.${SET}.profile > tmp
	paste -d "\t" ${GRS_NAME}.profile.tmp tmp > tmp2
	mv tmp2 ${GRS_NAME}.profile.tmp
	rm tmp 
#  	gzip ${GRS_NAME}.${SET}.profile
done
mv ${GRS_NAME}.profile.tmp ${GRS_NAME}.S1-8.profile

awk 'BEGIN {OFS="\t"} 
{
if (NR==1) {$4="S1_0.001"; $5="S2_0.01"; $6="S3_0.05"; $7="S4_0.1"; $8="S5_0.2"; $9="S6_0.3"; $10="S7_0.5"; $11="S8_1"; print $0}
else {print $0} 
}' ${GRS_NAME}.S1-8.profile > tmp
mv tmp ${GRS_NAME}.S1-8.profile


# STEP6: Standardise the scores
echo -e "\nSTEP6: Standardizing risk scores in ${GRS_NAME}.S1-8.standarized.profile.\n"

bash ${DIR_PROJ}/code/standardiseGRS.sh ${GRS_NAME}.S1-8.profile ${GRS_NAME}.S1-8.standarized.profile 

# need to copy the output to the results folder
cp ${GRS_NAME}.S1-8.standarized.profile ${DIR_PROJ}/results/GRS/${STUDY}_${GRS_NAME}.S1-8.standarized.profile

# zipping intermediate files
gzip *

echo -e "\nCompleted at `date`"
