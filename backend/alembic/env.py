"""Environment-injected DB URL; never store production credentials here."""

from logging.config import fileConfig

from alembic import context
from sqlalchemy import create_engine, pool

from app.database import Base, database_url
from app import models  # noqa: F401 — register tables with Base.metadata

config = context.config
if config.config_file_name:
    fileConfig(config.config_file_name)
target_metadata = Base.metadata


def run_on_connection(connection):
    context.configure(connection=connection, target_metadata=target_metadata, compare_type=True)
    with context.begin_transaction():
        context.run_migrations()


if context.is_offline_mode():
    context.configure(
        url=database_url(), target_metadata=target_metadata, literal_binds=True, compare_type=True
    )
    with context.begin_transaction():
        context.run_migrations()
elif config.attributes.get("connection") is not None:
    run_on_connection(config.attributes["connection"])
else:
    connectable = create_engine(database_url(), poolclass=pool.NullPool)
    with connectable.connect() as connection:
        run_on_connection(connection)
