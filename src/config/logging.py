import logging

FORMAT = (
    "[%(asctime)s] - [%(name)s/%(funcName)s:%(lineno)d] - [%(levelname)s] - %(message)s"
)


def setup_logger():
    logging.basicConfig(format=FORMAT, level=logging.INFO)
