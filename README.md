# UKB-MRI-Preprocessing

This repository contains the code for the preprocessing pipeline used in the [Deep Unsupervised Anomaly Detection in Brain Imaging:
Large-Scale Benchmarking and Bias Analysis](https://github.com/AlexanderFrotscher/UAD-IMAG) publication. Please cite the mentioned publication when using this repository for your research. 

&nbsp;

## Output

The pipeline implements preprocessing for **structural** MRI and will generate skullstripped images that are coregistred (between individual modalities) and rigidly registered to the [SRI24](https://www.nitrc.org/projects/sri24) atlas. The skullstripping follows the [UKB pipeline](https://git.fmrib.ox.ac.uk/falmagro/UK_biobank_pipeline_v_1).
Additionally custom QC is implemented that follows [fsqc](https://github.com/Deep-MI/fsqc). Note that for this step [Freesurfer](https://surfer.nmr.mgh.harvard.edu/) aseg files are needed that have to be located in the /anat directory and transformed to the original/individual coordinate system and the .nii.gz file format for every individual. 
Anomaly masks (binary segmentations indicating anomaly/normal) are automatically handled correctly if they are named sub-ID_seg-lesion_mask.nii.gz.

## File Structure

To use this repository your datasets have to be in the [BIDS](https://bids.neuroimaging.io/index.html) format:

```
 ├── Dataset
    │   ├── sub-ID
    │   │   ├── anat
    │   │   │   ├── sub-ID_T1w.nii
    │   │   │   ├── sub-ID_T2w.nii
    │   │   │   ├── aseg.nii
    │   │   │   └── ...

```
Additionally a .csv file is needed that specifies which individuals to preprocess. The path to the subjects directory is needed.

```
/home/user/dataset/sub-ID/
/home/user/dataset/sub-ID2/
...
```

## How to use
I apologize that this repository is not well documented. This pipeline is setup to run on a HPC cluster that has [Python](https://www.python.org/) and [FSL](https://fsl.fmrib.ox.ac.uk/fsl/docs/) installed and uses the job scheduler and workload manager [Slurm](https://slurm.schedmd.com/overview.html).
Before using the pipeline check the [init_vars.sh](init_vars.sh) script and set all the needed (SRI24, MNI_mask, FSL) paths appropriately.
Additionally you need a T1w image for every subject or you will need to change the behaviour of the pipeline in [pipeline_struct.py](pipeline_struct.py). The pipeline will **NOT** handle multiple T1w images!
To run the pipeline use:

```
bash init_vars.sh path_to_csv.csv
```

This will submit a single job via Slurm for every individual with the [start_pipeline.sh](start_pipeline.sh) script. The pipeline needs roughly 30 minutes to finish one individual. They will be stored in a new directory named dataset_processed that contains a data and logs directory. 
