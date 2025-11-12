#!/bin/bash

module load fsl

mapfile -t subj_arr < $1  # file of subjects ID

#SETUP FSL
export FSLDIR=/mnt/lmod/software/fsl #TO BE MODIFIED BY USER
. $FSLDIR/etc/fslconf/fsl.sh
export FSLCONFDIR=${FSLDIR}/config
export FSLOUTPUTTYPE="NIFTI_GZ"

export ROBEXDIR="/home/afrotscher/ROBEX"


#ENV VARIABLES FOR BIOBANK
export pipeDIR="/home/afrotscher/pipeline"                             #TO BE MODIFIED BY USER
export SRI24="/home/afrotscher/sri24_spm8/templates/T1.nii"
export SRI24_brain="/home/afrotscher/sri24_spm8/templates/T1_brain.nii"
export MNI_mask_dil="/home/afrotscher/pipeline/MNI152_T1_1mm_brain_mask_dil_GD7.nii.gz"
export MNI_mask="/home/afrotscher/pipeline/MNI152_T1_1mm_brain_mask.nii.gz"

first_subj="${subj_arr[0]}"
parent_dir="$(dirname "$first_subj")"
mkdir -p "$parent_dir""_processed/"
mkdir -p "$parent_dir""_processed/logs/"
mkdir -p "$parent_dir""_processed/data/"
export LOGS="$parent_dir""_processed/logs/"

# Loop through each subject
for subj in "${subj_arr[@]}"; do
    # Launch SLURM job for processing
    subj_directory="$(basename "$subj")"
    if [ ! -d "$parent_dir""_processed/data/$subj_directory" ]; then
      sbatch start_pipeline.sh $subj $LOGS/$subj_directory
    else
      echo "$subj_directory was already processed and is skipped."
    fi
done


