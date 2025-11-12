#!/bin/bash
#SBATCH --job-name=fsl_n
#SBATCH --output=%x_%j.out
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=1
#SBATCH --mem-per-cpu=4G
#SBATCH --time=7:00:00
#SBATCH --partition=cpu

# Subject name passed as argument
subj=$1

# Check if the output directory is provided as an argument
if [ -z "$2" ]; then
  echo "Output directory not specified. Using current directory."
  OUTDIR="."
else
  OUTDIR="$2"
  mkdir -p $OUTDIR  # Create the directory if it doesn't exist
fi

OUTPUT_FILE="${SLURM_JOB_NAME}_${SLURM_JOB_ID}.out"

# Run pipeline for the subject
python "$pipeDIR/main_pipeline.py" $subj

cp $OUTPUT_FILE $OUTDIR
rm $OUTPUT_FILE
