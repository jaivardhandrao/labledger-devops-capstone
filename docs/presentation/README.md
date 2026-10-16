# LabLedger presentation and local evidence

- [12-slide presentation PDF](LabLedger_Capstone_Presentation.pdf)
- [Editable PowerPoint with speaker notes](LabLedger_Capstone_Presentation.pptx)
- [Plain-text speaker notes](SPEAKER-NOTES.md)
- [53-second genuine local Terminal recording](../../evidence/presentation/local-terminal-walkthrough.mp4)
- [Native screenshots, provenance and capture limits](../../evidence/presentation/README.md)
- [Actual change → green CI → local rollout record](../DELIVERY-DEMONSTRATION.md)

The slides support an approximately eight-minute **live presentation**. The silent video is supporting Terminal evidence. It is not represented as a complete browser CRUD, Grafana, AWS or newly recorded change-to-rollout walkthrough.

The application/source pipeline shown is the actual seven-job green [run38915964006](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38915964006) for `5cb1c80d6489103ad0c4d60352d0b6c24e998920`. The local running application is the successfully promoted `c2f4acf1e663d79f122e47296621906c9b57d908`. This presentation/evidence update does not rebuild or change either runtime.

All browser images are genuine earlier School-profile captures retained unchanged. Native Terminal screenshots were captured on 16 October 2026 from a newly created dedicated window. The saved original pytest report is explicitly labeled; additional captures show all 35 result lines from the actual completed CI backend-test job. No database record/schema, AWS resource, Kubernetes configuration, Secret, package visibility or school form was changed for the captures.

## Present in order

1. Explain the original domain, lifecycle and request flow.
2. Show the actual isolated test results and live local container/database/cluster evidence.
3. Explain the real security finding/repair, SHA identity and retained promotion failure/recovery.
4. Show the actual Prometheus target state and HPA/troubleshooting evidence.
5. State the cloud status accurately. The real read-only plan exists, but AWS has not been provisioned.
6. Use the live School-profile UI/Swagger/Grafana and actual GitHub pages where available. Keep the final Google Form Submit action with the student.

## Exact remaining presentation dependencies

- Fresh School-profile Compose3000 and post-promotion Ingress8088/browser CRUD walkthrough; required browser work remains with the School-profile controls.
- Grafana populated browser panel using legitimate private login; the authenticated API evidence is already retained, but a login page/JSON is not that screenshot.
- GHCR package page and image access/visibility decision; publication alone does not prove anonymous pulls.
- Real AWS apply/runtime/Console/destroy evidence after the separately pending exact approvals and legitimate Console login.

The PDF, slides and Terminal recording do not claim completion of those missing portions or guarantee a grade. See [rubric status](../RUBRIC-STATUS.md).

## Editable source and validation

`build.py` generates both formats from one layout/content source and embeds the actual evidence files without cropping or fabricating them. PowerPoint contains editable text/shapes and speaker notes; the original screenshot pixels remain in their source files. PDF links and PowerPoint links lead to the actual repository/run.

```sh
python3 -m venv .local/presentation-venv
.local/presentation-venv/bin/python -m pip install -r docs/presentation/requirements.txt
.local/presentation-venv/bin/python docs/presentation/build.py
```

Arial is used when the local macOS font files are available; PDF generation otherwise uses Helvetica. The generation environment used ReportLab4.4.6 and python-pptx1.0.2. All 12 final PDF pages were rendered and visually reviewed; slide count, page dimensions, text and notes were checked. [Validation summary](validation.json) and [layout manifest](layout-manifest.json) document the bounded checks. Internal QA renders are intentionally outside Git.
