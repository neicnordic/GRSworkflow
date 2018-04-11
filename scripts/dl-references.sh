#!/bin/sh

if [ ! -d "data/ref/ldsc" ];
	then
		mkdir data/ref/ldsc
		cd data/ref/ldsc
		wget https://data.broadinstitute.org/alkesgroup/LDSCORE/eur_w_ld_chr.tar.bz2
		tar xf eur_w_ld_chr.tar.bz2
		rm eur_w_ld_chr.tar.bz2 # delete once extracted the folder
		cd -
fi
