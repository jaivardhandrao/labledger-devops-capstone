"""Bounded-label, per-process HTTP telemetry without personal information."""

from time import perf_counter

from prometheus_client import CollectorRegistry, Counter, Histogram
from starlette.types import ASGIApp, Message, Receive, Scope, Send


class HttpMetrics:
    def __init__(self) -> None:
        self.registry = CollectorRegistry()
        labels = ("method", "route", "status")
        self.requests = Counter(
            "labledger_http_requests_total", "Completed HTTP requests", labels, registry=self.registry
        )
        self.duration = Histogram(
            "labledger_http_request_duration_seconds",
            "HTTP request latency in seconds",
            labels,
            buckets=(0.005, 0.01, 0.025, 0.05, 0.1, 0.25, 0.5, 1, 2.5, 5),
            registry=self.registry,
        )


class MetricsMiddleware:
    def __init__(self, app: ASGIApp, metrics: HttpMetrics) -> None:
        self.app = app
        self.metrics = metrics

    async def __call__(self, scope: Scope, receive: Receive, send: Send) -> None:
        if scope["type"] != "http" or scope["path"] == "/metrics":
            await self.app(scope, receive, send)
            return

        started = perf_counter()
        status_code = 500

        async def capture(message: Message) -> None:
            nonlocal status_code
            if message["type"] == "http.response.start":
                status_code = message["status"]
            await send(message)

        try:
            await self.app(scope, receive, capture)
        finally:
            # Unknown paths share one label to prevent attacker-controlled
            # cardinality. Registered route templates contain no borrower IDs.
            route = getattr(scope.get("route"), "path", "unmatched")
            method = scope["method"]
            if method not in {"GET", "POST", "PUT", "DELETE", "PATCH", "HEAD", "OPTIONS"}:
                method = "OTHER"
            label_values = (method, route, str(status_code))
            self.metrics.requests.labels(*label_values).inc()
            self.metrics.duration.labels(*label_values).observe(perf_counter() - started)
