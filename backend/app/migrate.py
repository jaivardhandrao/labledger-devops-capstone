"""Apply migrations once at a time when several backend replicas start.

PostgreSQL's advisory transaction lock coordinates replicas sharing this DB.
For larger deployments, invoke this module from a controlled migration Job
before the application rollout instead of from each Pod.
"""

import logging
import time
from pathlib import Path

from alembic import command
from alembic.config import Config
from sqlalchemy import text
from sqlalchemy.exc import OperationalError

from app.database import get_engine

logger = logging.getLogger(__name__)


def upgrade_schema() -> None:
    engine = get_engine()
    config = Config(str(Path(__file__).resolve().parent.parent / "alembic.ini"))
    with engine.begin() as connection:
        if engine.dialect.name == "postgresql":
            connection.execute(text("SELECT pg_advisory_xact_lock(72400117)"))
        config.attributes["connection"] = connection
        command.upgrade(config, "head")


def main() -> None:
    # Bounded startup retry while Compose/Kubernetes starts PostgreSQL. No
    # connection URLs or exception text are logged because they may contain PII.
    for attempt in range(1, 31):
        try:
            upgrade_schema()
            return
        except OperationalError:
            if attempt == 30:
                raise RuntimeError("Database unavailable after migration startup retry window") from None
            logger.warning("Waiting for database before migration (attempt %s/30)", attempt)
            time.sleep(2)


if __name__ == "__main__":
    main()
