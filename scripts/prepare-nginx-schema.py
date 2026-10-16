#!/usr/bin/env python3
"""Resolve the pinned controller chart's schema references from a verified local file.

No network, AWS, kubeconfig or cluster access. Runtime chart files are unchanged.
"""
import argparse
import hashlib
import json
from pathlib import Path, PurePosixPath
import tarfile
import tempfile


def prepare(chart: Path, definitions: Path) -> Path:
    root = Path(__file__).resolve().parents[1]
    package_lock = json.loads((root / "k8s/nginx-ingress/chart.lock.json").read_text())
    schema_lock = json.loads((root / "k8s/nginx-ingress/schema.lock.json").read_text())
    if hashlib.sha256(chart.read_bytes()).hexdigest() != package_lock["package_sha256"]:
        raise ValueError("Controller package checksum does not match the pinned official chart")
    definitions = definitions.resolve(strict=True)
    if hashlib.sha256(definitions.read_bytes()).hexdigest() != schema_lock["sha256"]:
        raise ValueError("Definitions checksum does not match the pinned upstream schema")
    destination = Path(tempfile.mkdtemp(prefix="labledger-nginx-schema-"))
    with tarfile.open(chart) as archive:
        for member in archive.getmembers():
            path = PurePosixPath(member.name)
            if path.is_absolute() or ".." in path.parts or path.parts[0] != "nginx-ingress":
                raise ValueError("Unexpected archive path")
            if member.issym() or member.islnk():
                raise ValueError("Unexpected archive link")
        archive.extractall(destination, filter="data")
        chart_root = destination / "nginx-ingress"
        schema = chart_root / "values.schema.json"
        document = json.loads(schema.read_text())
        replacements = 0

        def rewrite(value):
            nonlocal replacements
            if isinstance(value, dict):
                for key, child in value.items():
                    if key == "$ref" and isinstance(child, str):
                        if child.startswith(schema_lock["source_url"] + "#"):
                            value[key] = definitions.as_uri() + child[len(schema_lock["source_url"]):]
                            replacements += 1
                        elif not child.startswith("#"):
                            raise ValueError("Unexpected external chart schema reference")
                    else:
                        rewrite(child)
            elif isinstance(value, list):
                for child in value:
                    rewrite(child)

        rewrite(document)
        if replacements != schema_lock["expected_reference_count"]:
            raise ValueError("Unexpected number of upstream schema references")
        schema.write_text(json.dumps(document, indent=2) + "\n")
        for member in archive.getmembers():
            if member.isfile() and member.name != "nginx-ingress/values.schema.json":
                if (destination / member.name).read_bytes() != archive.extractfile(member).read():
                    raise ValueError("A runtime chart file changed")
    return chart_root


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--chart", required=True, type=Path)
    parser.add_argument("--definitions", required=True, type=Path)
    args = parser.parse_args()
    try:
        print(prepare(args.chart, args.definitions))
    except (OSError, ValueError, tarfile.TarError) as error:
        parser.exit(1, str(error) + "\n")
