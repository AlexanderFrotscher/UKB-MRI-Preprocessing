import os
import json

def formatFileConfig(fileConfig):
    result=""    
    for key in fileConfig:
        result=result + key + "\n"
        for value in fileConfig[key]:
            result=result + "  "  + value + "\n"
    return result

def file_add_to_config(fileConfig,Path, key):
        fileConfig[key].append(Path)


def my_file_manger(subject, logger):
    fileConfig = {}


    os.chdir(logger.logDir)
    fd_fileName="file_descriptor.json"

    #Check if the subject has already been managed
    if (os.path.isfile(fd_fileName)):
        with open(fd_fileName, 'r') as f:
            fileConfig=json.load(f)
    else:
        os.chdir(subject)
        patterns = ["T1w", "T2w", "FLAIR", "PDw", "angio", "bold", "dwi"]
        for pattern in patterns:
            fileConfig[pattern] = []

        list_ses = os.listdir(".")
        if list_ses[0].startswith('ses'):
            for ses in list_ses:
                list_acq = os.listdir(ses)
                for acq in list_acq:
                    if os.path.isdir(acq):
                        scans = os.listdir(acq)
                        for scan in scans:
                            if scan.endswith('nii.gz'):
                                for pattern in patterns:
                                    if pattern in scan:
                                        my_path = os.path.join(subject,f'{ses}/{acq}/{scan}')
                                        file_add_to_config(fileConfig, my_path, pattern)
        else:
            for acq in list_ses:
                if os.path.isdir(acq):
                    scans = os.listdir(acq)
                    for scan in scans:
                        if scan.endswith('nii.gz'):
                            for pattern in patterns:
                                if pattern in scan:
                                    my_path = os.path.join(subject,f'{acq}/{scan}')
                                    file_add_to_config(fileConfig,my_path, pattern)

        # Create file descriptor
        os.chdir(logger.logDir)
        fd=open(fd_fileName, "w")
        json.dump(fileConfig,fd,sort_keys=True,indent=4)        
        fd.close()

        #fileConfigFormatted=formatFileConfig(fileConfig)

    return fileConfig


             


