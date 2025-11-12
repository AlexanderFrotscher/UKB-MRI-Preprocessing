#!/bin/bash
#
#
cd $1/anat
T1=$(find . -type f -name '*T1w*' | cut -c 3-)
if [ `${FSLDIR}/bin/imtest ${T1}` = 0 ] ; then
  echo No skullstripped T1 found!
  exit
fi
#patient_id=$(echo "$T1" | sed 's/_T1w\.nii\.gz//')
#Calculate Rigid Transformation
${FSLDIR}/bin/flirt -in $T1 -ref $SRI24_brain -out T1_SRI -omat T1_to_T1_SRI.mat -dof 6
${FSLDIR}/bin/flirt -in $T1 -ref $SRI24_brain -out $T1 -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
T2=$(find . -type f -name '*T2w*' | cut -c 3-)
#Warping for T2
if [ `${FSLDIR}/bin/imtest ${T2}` = 0 ] ; then
  echo "WARNING: No T2 in $1"
else
    #Take T2 to MNI
    ${FSLDIR}/bin/flirt -in $T2 -ref $T1 -out $T2 -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
PD=$(find . -type f -name '*PDw*' | cut -c 3-)
#Warping for PD
if [ `${FSLDIR}/bin/imtest ${PD}` = 0 ] ; then
  echo "WARNING: No PD in $1"
else
    # Take PD to MNI
    ${FSLDIR}/bin/flirt -in $PD -ref $T1 -out $PD -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
FLAIR=$(find . -type f -name '*FLAIR*' | cut -c 3-)
#Warping for FLAIR
if [ `${FSLDIR}/bin/imtest ${FLAIR}` = 0 ] ; then
  echo "WARNING: No FLAIR in $1"
else
    #Take FLAIR to MNI
    ${FSLDIR}/bin/flirt -in $FLAIR -ref $T1 -out $FLAIR -applyxfm -init T1_to_T1_SRI.mat -interp trilinear
fi
SEG=$(find . -type f -name '*surf_mask*' | cut -c 3-)
#Warping for segmentation
if [ `${FSLDIR}/bin/imtest ${SEG}` = 0 ] ; then
  echo "WARNING: No aseg file in $1"
else
    #Take segmentation to MNI
    ${FSLDIR}/bin/flirt -in $SEG -ref $T1 -out $SEG -applyxfm -init T1_to_T1_SRI.mat -interp nearestneighbour
    rm aseg.nii.gz 
fi
mask=$(find . -type f -name '*anomaly_mask*' | cut -c 3-)
#Warping for anomaly mask
if [ `${FSLDIR}/bin/imtest ${mask}` = 0 ] ; then
  echo "WARNING: No anomaly mask file in $1"
else
    #Take anomaly mask to MNI
    ${FSLDIR}/bin/flirt -in $mask -ref $T1 -out $mask -applyxfm -init T1_to_T1_SRI.mat -interp nearestneighbour
    rm mask.nii.gz 
fi
rm T1_SRI.nii.gz
rm *.mat