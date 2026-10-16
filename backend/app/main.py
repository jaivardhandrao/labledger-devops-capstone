"""ASGI entrypoint, health probes and API assembly."""

from typing import Annotated

from fastapi import Depends, FastAPI
from fastapi.responses import JSONResponse, Response
from prometheus_client import CONTENT_TYPE_LATEST, generate_latest
from sqlalchemy import text
from sqlalchemy.exc import SQLAlchemyError
from sqlalchemy.orm import Session

from app.database import get_db
from app.metrics import HttpMetrics, MetricsMiddleware
from app.routes import router


def create_app() -> FastAPI:
    application = FastAPI(
        title="LabLedger API",
        version="1.0.0",
        description="A campus equipment-loan ledger with observable operational endpoints.",
    )
    metrics = HttpMetrics()
    application.state.metrics = metrics
    application.add_middleware(MetricsMiddleware, metrics=metrics)
    application.include_router(router)

    @application.get("/health", tags=["Operations"])
    def health() -> dict[str, str]:
        return {"status": "ok", "service": "labledger-api"}

    @application.get("/ready", tags=["Operations"])
    def ready(db: Annotated[Session, Depends(get_db)]) -> JSONResponse:
        try:
            db.execute(text("SELECT 1"))
        except SQLAlchemyError:
            return JSONResponse(
                status_code=503, content={"status": "not_ready", "database": "unreachable"}
            )
        return JSONResponse(content={"status": "ready", "database": "reachable"})

    @application.get("/metrics", include_in_schema=False)
    def prometheus_metrics() -> Response:
        return Response(generate_latest(metrics.registry), headers={"Content-Type": CONTENT_TYPE_LATEST})

    return application


app = create_app()
