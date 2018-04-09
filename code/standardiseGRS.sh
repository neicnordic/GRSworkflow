#!/bin/bash

INPUT=$1
OUTPUT=$2

R --no-save  << EOF
read.table("$INPUT",header=T)-> data
head(data)
data[,c(4:11)] -> GRS
apply(GRS, 2, scale) -> GRS.standardized
head(cbind(data[,c(1:3)],GRS.standardized))

write.table(cbind(data[,c(1:3)],GRS.standardized),"$OUTPUT",sep="\t",row.names=F,col.names=T,quote=F)

q()
EOF