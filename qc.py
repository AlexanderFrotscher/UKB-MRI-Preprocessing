__author__ = "Alexander Frotscher"
__email__ = "alexander.frotscher@student.uni-tuebingen.de"


import logging_tool as LT
import os
import numpy as np
import nibabel as nib
from math import sqrt


def save_nii(path, img, affine, dtype):
        nib.save(nib.Nifti1Image(img.astype(dtype), affine), path)


def qc(subject, fileConfig, output):
    logger = LT.initLogging(__file__, subject, output)
    logDir = logger.logDir
    subjDir = logger.subjDir
    mri_t1 = fileConfig["T1w"][0]
    name_t1 = mri_t1.replace("\\", "/").split("/")[-1:][0]
    name = name_t1.split("_T1w")[0]
    img_path = f"{subjDir}/anat/{name_t1}"
    seg_path = f"{subjDir}/anat/{name}_seg-surf_mask.nii.gz"

    img = np.asarray(nib.load(img_path).dataobj, dtype=float)
    seg = np.asarray(nib.load(seg_path).dataobj, dtype=np.int32)
    my_affine = nib.load(seg_path).affine

    # set values in segmentation that do not belong to the brain to zero 
    x, y, z = np.where(img == 0)
    seg[x, y, z] = 0
    save_nii(seg_path,seg,my_affine,dtype="short")

    # Create 3D binary data where the white matter locations are encoded with 1, all the others with zero
    b_wm_data = np.zeros(img.shape)

    # The following keys represent the white matter labels in the aparc+aseg image
    wm_labels = [2, 41, 7, 46, 251, 252, 253, 254, 255, 77, 78, 79]

    # Find the wm labels in the aseg image and set the locations in the binary image to one
    for i in wm_labels:
        x, y, z = np.where(seg == i)
        b_wm_data[x, y, z] = 1

    # Computation of the SNR of the white matter
    x, y, z = np.where(b_wm_data == 1)
    signal_wm = img[x, y, z]
    signal_wm_mean = np.mean(signal_wm)
    signal_wm_std = np.std(signal_wm)
    wm_snr = signal_wm_mean / signal_wm_std
    num_wm = np.sum(b_wm_data)
    logger.info("White matter signal to noise ratio: " + "{:.4}".format(wm_snr))

    # Create 3D binary data where the gray matter locations are encoded with 1, all the others with zero
    b_gm_data = np.zeros(img.shape)

    # The following keys represent the gray matter labels in the aseg image
    gm_labels = [3, 42]

    # Find the gm labels in the aseg image and set the locations in the binary image to one
    for i in gm_labels:
        x, y, z = np.where(seg == i)
        b_gm_data[x, y, z] = 1

    # Computation of the SNR of the gray matter
    x, y, z = np.where(b_gm_data == 1)
    signal_gm = img[x, y, z]
    signal_gm_mean = np.mean(signal_gm)
    signal_gm_std = np.std(signal_gm)
    gm_snr = signal_gm_mean / signal_gm_std
    num_gm = np.sum(b_gm_data)
    logger.info("Gray matter signal to noise ratio: " + "{:.4}".format(gm_snr))

    mask = np.zeros_like(img)
    x, y, z = np.where(img != 0)
    mask[x, y, z] = 1
    n_vox = np.sum(mask)
    mu_fg = np.mean(img[mask == 1])
    sigma_fg = np.std(img[mask==1])
    snr =  float(mu_fg / (sigma_fg * sqrt(n_vox / (n_vox - 1))))
    logger.info("Signal to noise ratio equals: " + "{:.4}".format(snr))

    # Calculate the maximum value of the EFC (which occurs any time all
    # voxels have the same value)
    efc_max = 1.0 * n_vox * (1.0 / np.sqrt(n_vox)) * np.log(1.0 / np.sqrt(n_vox))

    # Calculate the total image energy
    b_max = np.sqrt((img[mask == 1] ** 2).sum())

    efc = round(float((1.0 / efc_max)* np.sum((img[mask == 1] / b_max) * np.log((img[mask == 1] + 1e-16) / b_max))),4)
    logger.info("EFC equals: " + "{:.4}".format(efc))

    cjv = float((signal_wm_std + signal_gm_std) / abs(signal_wm_mean - signal_gm_mean))
    logger.info("Coefficient of joint variation equals: " + "{:.4}".format(cjv))

    subj_id = name.split('_')[0].split('-')[1]
    snr = round(snr,4)
    cjv = round(cjv,4)
    wm_snr = round(wm_snr,4)
    gm_snr = round(gm_snr,4)
    # write out the TSV
    with open(f"{logDir}/qc.tsv", "w") as file:
        file.write(f'ID\tSNR\tWM-SNR\tGM-SNR\tEFC\tCJV\tNum-WM\tNum-GM\n{subj_id}\t{snr}\t{wm_snr}\t{gm_snr}\t{efc}\t{cjv}\t{num_wm}\t{num_gm}\n')


