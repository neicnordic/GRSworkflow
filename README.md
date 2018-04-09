# GRSworkflow for use case 1.1

## Instructions for setting up and testing the workflow  
Steps:  
1. Clone this repository `git clone https://github.com/oskarvid/GRSworkflow`  
2. Run `sh singularity/BuildSingularity.sh` to build the singularity image  
3. Download the "Testdata.tar.gz" archive from https://app.box.com/file/286447778176  
4. Untar the Testdata.tar.gz with `tar -zxvf Testdata.tar.gz` and put the `data` and `tesdata` directories in the `GRSworkflow` directory  
5. Run `sh scripts/dl-references.sh`  
6. Run `sh scripts/start-bash-pipeline.sh` to test the pipeline  

## Challenges
1. In step2_preparingtarget_Ricopili.sh there’s an if-else statement that checks whether the info/bgs/qc1 folders exist in that order, and if info exists, then bgs or qc1 aren’t used for anything. But if info doesn’t exist, but bgs does, qc1 isn’t used, and vice versa for qc1. If none of them exists then step3.sh will fail. I don’t know if checking this is easily doable in nextflow, hence it might make sense to just use the bash pipeline since it works already.  
2. If we go forward with the bash pipeline we can solve parallel sample execution with the built in parallelization options in e.g slurm on TSD.  

## Possible improvements and changes
1. plink can use the flag “--threads” for parallelization.  
2. Nextflow?  
 * Probably not

3. Detection of existing files/output to avoid wasting time on rerunning steps that don’t need to be rerun.  
4. If there are reference files in data/ref/1kg then proceed with step1.sh, else stop.  
 * Done  

5. If there are three output files per sample in data/geno/fastqc and one tsv per sample in data/sumstat/fastqc then run step3.sh, else stop.  
 * Done

6. Cluster support for parallel execution of multiple input files.  

7. Include launcher scripts in the container (maybe as singularity apps? As in `singularity run --app submit-jobs --nodes 10 --time 160h`, or even `singularity run --app run-on-mosler --nodes 10 --time 160h` or similar).  

## Known issues
1. When the docker image is built there’s an error message saying “Failed building wheel for bitarray” but then it continues and says “Successfully installed bitarray-0.8.1 etc...” and it seems to run as it should. This should probably be fixed whether it affects the functionality or not.
