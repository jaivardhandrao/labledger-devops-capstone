# Actual delivery demonstrations — retained 16 October evidence

**New cloud continuation:** controller fix06909ce passed all seven jobs in [run 38934060961](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38934060961), then actually rolled out those exact SHA images to EKS release2 at 16:52:04 UTC. The [cloud record](../evidence/aws-live-2026-10-16/README.md) contains actual metadata and verified cleanup. The visible footer/local sequence below remains a separate historical demonstration.
The earlier footer-change sequence below was performed against the dedicated local `labledger-capstone` profile. It is separate from the actual cloud continuation above. AWS was subsequently applied, demonstrated and verified removed; it is not currently running.

| Step | Actual observation |
|---|---|
| Baseline | Published commit `7e28da8205d18f5c1cb4541ebb10441a1716d714`; old footer “Made for the things we share.” appears in the genuine earlier browser capture. |
| Visible change | Commit `f7761d89db7b5add2afac96ca10ae7085d96af06` changes the footer to “Shared equipment. Clear returns.” |
| Pipeline | [The change run](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38909132624) passed both test jobs, all four strict architecture/component image scans and SHA publication. |
| Real failure | Promotion stopped before building or changing the release because Helm 4 rejects `helm list --all`. The failure is retained; no rollout was claimed for this attempt. |
| Compatibility repair | Commit `c2f4acf1e663d79f122e47296621906c9b57d908` uses the supported release-status flags. [Its actual run](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38909739859) passed all seven jobs. |
| Deployment | The promotion script archived this exact reviewed Git tree, built and strictly scanned native local images, loaded them into the dedicated profile and completed a waited Helm upgrade/rollout. Both frontend and backend have two Ready replicas using that exact full SHA tag. |
| Result | The actual served JavaScript contains the new footer and excludes the old text. The ServiceMonitor remained enabled; all 14 applicable Prometheus targets were UP after rollout. |

Evidence:

- [Actual running image/SHA and served-copy verification](../evidence/ci/deployed-commit.json)
- [Successful promotion command output](../evidence/ci/promotion-success.txt)
- [Final green run metadata](../evidence/ci/promotion-fix-run.json)
- [Initial compatibility failure](../evidence/ci/promotion-helm4-flag-failure.txt)
- [Original browser capture with the baseline footer](../evidence/ui-kubernetes-desktop-8088.jpg)

The local images were rebuilt and independently scanned from the reviewed SHA. They are not claimed to be byte-identical to the separately published multi-architecture registry images. No AWS credential or registry credential was copied into this local cluster.

## Later genuine local recording — final f271a837

The final source change improves the toolbar reset label to “Show all loans” and announces result counts accessibly. Its actual [run 38977458426](https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38977458426) passed all seven jobs. The 3m54.5s continuous native Terminal recording shows the fresh change, 9 frontend tests/build, personal-account Git push, actual CI wait, anonymous public ARM64 image pulls, and waited local Helm revision 4 rollout. It retains the real CI waiting interval.

Unlike the earlier rebuilt local-image sequence above, this final local rollout loaded the exact registry images produced by CI. Independent inspection matched all four active Ready Pod runtime config digests to the published ARM64 platform manifests for `f271a837a203a12e42e8353977bc1215a33f51e8`. The served bundle gained “Show all loans”; separate genuine School-profile captures show matching search/status results and reset to all three fictional records.

The initial `a0f81e7` run 38974959951 stopped because unnecessary BuildKit setup exceeded its five-minute publisher timeout; it was not deployed. The `b02f649` client-only manifest repair then passed all seven jobs and reached local Helm revision 3, but its recorder failed before the first video sample. The final `f271a837` sequence has a complete successful recording. These failures are not relabeled as successful recordings.

The final recording is included with the student’s 26 October publication approval [under demo/](../demo/README.md). It is not claimed to be the complete student presentation. It is Terminal-only and contains no slides-first narration, AWS Console tour, ArgoCD sync/GitOps view or full monitoring browser flow. **ArgoCD is not implemented; the actual deployment path is direct Helm.**

A genuine six-panel populated Grafana browser capture was completed privately on 16 October at 23:03:48 UTC after recovery of the existing local service. Its one-hour range includes earlier local revisions, rollout and recovery and is not exclusively final-SHA or AWS evidence. It is not embedded or published by this preparation.

This 26 October update only reconciles docs and packages saved media; no runtime check was repeated. The student reported manually submitting the repository, but no receipt or instructor acceptance has been verified and no form action is performed. The full slides-first presentation remains incomplete. [Presentation guide](DEMO.md) remains a speaking guide, not evidence that every requested segment was recorded.
