#!/bin/bash
#
#
cd $1/anat
T1=$(find . -type f -name '*T1w.nii.gz' | cut -c 3-)
if [ `${FSLDIR}/bin/imtest ${T1}` = 0 ] ; then
  echo No T1 found!
  exit
fi
#Apply re-orientation
patient_id=$(echo "$T1" | sed 's/_T1w\.nii\.gz//')
${FSLDIR}/bin/fslreorient2std $T1 $2/anat/"$patient_id""_T1w.nii.gz"
cd $2/anat
head_top=`${FSLDIR}/bin/robustfov -i "$patient_id""_T1w.nii.gz" | grep -v Final | head -n 1 | awk '{print $5}'`
${FSLDIR}/bin/fslmaths "$patient_id""_T1w.nii.gz" -roi 0 -1 0 -1 $head_top 170 0 1 T1_tmp
#Run a (Recursive) brain extraction on the roi
${FSLDIR}/bin/bet T1_tmp T1_tmp_brain -R

#Reduces the FOV of T1 by calculating a registration from T1_tmp_brain to ssref and applies it to T1
${FSLDIR}/bin/standard_space_roi T1_tmp_brain T1_tmp2 -maskNONE -ssref $FSLDIR/data/standard/MNI152_T1_1mm_brain -altinput "$patient_id""_T1w.nii.gz" -d

#Generate the actual affine from the orig volume to the cut version we have now and combine it to have an affine matrix from orig to MNI
${FSLDIR}/bin/flirt -in T1_tmp2 -ref "$patient_id""_T1w.nii.gz" -omat T1_to_T1_orig.mat -schedule $FSLDIR/etc/flirtsch/xyztrans.sch 
${FSLDIR}/bin/convert_xfm -omat T1_orig_to_T1.mat -inverse T1_to_T1_orig.mat
${FSLDIR}/bin/convert_xfm -omat T1_to_MNI_linear.mat -concat T1_tmp2_tmp_to_std.mat T1_to_T1_orig.mat

#Non-linear registration to MNI using the previously calculated alignment
${FSLDIR}/bin/fnirt --in=T1_tmp2 --ref=$FSLDIR/data/standard/MNI152_T1_1mm --aff=T1_to_MNI_linear.mat \
  --config=$pipeDIR/fnirt_cnf.cnf --refmask=$MNI_mask_dil \
  --logout=NonlinearReg.txt --cout=T1_to_MNI_warp_coef --fout=T1_to_MNI_warp \
  --jout=T1_to_MNI_warp_jac --iout=T1_brain_to_MNI.nii.gz --interp=spline


#Create brain mask
${FSLDIR}/bin/invwarp --ref=T1_tmp2 -w T1_to_MNI_warp_coef -o T1_to_MNI_warp_coef_inv
${FSLDIR}/bin/applywarp --rel --interp=nn --in=$MNI_mask --ref=T1_tmp2 -w T1_to_MNI_warp_coef_inv -o brain_mask
${FSLDIR}/bin/fslmaths T1_tmp2 -mul brain_mask T1_brain
cd $1/anat
T2=$(find . -type f -name '*T2w.nii.gz' | cut -c 3-)
#Warping for T2
if [ `${FSLDIR}/bin/imtest ${T2}` = 0 ] ; then
  echo "WARNING: No T2 in $1"
else
    #Take T2 to T1 and apply brain mask
    ${FSLDIR}/bin/fslreorient2std $T2 $2/anat/T2_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in T2_orient -ref "$patient_id""_T1w.nii.gz" -out T2_tmp -omat T2_to_T1.mat -dof 6
    ${FSLDIR}/bin/convert_xfm -omat T2_tmp.mat -concat T1_orig_to_T1.mat  T2_to_T1.mat
    ${FSLDIR}/bin/flirt -in T2_orient -ref T1_brain -refweight brain_mask -nosearch -init T2_tmp.mat -omat T2_orig_to_T2.mat -dof 6 -applyxfm -out T2_tmp2
    ${FSLDIR}/bin/fslmaths T2_tmp2 -mul brain_mask T2_brain
    mv T2_brain.nii.gz "$patient_id""_T2w.nii.gz"
fi
cd $1/anat
PD=$(find . -type f -name '*PDw.nii.gz' | cut -c 3-)
#Warping for PD
if [ `${FSLDIR}/bin/imtest ${PD}` = 0 ] ; then
  echo "WARNING: No PD in $1"
else
    #Take PD to T1 and apply brain mask
    ${FSLDIR}/bin/fslreorient2std $PD $2/anat/PD_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in PD_orient -ref "$patient_id""_T1w.nii.gz" -out PD_tmp -omat PD_to_T1.mat -dof 6
    ${FSLDIR}/bin/convert_xfm -omat PD_tmp.mat -concat T1_orig_to_T1.mat PD_to_T1.mat
    ${FSLDIR}/bin/flirt -in PD_orient -ref T1_brain -refweight brain_mask -nosearch -init PD_tmp.mat -omat PD_orig_to_PD.mat -dof 6 -applyxfm -out PD_tmp2
    ${FSLDIR}/bin/fslmaths PD_tmp2 -mul brain_mask PD_brain
    mv PD_brain.nii.gz "$patient_id""_PDw.nii.gz"
fi
cd $1/anat
FLAIR=$(find . -type f -name '*FLAIR.nii.gz' | cut -c 3-)
#Warping for FLAIR
if [ `${FSLDIR}/bin/imtest ${FLAIR}` = 0 ] ; then
  echo "WARNING: No FLAIR in $1"
else
    #Take FLAIR to T1 and apply brain mask
    ${FSLDIR}/bin/fslreorient2std $FLAIR $2/anat/FLAIR_orient
    cd $2/anat
    ${FSLDIR}/bin/flirt -in FLAIR_orient -ref "$patient_id""_T1w.nii.gz" -out FLAIR_tmp -omat FLAIR_to_T1.mat -dof 6
    ${FSLDIR}/bin/convert_xfm -omat FLAIR_tmp.mat -concat T1_orig_to_T1.mat FLAIR_to_T1.mat
    ${FSLDIR}/bin/flirt -in FLAIR_orient -ref T1_brain -refweight brain_mask -nosearch -init FLAIR_tmp.mat -omat FLAIR_orig_to_FLAIR.mat -dof 6 -applyxfm -out FLAIR_tmp2
    ${FSLDIR}/bin/fslmaths FLAIR_tmp2 -mul brain_mask FLAIR_brain
    mv FLAIR_brain.nii.gz "$patient_id""_FLAIR.nii.gz"
fi
cd $1/anat
SEG=$(find . -type f -name '*aseg*' | cut -c 3-)
#Warping for segmentation
if [ `${FSLDIR}/bin/imtest ${SEG}` = 0 ] ; then
  echo "WARNING: No segmentation in $1"
else
    #Take segmentation to standard / stripping not needed
    ${FSLDIR}/bin/fslreorient2std $SEG $2/anat/aseg
    cd $2/anat
    ${FSLDIR}/bin/flirt -in aseg -ref T1_brain -refweight brain_mask -nosearch -init T1_orig_to_T1.mat -dof 6 -applyxfm -interp nearestneighbour -out "$patient_id""_seg-surf_mask.nii.gz"

fi
cd $1/anat
mask=$(find . -type f -name '*lesion_mask*' | cut -c 3-)
#Warping for lesion mask
if [ `${FSLDIR}/bin/imtest ${mask}` = 0 ] ; then
  echo "WARNING: No lesion mask in $1"
else
    #Take mask to standard / stripping not needed
    ${FSLDIR}/bin/fslreorient2std $mask $2/anat/mask
    cd $2/anat
    ${FSLDIR}/bin/flirt -in mask -ref T1_brain -refweight brain_mask -nosearch -init T1_orig_to_T1.mat -dof 6 -applyxfm -interp nearestneighbour -out "$patient_id""_seg-anomaly_mask.nii.gz"

fi
cd $2/anat
mv T1_brain.nii.gz "$patient_id""_T1w.nii.gz"
rm *_orient.nii.gz
rm *_brain.nii.gz
rm *.mat
rm *_tmp.nii.gz
rm *_tmp2.nii.gz
rm *_roi.nii.gz
rm *_std.nii.gz
rm *_in.nii.gz
rm *warp*
rm T1_brain_to_MNI.nii.gz
rm NonlinearReg.txt
