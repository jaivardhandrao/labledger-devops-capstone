# Deployed UI and monitoring browser evidence — 16 October 2026

All captures are genuine, unmodified browser screenshots obtained through supported controls in Chrome's Jaivardhan SST / School profile (browser ID 1). No credentials were read or entered, no monitoring settings changed, and no school submission made.

## Results

- `http://localhost:8088/` loads LabLedger with three explicitly synthetic loans: USB microphone (returned), Arduino kit (requested), DSLR camera (collected/overdue). Counts: 3 total, 2 active, 1 overdue, 1 returned. The implementation task identifies this endpoint as the local Kubernetes deployment; the browser capture establishes that the endpoint renders the working app, not AWS deployment evidence.
- `http://localhost:9090/targets` loads Prometheus. The `serviceMonitor/monitoring/labledger/0` pool has **2 / 2 up**. Both `labledger-backend` targets are UP: `10.244.0.13:8000/metrics` and `10.244.0.12:8000/metrics`, in namespace `labledger`.
- Three control-plane scrape targets are DOWN with connection-refused errors: kube-controller-manager (192.168.58.2:10257), kube-etcd (192.168.58.2:2381), and kube-scheduler (192.168.58.2:10259). The app target screenshot uses an explicit `labledger-backend` display filter; it must not be represented as all targets being healthy. A complete target screenshot is also saved.
- `http://localhost:3001/` redirects to `http://localhost:3001/login`. The Grafana login screen is available, but no authenticated browser session is present. A populated dashboard screenshot is **pending authentication**, not completed. No login was attempted; no authentication denial occurred. Grafana tab **1342518796** is retained for handoff.

## Prior layout fixes verified live

- The 320px dialog now stacks Return by and Status vertically; `Requested` is fully readable. Dialog remains scrollable; Cancel was successfully used without creating anything.
- Mobile table guidance now says `Scroll sideways to see return dates, status and actions.`
- Table scroll region has `tabindex=0`. Keyboard Tab from the focused region reached `Edit USB microphone — demo loan` and scrolled the table to `scrollLeft=362`, exposing Return by, Status and Actions. The edit action itself was not activated.
- At 390px, document width is 390px with no page-wide horizontal overflow; table width is 710px within a 348px scrolling region.
- At 1024 × 600, sidebar client and scroll heights are both 600px and overflow-y is auto. The lending-desk footer is now visible.
- Secondary text is visibly larger/darker. Parallel source review confirms #526c7b, mostly 11px, approximately 5.54:1 against white and 4.99:1 against page background.
- Temporary viewport override reset after checks. No demo records changed.

## Screenshot files

All paths are relative to this evidence directory:

| File | Content |
| --- | --- |
| `ui-kubernetes-desktop-8088.jpg` | Full app at current default desktop viewport |
| `prometheus-labledger-targets-up.jpg` | Explicitly filtered LabLedger pool, both targets UP |
| `prometheus-all-targets.jpg` | Complete target list, including three control-plane DOWN targets |
| `grafana-login-required.jpg` | Login blocker; not a populated dashboard |
| `ui-fixed-compact-dialog-320.jpg` | Stacked narrow dialog fields |
| `ui-fixed-mobile-390.jpg` | Full mobile app with visible horizontal-scroll hint |
| `ui-fixed-mobile-actions-390.jpg` | Keyboard focus on Edit, date/status/actions visible |
| `ui-fixed-short-laptop-1024x600.jpg` | Compact sidebar and footer visible |

The prior Compose screenshot set remains in place as historical evidence. This review supersedes the prior four UI polish findings: all were addressed in the current deployed frontend. Grafana dashboard capture is the only requested capture still blocked. School form tab 1342518778 remains blank, retained and unsubmitted.

## Follow-up: applicable local targets all UP

The coordinating task reported that it diagnosed the three inaccessible optional Minikube control-plane metrics and excluded those endpoints in the local-only scrape configuration. This browser follow-up did not modify that configuration.

Reopened `http://localhost:9090/targets` in the same School Chrome profile and verified **14 UP, 0 DOWN** across **13 scrape pools**, with no health or endpoint display filter applied. The LabLedger pool still has 2/2 UP; each other applicable pool has 1/1 UP. The previously failing controller-manager, etcd and scheduler scrape pools are absent from the updated target list. This is evidence of the revised applicable target set being healthy, not evidence that the excluded endpoints became reachable.

New evidence, preserving all original captures:

- `prometheus-applicable-targets-full-updated.jpg`: complete expanded target list.
- `prometheus-applicable-targets-summary-updated.jpg`: all 13 pool summaries, totaling 14 UP targets.
- `prometheus-applicable-targets-updated.txt`: DOM snapshot of expanded target state.

Original `prometheus-all-targets.jpg` still records the earlier three failures. Grafana dashboard capture remains pending an authenticated session at `http://localhost:3001/login` (tab 1342518796); no secret was read or entered and no authentication attempt was made. The school form repository field remains untouched pending verification of repository contents/CI. Group A and roll 10117 were additionally confirmed by the user through the coordinating task.
