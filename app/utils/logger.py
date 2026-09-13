from enum import Enum
from pathlib import Path
from logging.handlers import RotatingFileHandler
import logging


class LogType(Enum):
    API = "api"
    AUTH = "auth"
    VM = "vm"
    LXC = "lxc"
    NETWORK = "network"
    SYSTEM = "system"


class HyperiaLogger:

    LOG_DIR = Path("./logs")

    @classmethod
    def get_logger(cls, log_type: LogType) -> logging.Logger:

        cls.LOG_DIR.mkdir(parents=True, exist_ok=True)

        logger_name = f"hyperia.{log_type.value}"

        logger = logging.getLogger(logger_name)

        if logger.handlers:
            return logger

        logger.setLevel(logging.INFO)

        handler = RotatingFileHandler(
            cls.LOG_DIR / f"{log_type.value}.log",
            maxBytes=10 * 1024 * 1024,
            backupCount=5
        )

        formatter = logging.Formatter(
            "%(asctime)s [%(levelname)s] %(name)s - %(message)s"
        )

        handler.setFormatter(formatter)

        logger.addHandler(handler)

        return logger