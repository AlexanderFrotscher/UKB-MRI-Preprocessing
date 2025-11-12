#!/bin/bash
#
#
cd $1/anat
T1=$(find . -type f -name '*T1w*' | grep -v '_ce-Gd_T1w.nii.gz' | cut -c 3-)
if [ `${FSLDIR}/bin/imtest ${T1}` = 0 ] ; then
  echo No skullstripped T1 found!
  exit
fi
patient_id=$(echo "$T1" | sed 's/_T1w\.nii\.gz//')
${FSLDIR}/bin/fslreorient2std $T1 $2/anat/T1_orient
cd $2/anat
#Calculate Rigid Transformation
${FSLDIR}/bin/flirt -in T1_orient -ref $SRI24_brain -out T1_tmp -omat T1_to_T1_SRI.mat -dof 6
${FSLDIR}/bin/flirt -in T1_orient -ref $SRI24_brain -applyxfm -init T1_to_T1_SRI.mat -out T1_SRI.nii.gz -interp trilinear
cd $1/anat
T2=$(find . -type f -name '*T2w*' | cut -c 3-)
#Warping for T2
if [ `${FSLDIR}/bin/imtest ${T2}` = 0 ] ; then
  echo "WARNING: No T2 in $1"
else
    # Take T2 to MNI
    ${FSLDIR}/bin/fslreorient2std $T2 $2/anat/T2_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in T2_orient -ref T1_SRI -out "$patient_id""_T2w.nii.gz" -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
cd $1/anat
PD=$(find . -type f -name '*PDw*' | cut -c 3-)
#Warping for PD
if [ `${FSLDIR}/bin/imtest ${PD}` = 0 ] ; then
  echo "WARNING: No PD in $1"
else
    # Take PD to MNI
    ${FSLDIR}/bin/fslreorient2std $PD $2/anat/PD_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in PD_orient -ref T1_SRI -out "$patient_id""_PDw.nii.gz" -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
cd $1/anat
FLAIR=$(find . -type f -name '*FLAIR*' | cut -c 3-)
#Warping for FLAIR
if [ `${FSLDIR}/bin/imtest ${FLAIR}` = 0 ] ; then
  echo "WARNING: No FLAIR in $1"
else
    # Take FLAIR to MNI
    ${FSLDIR}/bin/fslreorient2std $FLAIR $2/anat/FLAIR_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in FLAIR_orient -ref T1_SRI -out "$patient_id""_FLAIR.nii.gz" -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
cd $1/anat
T1CE=$(find . -type f -name '*ce-Gd*' | cut -c 3-)
#Warping for T1CE
if [ `${FSLDIR}/bin/imtest ${T1CE}` = 0 ] ; then
  echo "WARNING: No T1CE in $1"
else
    # Take T1CE to MNI
    ${FSLDIR}/bin/fslreorient2std $T1CE $2/anat/T1CE_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in T1CE_orient -ref T1_SRI -out "$patient_id""_ce-Gd_T1w.nii.gz" -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
cd $1/anat
SEG=$(find . -type f -name '*aseg*' | cut -c 3-)
#Warping for segmentation
if [ `${FSLDIR}/bin/imtest ${SEG}` = 0 ] ; then
  echo "WARNING: No aseg file in $1"
else
    #Take segmentation to MNI
    ${FSLDIR}/bin/fslreorient2std $SEG $2/anat/aseg_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in aseg_orient -ref T1_SRI -out "$patient_id""_seg-surf_mask.nii.gz" -applyxfm -init T1_to_T1_SRI.mat -interp nearestneighbour 
fi
cd $1/anat
mask=$(find . -type f -name '*lesion_mask*' | cut -c 3-)
#Warping for lesion_mask
if [ `${FSLDIR}/bin/imtest ${mask}` = 0 ] ; then
  echo "WARNING: No lesion_mask file in $1"
else
    #Take mask to MNI
    ${FSLDIR}/bin/fslreorient2std $mask $2/anat/mask
    cd $2/anat
    ${FSLDIR}/bin/flirt -in mask -ref T1_SRI -out "$patient_id""_seg-anomaly_mask.nii.gz" -applyxfm -init T1_to_T1_SRI.mat -interp nearestneighbour 
fi
cd $2/anat
rm *_orient.nii.gz
rm *.mat
rm *_tmp.nii.gz
mv T1_SRI.nii.gz "$patient_id""_T1w.nii.gz"
