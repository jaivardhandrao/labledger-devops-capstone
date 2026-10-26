# LabLedger presentation — approved reviewed deck

- [Corrected 12-slide PDF](LabLedger_Capstone_Presentation.pdf)
- [Editable PowerPoint with speaker notes](LabLedger_Capstone_Presentation.pptx)
- [Plain-text speaker notes](SPEAKER-NOTES.md)
- [Demo/ package and exact coverage/gaps](../../demo/README.md)
- [Actual temporary AWS run and verified cleanup](../../evidence/aws-live-2026-10-16/README.md)

Prepared and reviewed 26 October from saved 16 October evidence, then approved by the student for publication. The existing design, 12-slide count and genuine previously published images are retained. Slide 6 distinguishes historical 06909ce EKS release 2 from the final f271a837 seven-green CI and exact-image local Helm release 4. Slide 10 records that the populated local Grafana browser capture exists privately; slide 12 states the current demo/ requirement and remaining presentation/ArgoCD gaps.

The genuine Grafana capture is dated 16 October 23:03:48 UTC. Its one-hour range includes earlier revisions, rollout and recovery; it is not exclusively f271a837 or AWS. No new private browser original is embedded. The complete slides-first AWS Console / ArgoCD synced-GitOps / Kubernetes / Prometheus-UP / Grafana presentation is not recorded. ArgoCD is not implemented, and direct Helm is not described as ArgoCD.

The existing 3m54.5s video under demo/ is a genuine local Terminal change-to-rollout recording. It supports, but does not replace, the complete requested presentation. The full assignment is not marked ready. The student approved publishing this reviewed deck and existing video. Slide bytes are unchanged from review; “review candidate”, “nothing new is published” and similar captions describe the prepublication review stage. Current repository publication status is recorded here and in demo/README.md. Private raw browser evidence remains excluded. Existing originals are preserved in local review backups and Git history; unrelated evidence is unchanged.

`build.py` retains one layout/content source for both formats and speaker notes. It checks the saved successful cleanup-verification artifact without contacting AWS. To reproduce the artifact locally:

```sh
python3 -m venv .local/presentation-venv
.local/presentation-venv/bin/python -m pip install -r docs/presentation/requirements.txt
.local/presentation-venv/bin/python docs/presentation/build.py
```

[Validation](validation.json) records page/slide/text/notes/render checks for this review. No application test, deployment, database or AWS operation was repeated. AWS infrastructure is retired; final billing remains unverified. The student reported original form submission; no receipt or resubmission is claimed.
