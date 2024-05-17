import logging
import socket
import socketserver
from socketserver import BaseRequestHandler
from typing import Any, Callable, Self


class EventsHandler(socketserver.BaseRequestHandler):
    def __init__(
        self,
        request: socket.socket | tuple[bytes, socket.socket],
        client_address: Any,
        server: socketserver.BaseServer,
    ) -> None:
        self.logger = logging.getLogger("EventHandler")
        super().__init__(request, client_address, server)

    def handle(self):
        self.request: socket.socket
        data = self.request.recv(1024)
        self.logger.info(f"Handled data: {data}")


class Server(socketserver.TCPServer):
    def __init__(
        self,
        server_address: tuple[str | bytes | bytearray, int],
        RequestHandlerClass: Callable[[Any, Any, Self], BaseRequestHandler],
        bind_and_activate: bool = True,
    ) -> None:
        self.allow_reuse_address = True
        super().__init__(server_address, RequestHandlerClass, bind_and_activate)

    def server_bind(self) -> None:
        return super().server_bind()
