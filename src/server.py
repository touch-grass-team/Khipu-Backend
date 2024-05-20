import logging
import socket
import socketserver
from typing import Any, Callable, Tuple
from src.utils.parser import log_parse

from src.config.logging import BASE_LOGGER_NAME


class EventsHandler(socketserver.DatagramRequestHandler):

    def __init__(
        self,
        request: socket.socket,
        client_address: Any,
        server: socketserver.BaseServer,
    ) -> None:
        self.logger = logging.getLogger(f"{BASE_LOGGER_NAME}.EventHandler")
        super().__init__(request, client_address, server)

    def handle(self):
        data = self.rfile.readline()
        log_info = log_parse(data.decode())
        self.logger.info(log_info)
        


class Server(socketserver.UDPServer):
    def __init__(
        self,
        server_address: Tuple[str, bytes, bytearray, int],
        RequestHandlerClass: Callable[[Any, Any], socketserver.DatagramRequestHandler],
        bind_and_activate: bool = True,
    ) -> None:
        self.logger = logging.getLogger(f"{BASE_LOGGER_NAME}.Server")
        self.allow_reuse_address = True
        super().__init__(server_address, RequestHandlerClass, bind_and_activate)

    def server_activate(self) -> None:
        self.logger.info(f"Serving connection at {self.server_address}")
        return super().server_activate()

    def server_bind(self) -> None:
        return super().server_bind()
