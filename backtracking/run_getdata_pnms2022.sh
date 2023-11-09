#!/bin/bash
#SBATCH --partition=compute # Queue selection
#SBATCH --job-name=getdata_marlin # Job name
#SBATCH --mail-type=END,FAIL # Mail events (BEGIN, END, FAIL, ALL)
#SBATCH --mail-user=chernandez@whoi.edu # Where to send mail
#SBATCH -N 1
#SBATCH --ntasks=1 # Run on 1 cores
#SBATCH --mem=20480 # Job memory request
#SBATCH --time=01:00:00 # Time limit hrs:min:sec
#SBATCH --output=cms_pnms_getdata_%j.log # Standard output/error
echo "Starting Run"
pwd; hostname; date
module load gcc/9.3.1
module load netcdf/gcc/4.6.1 openmpi/gcc

./getdata pnms2022 1
# mpirun -np 7 cms pipa2016
./getdata pnms2022 1

./getdata pnms2022 1

./getdata pnms2022 1

echo "Finished getting data" 
date

