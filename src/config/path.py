import os
import __main__

ROOT_PATH = os.path.abspath(os.path.dirname(__main__.__file__))

LOGS_DIR_PATH = os.path.join("/var/log", "khipu/")
LOG_FILE_PATH = LOGS_DIR_PATH + "log.log"

def create_paths():
    path = os.path.abspath(LOGS_DIR_PATH)
    if not os.path.exists(path):
        os.mkdir(LOGS_DIR_PATH)
