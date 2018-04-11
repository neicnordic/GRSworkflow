#!/bin/sh

date && \
time singularity exec -B testdata:`pwd`/data/geno/raw \
singularity/GRSworkflow.simg \
bash scripts/RunBashPipeline.sh
