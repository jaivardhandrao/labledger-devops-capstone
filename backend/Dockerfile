FROM python:3.12-alpine

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1 \
    PIP_NO_CACHE_DIR=1 \
    BUSINESS_TIMEZONE=Asia/Kolkata

WORKDIR /app
COPY requirements.txt ./
RUN pip install --no-cache-dir --requirement requirements.txt \
    && addgroup -g 10001 -S labledger \
    && adduser -u 10001 -S -D -H -G labledger -s /sbin/nologin labledger

COPY --chown=labledger:labledger app/ ./app/
COPY --chown=labledger:labledger alembic/ ./alembic/
COPY --chown=labledger:labledger alembic.ini ./
USER 10001:10001
EXPOSE 8000
HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)" || exit 1
CMD ["sh", "-c", "python -m app.migrate && exec uvicorn app.main:app --host 0.0.0.0 --port 8000"]
