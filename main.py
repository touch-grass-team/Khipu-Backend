import logging
import signal
import sys
from src.config.path import create_paths
from src.config.logging import BASE_LOGGER_NAME, setup_logger
from src.config.server import IP_PORT
from src.server import EventsHandler, Server

def setup():
    create_paths()
    setup_logger()


if __name__ == "__main__":
    setup()

    server = Server(IP_PORT, EventsHandler)

    def cleanup(signum, frame):
        server.server_close()
        server.socket.close()
        logger = logging.getLogger(BASE_LOGGER_NAME)
        logger.info("Exited gracefully")
        sys.exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    server.serve_forever()
