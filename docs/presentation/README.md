# LabLedger presentation and actual evidence

- [12-slide PDF](LabLedger_Capstone_Presentation.pdf)
- [Editable PowerPoint with speaker notes](LabLedger_Capstone_Presentation.pptx)
- [Plain-text speaker notes](SPEAKER-NOTES.md)
- [Actual temporary AWS run, native evidence and verified cleanup](../../evidence/aws-live-2026-10-16/README.md)
- [Original supporting local Terminal recording](../../evidence/presentation/local-terminal-walkthrough.mp4)

The deck supports the student's live presentation. It covers the original domain, request flow, tests, Docker, strict scan repair, fresh green 06909ce CI, exact-SHA EKS promotion, PostgreSQL/gp3, actual HPA/fault/recovery, real monitoring and verified teardown. Old local captures and saved actual cloud snapshots are labeled by scope and time; a saved result is not presented as a fresh query after retirement.

No private browser originals were embedded while their publication approval remained pending. A populated Grafana browser panel and the full student browser/live walkthrough are not claimed complete. Short silent Terminal recordings are supporting evidence, not that complete presentation. The cloud burst's12failures remain disclosed, along with the separate lower-rate40/40recovery. No grade is guaranteed.

`build.py` produces both formats from one layout/content source and regenerates the notes. It requires the actual successful cleanup-verification artifact before building this final version. Screenshot source pixels are retained without cropping or fabrication. Text/shapes/notes are editable in PowerPoint.

```sh
python3 -m venv .local/presentation-venv
.local/presentation-venv/bin/python -m pip install -r docs/presentation/requirements.txt
.local/presentation-venv/bin/python docs/presentation/build.py
```

The temporary AWS endpoint is retired; local reproduction instructions remain in the repository. [Validation](validation.json) records the final page/slide/text/notes/render checks. Actual final AWS billing is not yet verified; the published price scenario remains an estimate.
