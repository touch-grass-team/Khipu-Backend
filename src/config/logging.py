import logging

from src.config.path import LOG_FILE_PATH

BASE_LOGGER_NAME = "main"
FORMAT = (
    "[%(asctime)s] - [%(name)s/%(funcName)s:%(lineno)d] - [%(levelname)s] - %(message)s"
)


def setup_logger():
    formatter = logging.Formatter(FORMAT)

    base_logger = logging.getLogger(BASE_LOGGER_NAME)
    base_logger.setLevel(logging.INFO)

    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(formatter)
    file_handler = logging.FileHandler(LOG_FILE_PATH)
    file_handler.setFormatter(formatter)

    base_logger.addHandler(file_handler)
    base_logger.addHandler(console_handler)
