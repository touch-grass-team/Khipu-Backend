import os
import __main__

ROOT_PATH = os.path.abspath(os.path.dirname(__main__.__file__))

LOGS_DIR_PATH = os.path.join(ROOT_PATH, "logs/")
LOG_FILE_PATH = LOGS_DIR_PATH + "log.log"

def create_paths():
    if not os.path.exists(LOGS_DIR_PATH):
        os.mkdir(LOGS_DIR_PATH)
