import datetime
import re
from dataclasses import dataclass
from typing import Optional


@dataclass
class LogInfo:
    Timestamp: datetime.datetime
    Level: str
    User: str
    Process: str
    PID: Optional[int]
    Message: str


def log_parse(log: bytes):
    # Head parsing
    parts = list(map(str, log.partition(": ")))
    head = parts[0].split()
    month = re.search(r"[A-Za-z]+", head[0])[0]
    timestamp = datetime.datetime.fromisoformat(head[0])
    level = head[1]
    user = head[2]
    proccess = re.search(r"([a-zA-Z]+)", head[3])[0]
    pid = re.search(r"\[(\d+)\]", head[3])
    if pid:
        pid = pid[1]
    message = parts[2]
    log_info = LogInfo(
        Timestamp=timestamp, User=user, Process=proccess, PID=pid, Message=message, Level=level
    )
    return log_info
