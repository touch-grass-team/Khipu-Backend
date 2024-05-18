import logging

BASE_LOGGER_NAME = "main"
FORMAT = (
    "[%(asctime)s] - [%(name)s/%(funcName)s:%(lineno)d] - [%(levelname)s] - %(message)s"
)

base_logger = logging.getLogger(BASE_LOGGER_NAME)

def setup_logger():
    console_handler = logging.StreamHandler()
    console_handler.setLevel(logging.INFO)
    console_handler.setFormatter(logging.Formatter(FORMAT))
    base_logger.setLevel(logging.INFO)
    base_logger.addHandler(console_handler)
