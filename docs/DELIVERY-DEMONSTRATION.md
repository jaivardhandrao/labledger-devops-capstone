# Actual delivery demonstration — 16 October 2026

The following sequence was performed against the dedicated local `labledger-capstone` profile. It is local Kubernetes evidence; the separate AWS work has not yet been applied.

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

A post-promotion browser screenshot and a live presentation or genuine recorded remote walkthrough remain separate capture requirements. This record does not claim a video was created or that the school form was submitted. [Presentation guide](DEMO.md) explains how to demonstrate the system live.
