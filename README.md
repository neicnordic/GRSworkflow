# GRSworkflow for use case 1.1

## Instructions for setting up and testing the serial workflow  
Steps:  
1. Clone this repository `git clone https://github.com/oskarvid/GRSworkflow.git`  
2. Run `./singularity/BuildSingularity.sh` to build the singularity image
3. Download the "Testdata.tar.gz" archive from https://ki.box.com/s/ct9pibmwu38z0jgfqvtyqr4et07niyad  
4. Untar the Testdata.tar.gz with `tar -zxvf Testdata.tar.gz` and put the `data` and `tesdata` directories in the `GRSworkflow` directory  
5. Run `./scripts/dl-references.sh`
6. Run `./scripts/start-bash-pipeline.sh` to test the pipeline

## Step by step instructions to adapt the parallelized workflow to your local slurm setup  
1. Change branches to the `optimized` branch  
2. Copy the `scripts/RunTsdSbatchPipeline.sh` script to `scripts/RunNAMESbatchPipeline.sh` and change NAME to the name of your system.  
3. Open the `scripts/RunNAMESbatchPipeline.sh` file with a text editor and begin by changing the directory path on row 10 to one that points to the absolute path of your `GRSworkflow/input-definitions` directory.  
4. Now change the path on row 17 to point to the absolute path of your GRSworkflow directory.  
5. That's it for the `scripts/RunNAMESbatchPipeline.sh` script, you can now save and close it.  
6. Proceed by opening the `scripts/step1.sbatch` script with a text editor.  
7. Begin by changing the account name in the --account flag to your own account name, also edit the `--mem-per-cpu` flag to something that suits your system. Then edit or remove the `source` row as well as the two `module` rows as necessary.  
8. On row 36 you need to edit the mount points so that they are correct for your specific system. The mount points (the -B and --home flags) from the original script only works for TSD, it's possible you don't need the --home flag at all for instance.  
9. Repeat step 7 and 8 for `scripts/step2.sbatch` and `scripts/step3.sbatch`.  
10. You are now ready to test the pipeline for the first time, navigate to the GRSworkflow folder if you're not already there, and run the `./scripts/RunNAMESbatchPipeline.sh` script that you created and edited earlier and use `squeue` and `qsumm` to monitor the execution of the individual jobs.  
You should see an output similar to this when you run squeue:  
![Image of squeue cli output](https://github.com/neicnordic/GRSworkflow/blob/optimized/.squeue.png)
The image shows eight jobs being queued in slurm, four of them are marked with "Priority" and will run as soon as it's their turn in the queue. The ones marked with "Dependency" will run once the jobs that are marked with "Priority" that they depend on have finished.  
This particular workflow has three steps, step 1 and step 2 run independently of each other, and can therefore run simultaneously. But step 3 depends on output files from step 1 and step 2. It is the step 1 and step 2 jobs that are marked with "Priority", and step 3 jobs are marked with "Dependency".  

## Challenges
1. Adapt the workflow to Moab/Torque to achieve a similar level of parallelization.

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
 * Done

7. Include launcher scripts in the container (maybe as singularity apps? As in `singularity run --app submit-jobs --nodes 10 --time 160h`, or even `singularity run --app run-on-mosler --nodes 10 --time 160h` or similar).  

## Known issues
1. When the docker image is built there’s an error message saying “Failed building wheel for bitarray” but then it continues and says “Successfully installed bitarray-0.8.1 etc...” and it seems to run as it should. This should probably be fixed whether it affects the functionality or not.
