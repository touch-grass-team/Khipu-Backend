import logging
import signal
from src.config.logging import setup_logger
from src.config.server import IP_PORT
from src.server import EventsHandler, Server

server = Server(IP_PORT, EventsHandler)


def cleanup(signum, frame):
    server.server_close()
    server.socket.close()
    logger = logging.getLogger("Main")
    logger.info("Exited gracefully")
    exit(0)


if __name__ == "__main__":
    setup_logger()
    signal.signal(signal.SIGINT, cleanup)
    signal.signal(signal.SIGTERM, cleanup)
    server.serve_forever()
