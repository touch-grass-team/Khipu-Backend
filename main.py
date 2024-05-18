import logging
import signal
from src.config.logging import BASE_LOGGER_NAME, setup_logger
from src.config.server import IP_PORT
from src.server import EventsHandler, Server


if __name__ == "__main__":
    setup_logger()
    server = Server(IP_PORT, EventsHandler)

    def cleanup(signum, frame):
        server.server_close()
        server.socket.close()
        logger = logging.getLogger(BASE_LOGGER_NAME)
        logger.info("Exited gracefully")
        exit(0)

    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    server.serve_forever()
