# Browser UI evidence — 16 October 2026

Captured from the real running Compose app at `http://localhost:3000/` using supported Chrome browser controls, browser ID 1, the user's Jaivardhan SST / School profile. Screenshots are unmodified JPEG captures, not mockups. The records are explicitly fictional demo fixtures. No records were created, edited, or deleted during this review. No school form fields were changed or submitted.

## Captures

| File | Viewport | State |
| --- | --- | --- |
| `ui-desktop-1800.jpg` | 1800 × 1042 | Full page, all three demo loans |
| `ui-laptop-1024.jpg` | 1024 × 768 | Full page, all three demo loans |
| `ui-tablet-768.jpg` | 768 × 1024 | Full page, tablet navigation |
| `ui-mobile-390.jpg` | 390 × 844 | Full page, two-column overview and horizontal loan table |
| `ui-mobile-dialog-390.jpg` | 390 × 844 | New-loan dialog, all fields and footer visible |
| `ui-compact-dialog-320.jpg` | 320 × 568 | New-loan dialog at compact phone width |
| `ui-overdue-1024.jpg` | 1024 × 768 | Full page, overdue filter shows the multimeter only |
| `ui-short-laptop-1024x600.jpg` | 1024 × 600 | Short desktop viewport, sidebar footer clips |

## Verified behavior

- Live UI loaded three loans: Audio recorder (returned), USB microscope (requested), and Digital multimeter (collected and overdue).
- Overview counts were 3 total, 2 active, 1 overdue, and 1 returned.
- Overdue overview button correctly filtered the table to the multimeter.
- Searching `microscope` correctly filtered to the USB microscope. Search was cleared afterward and All loans restored.
- New-loan dialog opened and canceled successfully at 390 and 320 pixels. No Create loan action was used.
- No page-wide horizontal overflow at 1800, 1024, 768, or 390 pixels. At 390, the table is deliberately wider than its container: 710px table inside 348px with `overflow-x:auto`.
- Compact dialog fit horizontally: 280px client and scroll width, within a 320px viewport. It has a 526px client height and 589px scroll height, so its footer requires dialog scrolling on the short screen. Cancel remained reachable.
- Temporary viewport overrides were reset after review.

## Usability findings for implementation

1. Small secondary text is faint. Source review measured notes around 3.35:1, summary descriptions 3.91:1, and footnote 3.30:1 against white, at roughly 9–10px. Darken toward the existing muted color and consider slightly larger text. Screenshot evidence shows the legibility concern.
2. At 320px the native Status select visibly truncates `Requested` (see compact-dialog capture). Stack Return by / Status at the narrow breakpoint or permit more width. No horizontal overflow or blocked cancel was observed.
3. At 1024 × 600 the fixed sidebar is 600px high with 680px scroll height and `overflow-y:visible`; its lower lending-desk identity/footer falls below the screen. Add vertical scrolling or compact the decorative guide for short desktop screens. Main navigation remains visible.
4. Mobile/tablet table overflow has no visible scroll hint. At 390px the initial view hides return date, status, and action columns. Consider a hint or card layout. Horizontal touch/trackpad scrolling to Actions was not completed before the planned container stop notice; do not claim it was verified.

These are polish/accessibility issues, not a proven app-wide functional failure.

## Availability / scope limit

The app was available when the screenshots and filter/search checks were captured. The coordinating task subsequently reported it was temporarily stopping Compose to increase resources for the new local Kubernetes cluster. Further endpoint checks were paused at that point; no containers were restarted or modified. Current localhost:3000 availability after that notice is unverified. These captures demonstrate the Compose app only; they do not prove Helm/Ingress deployment or Prometheus/Grafana operation. A new endpoint can be inspected once supplied.

School form remains blank and unsubmitted in School Chrome tab 1342518778, retained for later handoff. No access denial occurred.
