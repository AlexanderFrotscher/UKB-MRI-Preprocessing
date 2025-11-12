import os
import time
import logging
from subprocess import check_output

def initLogging(fileName, subject, output):

    scriptName = os.path.basename(fileName)
    scriptNameIndex = scriptName.rfind('.')
    if scriptNameIndex != -1 :
        scriptName = scriptName[0:scriptNameIndex]

    logging.basicConfig(level = logging.INFO)
    logger = logging.getLogger(scriptName)
    logger.propagate = False
    subject_dir = subject.replace("\\", "/").split("/")[-1:][0]
    logDir = output + '/logs/' + subject_dir
    os.makedirs(logDir, exist_ok=True)

    subjDir = f'{output}/data/{subject_dir}'
    os.makedirs(subjDir,exist_ok=True)

    logFileName = logDir + '/' + scriptName + '__' + str(os.getpid()) + '.log'
    logFile = logging.FileHandler(logFileName)
    logFile.setFormatter(logging.Formatter('%(asctime)s - %(name)s - %(levelname)s - %(message)s '))
    logger.addHandler(logFile)
    logger.info('Starting the subject processing: ' + str(time.ctime(int(time.time())))  )
    logger.info('Subject received as input: ' + subject  )

    logger.logDir = logDir
    logger.subjDir = subjDir

    return logger


def finishLogging(logger):

     logger.info('Main processing file finished at: ' + str(time.ctime(int(time.time())))  )


def runCommand(logger, command):
    
    try:
        logger.info('COMMAND TO RUN: \t' + command.strip())
        jobOUTPUT = check_output(command, shell=True).decode('UTF-8')
        logger.info('COMMAND OUTPUT: \t' + jobOUTPUT.strip())
    except Exception as e:
        logger.error('Exception raised during execution of: \t' + command.strip())
        logger.error('Exception type: \t' + str(type(e)))
        logger.error('Exception args: \t' + str(e.args))
        logger.error('Exception message: \t' + str(e))

        jobOUTPUT=""
    return jobOUTPUT.strip()

