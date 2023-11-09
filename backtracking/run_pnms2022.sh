#!/bin/bash
#SBATCH --partition=compute # Queue selection
#SBATCH --job-name=pnms2022 # Job name
#SBATCH --mail-type=END,FAIL # Mail events (BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=chernandez@whoi.edu # Where to send mail
#SBATCH -N 1
#SBATCH --ntasks=8 # Run on 7 cores
#SBATCH --mem=20480 # Job memory request
#SBATCH --time=01:00:00 # Time limit hrs:min:sec
#SBATCH --output=cms_pnms2022_testrun_%j.log # Standard output/error
echo "Starting Run"
pwd; hostname; date
module load gcc/9.3.1
module load netcdf/gcc/4.6.1 openmpi/gcc

mpirun -np 8 cms pnms2022

echo "Finish Run" 
date

cp -r expt_pnms2022 /vortexfs1/home/chernandez/pnms/test/
cp -r input_pnms2022 /vortexfs1/home/chernandez/pnms/test/
 
echo "Successfully copied to home directory"
