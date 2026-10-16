"""Create local-only credentials; refuse to overwrite an existing environment."""
from pathlib import Path
import secrets
import os
p = Path(__file__).resolve().parents[1] / ".env"
fd = os.open(p, os.O_CREAT | os.O_EXCL | os.O_WRONLY, 0o600)
with os.fdopen(fd, "w") as stream:
    stream.write("POSTGRES_USER=labledger\nPOSTGRES_DB=labledger\nPOSTGRES_PASSWORD=" + secrets.token_urlsafe(32) + "\nBUSINESS_TIMEZONE=Asia/Kolkata\n")
print("Created ignored .env with a generated local password; its value was not printed.")
