#!/bin/bash

#set -o xtrace

trap usage ERR SIGKILL SIGINT

# Function that simplifies the rsync command
rprog () {
	rsync --progress -ah $@
}

usage () {
	echo "Usage: /tsd/shared/bioinformatics/workflows/GRSworkflow/scripts/copy-workflow.sh -d /path/to/where/you/want/to/copy/the/workflow -t"
	echo "-d: This flag is used to define where you want to copy the GRSworkflow directory"
	echo "-t: Optional: This flag is used to also transfer and automatically set up the toy data and reference files"
	exit
}

# Flag that is changed to true if the toy data is desired
TOYDATA=false

# Check what flags were set on the command line
while getopts 'd:ht' flag; do
	case "${flag}" in
	d)
		d=${OPTARG}
		if [[ ! -d /"${d}" ]]; then
			usage
		else
			DEST="${d%/}"
		fi
		;;
	t)
		t=${OPTARG}
		TOYDATA=true
		;;
	h)
		h=${OPTARG}
		usage
		;;
	*)
		usage
		;;
	esac
done

# If the -d flag is not provided a directory path the $DEST variable is empty and the script is terminated after the usage function is run
if [[ -z $DEST ]]; then
	echo "The -d flag and a file path must be used"
	usage
fi

# Copy the GRSworkflow directory to the desired destination
rprog /tsd/shared/bioinformatics/workflows/GRSworkflow $DEST

# Run this if the -t flag is used to copy and set up all toy data and reference files
if [[ $TOYDATA == true ]]; then
	rprog /tsd/shared/bioinformatics/reference-data/GRSworkflow/GRSdata.tar.gz $DEST/GRSworkflow
	cd $DEST/GRSworkflow
	tar -zxvf GRSdata.tar.gz
	rprog Testdata/data .
	rprog Testdata/testdata/ data/geno/raw

	if [ ! -d "data/ref/ldsc" ]; then
		mkdir -p data/ref/ldsc
		rprog eur_w_ld_chr data/ref/ldsc
	fi

	rm -r GRSdata.tar.gz Testdata eur_w_ld_chr
fi

#All done!
echo "All done!"
