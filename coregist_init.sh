#!/bin/bash
#
#
cd $1/anat
T1=$(find . -type f -name '*T1w*' | cut -c 3-)
if [ `${FSLDIR}/bin/imtest ${T1}` = 0 ] ; then
  echo No T1 found!
  exit
else
    #Apply re-orientation
    ${FSLDIR}/bin/fslreorient2std $T1 $2/anat/$T1
fi
patient_id=$(echo "$T1" | sed 's/_T1w\.nii\.gz//')
T2=$(find . -type f -name '*T2w*' | cut -c 3-)
#Warping for T2
if [ `${FSLDIR}/bin/imtest ${T2}` = 0 ] ; then
  echo "WARNING: No T2 in $1"
else
    #Take T2 to T1
    ${FSLDIR}/bin/fslreorient2std $T2 $2/anat/T2_orient
    ${FSLDIR}/bin/flirt -in $2/anat/T2_orient -ref $2/anat/$T1 -out $2/anat/"$patient_id""_T2w.nii.gz" -omat $2/anat/T2_to_T1.mat -dof 6
fi
PD=$(find . -type f -name '*PDw*' | cut -c 3-)
#Warping for PD
if [ `${FSLDIR}/bin/imtest ${PD}` = 0 ] ; then
  echo "WARNING: No PD in $1"
else
    #Take PD to T1
    ${FSLDIR}/bin/fslreorient2std $PD $2/anat/PD_orient
    ${FSLDIR}/bin/flirt -in $2/anat/PD_orient -ref $2/anat/$T1 -out $2/anat/"$patient_id""_PDw.nii.gz" -omat $2/anat/PD_to_T1.mat -dof 6
fi
FLAIR=$(find . -type f -name '*FLAIR*' | cut -c 3-)
#Warping for FLAIR
if [ `${FSLDIR}/bin/imtest ${FLAIR}` = 0 ] ; then
  echo "WARNING: No FLAIR in $1"
else
    #Take FLAIR to T1
    ${FSLDIR}/bin/fslreorient2std $FLAIR $2/anat/FLAIR_orient
    ${FSLDIR}/bin/flirt -in $2/anat/FLAIR_orient -ref $2/anat/$T1 -out $2/anat/"$patient_id""_FLAIR.nii.gz" -omat $2/anat/FLAIR_to_T1.mat -dof 6
fi
SEG=$(find . -type f -name '*aseg*' | cut -c 3-)
#Warping for segmentation
if [ `${FSLDIR}/bin/imtest ${SEG}` = 0 ] ; then
  echo "WARNING: No segmentation in $1"
else
    #Take segmentation standard
    ${FSLDIR}/bin/fslreorient2std $SEG $2/anat/"$patient_id""_seg-surf_mask.nii.gz"
fi
mask=$(find . -type f -name '*lesion_mask*' | cut -c 3-)
#Warping for lesion mask
if [ `${FSLDIR}/bin/imtest ${mask}` = 0 ] ; then
  echo "WARNING: No lesion mask in $1"
else
    #Take lesion mask to  standard, be careful about the origin of the mask, FLAIR, T1, if mask from FLAIR, this will not do it?
    ${FSLDIR}/bin/fslreorient2std $mask $2/anat/"$patient_id""_seg-anomaly_mask.nii.gz"
fi
#rm *_orient.nii.gz