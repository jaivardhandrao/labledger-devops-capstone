# LabLedger demo — existing recording and reviewed slides

**Included with the student’s publication approval on 26 October 2026. The full assignment is not marked ready.** This is the same submitted repository. The existing recording and reviewed slides are provided without creating a new video, implementing ArgoCD, uploading to Drive, deploying, provisioning AWS or performing another school form submission.

Student: Jaivardhan D Rao · Roll 10117 · Enrollment 24BCS10117 · Group A.

## Included files

| File | Contents | Status |
|---|---|---|
| [LabLedger_Capstone_Presentation.pdf](LabLedger_Capstone_Presentation.pdf) | Corrected 12-slide reviewed deck | Included in this repository |
| [LabLedger_Capstone_Presentation.pptx](LabLedger_Capstone_Presentation.pptx) | Editable matching deck with speaker notes | Included in this repository |
| [LabLedger_Local_Change_CI_Deployment_Review.mp4](LabLedger_Local_Change_CI_Deployment_Review.mp4) | Genuine 3m54.5s continuous native Terminal recording, 1920×1288, silent | Existing recording; not the complete presentation |
| [Speaker notes](../docs/presentation/SPEAKER-NOTES.md) | Scope, evidence dates and limits for all 12 slides | Local correction |

## What the recording actually proves

On 16 October it recorded a fresh app accessibility refinement, 9 passing frontend tests and production build, personal-account commit/push of `f271a837a203a12e42e8353977bc1215a33f51e8`, the actual CI waiting interval and [all seven successful jobs in run 38977458426](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38977458426), anonymous pulls of the exact published ARM64 images, loading them into the dedicated local Minikube profile, and successful Helm revision 4 rollout. Two Ready API and two Ready UI Pods were independently matched to the published platform config digests. The served asset gained “Show all loans.”

Approximate chapters: 00:00–00:12 real source change/tests/build/commit/push; 00:12–03:17 actual CI wait; 03:17–03:39 successful jobs and published-image pulls; 03:39–03:54 local Helm rollout and served-asset verification. The opening seconds include prior Terminal scrollback before the new run. Output is genuine; no result is replayed or drawn. It is a silent supporting Terminal capture, not narrated student presentation footage.

Size: **19,758,772 bytes**. SHA-256: `8fe816f1c48edc3847294c7f929ec28fdceedc4ce50b8b1b8a0548e08576ed4e`. The original native MOV and prior failed-attempt records are preserved privately. This copy has identical MP4 bytes and retains its previously reviewed filename. The deck PDF/PPTX also retain their approved review bytes. Their dated review-stage captions record the earlier preparation; current publication status is stated in this README.

## Required presentation coverage still missing

The [official submission guide](https://github.com/Nency-Ravaliya/devsecops-python/blob/main/SUBMISSION.md) and [grading guide](https://github.com/Nency-Ravaliya/devsecops-python/blob/main/GRADING.md), together with the supplied 26 October SST Class of 2028 announcements, are the source references. The full presentation should start with slides, then cover code, actual push → CI → deployment, Terraform/AWS Console VPC/EKS, ArgoCD synced/GitOps, Kubernetes, Prometheus UP and populated Grafana.

| Requested segment | Existing evidence | Candidate video coverage / remaining gap |
|---|---|---|
| Slides first, then code | Corrected 12-slide PPTX/PDF | Slides are separate; video does not start with them or provide narration |
| Real change, push, CI, deployment | Final f271a837, seven-green run, exact-image local Helm 4 | Covered in Terminal on the actual local cluster |
| Terraform and AWS Console VPC/EKS | Actual temporary AWS deployment and cleanup records; separate Console captures held privately | Absent from this video; AWS infrastructure is retired, with no restart authorized |
| ArgoCD synced / GitOps | **Not implemented** | **Missing.** Delivery is direct Helm, not ArgoCD or automated reconciliation |
| Kubernetes | Local and historical EKS evidence | Local Helm/Pods/Services visible; no complete narrated browser tour |
| Prometheus UP | Retained local and historical cloud captures/results | Not shown in this final change-to-rollout video |
| Populated Grafana | Genuine private local six-panel screenshot, 16 October 23:03:48 UTC | Not in this video or deck. One-hour history spans earlier revisions, rollout and recovery; not exclusively f271a837 or AWS |

The 26 October messages at 14:11 and 14:17 IST require video and PPT/PDF in `demo/` in this same submitted repository by **EOD 26 October** and also permit a Drive-video link in Markdown here. No exact EOD clock time was supplied. This repository addition does not create a Drive upload or invent a link. If a Drive route is chosen later, its real accessible URL must be reviewed before publication.

M10 is README **2**, video **2**, slides **1** mark. The guide says a missing video gives zero for **M10 only**. Presence of this partial recording is not a promise of full credit or full requirement coverage.

## Approved media and remaining private evidence

The video and its real transcript were checked for credential values; the existing validation/hash checks were retained. Its Terminal text includes the student's public GitHub identity, local `/Users/jaivardhandrao/...` paths and Mac/user prompt information. These personal device details remain visible in the unchanged recording. The student was informed and explicitly approved publishing this existing video on 26 October. This approval does not extend to private Grafana or raw browser captures. No new raw browser screenshot is included in this folder or deck.

The earlier approved 58-second engineering overview remains unchanged in [evidence/presentation](../evidence/presentation/LabLedger_Engineering_Walkthrough.mp4). It is an edited overview and is not relabeled as the complete presentation.

The student reported submitting the original repository URL. No receipt or instructor acceptance is verified and no submission/resubmission is attempted. See [rubric status](../docs/RUBRIC-STATUS.md) and [delivery chronology](../docs/DELIVERY-DEMONSTRATION.md) for precise historical scope.
