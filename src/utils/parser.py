import datetime
import re
from dataclasses import dataclass
from typing import Optional


@dataclass
class LogInfo:
    Timestamp: datetime.datetime
    User: str
    Process: str
    PID: Optional[int]
    Message: str


def log_parse(log: bytes):
    # Head parsing
    parts = list(map(str, log.partition(": ")))
    head = parts[0].split()
    month = re.search(r"[A-Za-z]+", head[0])[0]
    day = head[1]
    time = head[2]
    user = head[3]
    proccess = re.search(r"([a-zA-Z]+)", head[4])[0]
    pid = re.search(r"\[(\d+)\]", head[4])
    if pid:
        pid = pid[1]
    message = parts[2]
    year = datetime.date.today().year
    timestamp = datetime.datetime.strptime(
        f"{month} {day.zfill(2)} {year} {time}", "%b %d %Y %H:%M:%S"
    )
    log_info = LogInfo(
        Timestamp=timestamp, User=user, Process=proccess, PID=pid, Message=message
    )
    return log_info
