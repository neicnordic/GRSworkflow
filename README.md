# GRSworkflow for use case 1.1

## Instructions for setting up and testing the workflow  
Steps:
1. Clone this repository `git clone https://github.com/oskarvid/GRSworkflow`  
2. Run "sh scripts/dl-references.sh"  
3. Run `sh scripts/BuildSingularity.sh` to build the singularity image  
4. Download the "Testdata.tar.gz" archive from https://app.box.com/file/286447778176  
5. Untar the Testdata.tar.gz with `tar -zxvf Testdata.tar.gz` and put the `data` and `tesdata` directories in the `GRSworkflow` directory  
6. Run `sh scripts/start-bash-pipeline.sh` to test the pipeline  
