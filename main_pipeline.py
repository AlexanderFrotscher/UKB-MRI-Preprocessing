import os
import logging
import sys
import argparse
import logging_tool as LT
from my_file_manager import my_file_manger
from pipeline_struct import pipeline_struct
from qc import qc

class MyParser(argparse.ArgumentParser):
    def error(self, message):
        sys.stderr.write('error: %s\n' % message)
        self.print_help()
        sys.exit(2)

class Usage(Exception):
    def __init__(self, msg):
        self.msg = msg

def main(): 
  
    parser = MyParser(description='BioBank Pipeline Manager')
    parser.add_argument("subjectFolder", help='Subject Folder')

    argsa = parser.parse_args()

    subject = argsa.subjectFolder
    subject = subject.strip()

    if subject[-1] =='/':
        subject = subject[0:len(subject)-1]

    #create dataset folder
    output_folder = subject.replace("\\", "/").split("/")[:-1]
    output_folder[-1] = output_folder[-1] + '_processed'
    output_folder = '/'.join(output_folder)
    os.makedirs(output_folder,exist_ok=True)

    logger = LT.initLogging(__file__, subject, output_folder)

    logger.info('Running file manager') 
    fileConfig = my_file_manger(subject,logger)
    jobSTEP1 = "-1"
    jobSTEP1 = pipeline_struct(subject, fileConfig, output_folder)
    qc(subject, fileConfig, output_folder)
    LT.finishLogging(logger)
             
if __name__ == "__main__":
    main()
