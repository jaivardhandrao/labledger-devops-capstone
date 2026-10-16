# Container scan result

Trivy 0.75.0 scanned both pre-demo baseline runtime images for known HIGH and CRITICAL vulnerabilities with `--ignore-unfixed=false` and a failing exit code for findings. The initial Debian backend reported 44 HIGH findings; replacing its base with Alpine and retesting produced zero HIGH/CRITICAL findings for the backend and final frontend image in the saved local reports. These results apply to the exact image IDs and vulnerability database at scan time; they do not establish that the application is free of vulnerabilities, and all four actual baseline CI scans are also clean in the downloaded [CI reports](ci/baseline-scan-summary.json).

| Image | Exact local image ID | Scan timestamp | HIGH / CRITICAL |
|---|---|---|---|
| Backend | `sha256:a8f7d0e1b0216753e03c0b2546c66fcc11ec625a10504cc17b79a228a56820b6` | 16 October 2026, 18:29:11 +05:30 | 0 / 0 |
| Frontend | `sha256:18098bb883fab3b21d3a2add3195144f0534e10be3c5174fa6864aff659cfc80` | 16 October 2026, 18:42:12 +05:30 | 0 / 0 |

Read the complete [backend](trivy-backend.json), [frontend](trivy-frontend.json) and [original failed Debian](trivy-backend-debian-initial.json) reports. No CVE exception or weakened severity gate was used.
