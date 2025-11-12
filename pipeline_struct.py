import os
import logging_tool as LT


def pipeline_struct(subject, fileConfig, output):

    logger = LT.initLogging(__file__, subject, output)
    logDir = logger.logDir
    subjDir = logger.subjDir
    subjID = subject.replace("\\", "/").split("/")[-1:][0]
    jobReg = "-1"
    jobStripping = "-1"
    jobSTRUCTINIT = "-1"

    # TO do: implement behaviour for more than one T1 in the dataset
    mri_t1 = fileConfig['T1w'][0]
    name_t1 = mri_t1.replace("\\", "/").split("/")[-1:][0]

    os.makedirs(f'{subjDir}/anat',exist_ok=True)

    jobReg = LT.runCommand(
        logger,
        "bash ${pipeDIR}/coregist_init.sh"
        + f' {subject} {subjDir}'
    )

    # Skullstrippings
    #jobStripping = LT.runCommand(
    #    logger,
    #    '${ROBEXDIR}/runROBEX.sh'
    #    + f" {subjDir}/anat/{name_t1}"
    #    + f" {subjDir}/anat/{name_t1}"
    #    + f" {subjDir}/anat/brain_mask.nii.gz"
    #)

    jobStripping = LT.runCommand(
        logger,
        "bash ${pipeDIR}/skullstrip_fnirt.sh"
        + f' {subject} {subjDir}'
    )

    # Registrations
    jobSTRUCTINIT = LT.runCommand(
        logger,
        "bash ${pipeDIR}/struct_init.sh"
        + f' {subjDir}'
    )

    #jobSTRUCTINIT = LT.runCommand(
    #    logger,
    #    "bash ${pipeDIR}/struct_HCP.sh"
    #    + f' {subject} {subjDir}'
    #)


    return ",".join([jobReg,jobStripping,jobSTRUCTINIT])
