"""Build the editable slides and matching PDF from genuine repository evidence."""
from pathlib import Path
from textwrap import dedent
import json
from PIL import Image
from reportlab.pdfgen import canvas
from reportlab.pdfbase import pdfmetrics
from reportlab.pdfbase.ttfonts import TTFont
from reportlab.lib.utils import ImageReader
from pptx import Presentation
from pptx.util import Inches, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE

ROOT = Path(__file__).resolve().parents[2]
OUT = Path(__file__).resolve().parent
W, H = 960, 540
NAVY, INK, TEAL, PAPER, MUTED = '102D42', '17364B', '007E80', 'F4F8FA', '526C7B'
FONT = 'Helvetica'
BOLD = 'Helvetica-Bold'
font_dir = Path('/System/Library/Fonts/Supplemental')
if (font_dir/'Arial.ttf').exists():
    pdfmetrics.registerFont(TTFont('ArialLocal', str(font_dir/'Arial.ttf')))
    pdfmetrics.registerFont(TTFont('ArialLocal-Bold', str(font_dir/'Arial Bold.ttf')))
    FONT, BOLD = 'ArialLocal', 'ArialLocal-Bold'


def rgb(value):
    return tuple(int(value[i:i+2], 16)/255 for i in (0, 2, 4))


class Deck:
    def __init__(self):
        self.pdf = canvas.Canvas(str(OUT/'LabLedger_Capstone_Presentation.pdf'), pagesize=(W, H))
        self.pdf.setTitle('LabLedger — DevOps Capstone | Jaivardhan D Rao | Local Evidence')
        self.pdf.setAuthor('Jaivardhan D Rao')
        self.ppt = Presentation()
        self.ppt.slide_width, self.ppt.slide_height = Inches(13.333333), Inches(7.5)
        self.ppt.core_properties.title = 'LabLedger — DevOps Capstone'
        self.ppt.core_properties.author = 'Jaivardhan D Rao'
        self.number = 0
        self.items = []

    def rect(self, x, y, w, h, color, radius=0):
        self.pdf.setFillColorRGB(*rgb(color))
        if radius:
            self.pdf.roundRect(x, H-y-h, w, h, radius, stroke=0, fill=1)
        else:
            self.pdf.rect(x, H-y-h, w, h, stroke=0, fill=1)
        shape = self.slide.shapes.add_shape(MSO_SHAPE.ROUNDED_RECTANGLE if radius else MSO_SHAPE.RECTANGLE,
                                           Inches(x/72), Inches(y/72), Inches(w/72), Inches(h/72))
        shape.fill.solid(); shape.fill.fore_color.rgb = RGBColor.from_string(color)
        shape.line.fill.background()
        if radius:
            shape.adjustments[0] = 0.12

    def text(self, text, x, y, size=20, w=820, color=INK, bold=False, leading=1.25):
        font = BOLD if bold else FONT
        lines = []
        for block in text.split('\n'):
            line = ''
            for word in block.split():
                candidate = (line+' '+word).strip()
                if line and pdfmetrics.stringWidth(candidate, font, size) > w:
                    lines.append(line); line = word
                else:
                    line = candidate
            lines.append(line)
        h = size*leading*len(lines)
        assert x >= 0 and y >= 0 and x+w <= W+0.1 and y+h <= H+0.1, (self.number, text, y+h)
        self.pdf.setFillColorRGB(*rgb(color)); self.pdf.setFont(font, size)
        for i, line in enumerate(lines):
            self.pdf.drawString(x, H-y-size-i*size*leading, line)
        box = self.slide.shapes.add_textbox(Inches(x/72), Inches(y/72), Inches(w/72), Inches((h+3)/72))
        frame = box.text_frame; frame.clear(); frame.word_wrap = False
        frame.margin_left = frame.margin_right = frame.margin_top = frame.margin_bottom = 0
        for i, line in enumerate(lines):
            p = frame.paragraphs[0] if i == 0 else frame.add_paragraph()
            p.text = line; p.font.name = 'Arial'; p.font.size = Pt(size); p.font.bold = bold
            p.font.color.rgb = RGBColor.from_string(color)
            p.space_before = p.space_after = Pt(0); p.line_spacing = Pt(size*leading)
        self.items.append({'slide': self.number, 'type': 'text', 'text': text, 'bounds': [x, y, w, h]})
        return h

    def image(self, relative, x, y, w, h):
        path = ROOT/relative
        with Image.open(path) as im:
            iw, ih = im.size
        scale = min(w/iw, h/ih); dw, dh = iw*scale, ih*scale
        px, py = x+(w-dw)/2, y+(h-dh)/2
        self.pdf.drawImage(ImageReader(str(path)), px, H-py-dh, dw, dh, mask='auto')
        self.slide.shapes.add_picture(str(path), Inches(px/72), Inches(py/72), width=Inches(dw/72), height=Inches(dh/72))
        self.items.append({'slide': self.number, 'type': 'genuine_image', 'source': relative, 'bounds': [px, py, dw, dh]})

    def page(self, title, kicker, notes, dark=False):
        if self.number:
            self.pdf.showPage()
        self.number += 1
        self.slide = self.ppt.slides.add_slide(self.ppt.slide_layouts[6])
        self.rect(0, 0, W, H, NAVY if dark else PAPER)
        self.text(kicker.upper(), 64, 26, 11, color='A7E2DD' if dark else TEAL, bold=True)
        self.text(title, 64, 48, 30, color='FFFFFF' if dark else NAVY, bold=True)
        self.text(f'Jaivardhan D Rao  ·  10117  ·  Group A', 64, 512, 10,
                  color='CBDAE3' if dark else MUTED, w=600)
        self.text(f'{self.number:02d} / 12', 842, 512, 10, color='CBDAE3' if dark else MUTED, w=70)
        self.slide.notes_slide.notes_text_frame.text = dedent(notes).strip()

    def bullet(self, heading, body, y, x=64, w=540):
        self.text(heading, x, y, 21, w=w, bold=True)
        return y+31+self.text(body, x, y+31, 17, w=w, color=MUTED)+18

    def link(self, label, url, x=64, y=478, w=820):
        self.text(label, x, y, 11, color=TEAL, w=w)
        self.pdf.linkURL(url, (x, H-y-16, x+w, H-y), relative=0, thickness=0)
        self.slide.shapes[-1].text_frame.paragraphs[0].runs[0].hyperlink.address = url

    def save(self):
        self.pdf.save()
        self.ppt.save(OUT/'LabLedger_Capstone_Presentation.pptx')
        (OUT/'layout-manifest.json').write_text(json.dumps({'slides': self.number, 'page_size_points': [W,H], 'items': self.items}, indent=2)+'\n')


d = Deck()
d.page('LabLedger', 'DevOps final capstone · local demonstration', '''
Introduce the original campus equipment-loan domain. Identify yourself as Jaivardhan D Rao, roll 10117, Group A.
The screenshot is a genuine earlier School-profile capture of local Kubernetes, not AWS. Every displayed loan is fictional.
State the scope accurately: the application, CI and local Kubernetes have run; real AWS apply and teardown remain pending approval.
The slides support a live presentation. The separate short video records only the actual local Terminal evidence, not a complete browser walkthrough.
''', dark=True)
d.text('Shared equipment.\nClear returns.', 64, 128, 32, w=318, color='FFFFFF', bold=True)
d.text('React · FastAPI · PostgreSQL\nDocker · CI · Helm · Monitoring', 64, 252, 19, w=305, color='CBDAE3')
d.rect(64, 355, 293, 86, '1E4559', radius=8)
d.text('VERIFIED LOCALLY', 80, 370, 13, w=260, color='A7E2DD', bold=True)
d.text('Cloud execution is still pending.', 80, 398, 15, w=260, color='FFFFFF')
d.image('evidence/ui-kubernetes-desktop-8088.jpg', 390, 126, 515, 335)

d.page('One clear equipment-loan lifecycle', '01 · Application', '''
A borrowing request moves through requested, collected and returned. Only a collected loan past its due date is overdue.
A date has no UTC offset; the application evaluates today in Asia/Kolkata. Returning an item updates the statistics.
Explain the responsive table, keyboard access, filters and create/edit dialogs. The mobile capture is genuine and predates the later footer-only delivery change.
For the live demo open localhost:8088 only in the School Chrome profile; create and remove a temporary fictional loan only when that write is authorized.
''')
y = d.bullet('Request → collect → return', 'A lab desk records the borrower, equipment and return date.', 113, w=540)
y = d.bullet('Overdue has a precise meaning', 'Collected + due date before today in Asia/Kolkata. Requested loans are active, but not overdue.', y, w=540)
d.bullet('Usable on small screens', 'Search, status filters, readable actions and an accessible dialog. Demonstration records are explicitly fictional.', y, w=540)
d.image('evidence/ui-fixed-mobile-390.jpg', 664, 103, 220, 363)
d.text('Genuine School-profile mobile capture', 649, 472, 11, w=260, color=MUTED)

d.page('Follow a request through the stack', '02 · Architecture', '''
The browser sends relative /api requests. Compose Nginx resolves the backend service; Kubernetes Ingress routes /api directly to the API ClusterIP Service.
The frontend serves static React assets. The backend validates inputs and persists loans through SQLAlchemy in PostgreSQL, with Alembic owning schema migration.
Prometheus scrapes both backend replicas and Grafana queries Prometheus. Metrics Server is a separate HPA dependency.
Kubernetes API and monitoring UIs are not public in this local demonstration. A real cloud public endpoint has not been created.
''')
for i, (head, body) in enumerate([('React UI', 'Relative /api calls'), ('Nginx / Ingress', '/ and /api routes'), ('FastAPI', 'Validation + metrics'), ('PostgreSQL', 'Alembic + loans')]):
    x = 64+i*218
    d.rect(x, 132, 190, 90, 'FFFFFF', radius=8)
    d.text(head, x+14, 149, 19, w=164, bold=True)
    d.text(body, x+14, 183, 13, w=164, color=MUTED)
    if i<3: d.text('→', x+195, 158, 24, w=26, color=TEAL)
d.text('Compose', 64, 265, 20, bold=True, w=150)
d.text('localhost:3000 → frontend → backend → database', 234, 267, 18, w=650)
d.text('Kubernetes', 64, 313, 20, bold=True, w=150)
d.text('localhost:8088 → Ingress → ClusterIP Services → Pods', 234, 315, 18, w=650)
d.rect(64, 377, 832, 81, 'E4F1F2', radius=8)
d.text('Prometheus → Grafana', 82, 389, 20, w=400, color=TEAL, bold=True)
d.text('/metrics on both API replicas; real HTTP counters and latency histograms.', 82, 421, 17, w=780)

d.page('35 isolated tests, plus real-stack checks', '03 · Correctness', '''
The image is a native Terminal screenshot of the actual completed CI pytest output, part 2 of 2; it is explicitly not a fresh rerun. Both captures together show every test-result line.
The full evidence/pytest.txt contains all 35 passing API/migration tests. Tests isolate their SQLite database and mock dependencies; they do not use the running PostgreSQL data.
Mention invalid-input rejection, PUT replacement semantics, stats after return/delete, readiness failure and bounded metric route labels.
Separate real HTTP checks exercised the PostgreSQL/Compose path. The latest successful GitHub pipeline also ran the backend tests and nine frontend tests.
''')
d.image('evidence/presentation/terminal-ci-tests-part2.png', 64, 106, 832, 367)
d.text('Actual completed CI pytest output; all 35 results are available across the two native captures.', 64, 482, 12, color=MUTED)

d.page('Three healthy services; two non-root images', '04 · Docker and persistence', '''
This is a fresh actual native Terminal capture. The Compose service is named database, while the Kubernetes StatefulSet is named labledger-postgres.
The API runs as UID10001 and frontend as UID101. The frontend is a Node-build to unprivileged-Nginx multi-stage image.
The read-only PostgreSQL session lists alembic_version and loans. No database record or schema was changed for this capture.
A prior forced backend IP-change check verified proxy DNS recovery and data preservation; see the original raw evidence. No images were rebuilt during this presentation capture.
''')
d.image('evidence/presentation/terminal-compose.png', 64, 106, 832, 367)
d.text('Live local containers and enforced read-only table inspection; original volumes preserved.', 64, 482, 12, color=MUTED)

d.page('A real change reached the running application', '05 · Delivery', '''
Show the meaningful history and actual completed main-push run38915964006, all seven jobs green for source5cb1c80.
The earlier visible footer change went through runs38909132624 and38909739859. Helm4 rejected the first promotion preflight flag, so no deployment was claimed for that failure.
The repaired c2f4acf revision then passed CI and completed exact-Git-archive promotion: two Ready API and UI replicas, new footer served, old footer absent.
The current source-only cloud-preparation commit5cb1c80 is green but is not claimed deployed locally. Full SHAs identify images; the workflow does not deploy automatically to AWS.
''')
d.image('evidence/presentation/terminal-git.png', 64, 106, 832, 350)
d.text('Visible change → green CI → exact c2f4acf local rollout. Current source/CI: 5cb1c80.', 64, 466, 13, color=MUTED)
d.link('Open the actual seven-job green run', 'https://github.com/jaivardhandrao/labledger-devops-capstone/actions/runs/38915964006', y=489)

d.page('The scan gate found a problem, then verified the repair', '06 · DevSecOps', '''
Explain that the initial Debian-based backend image failed strict HIGH/CRITICAL scanning. Its original failed report was retained.
Replacing the runtime with Alpine and rebuilding produced clean backend/frontend reports. Both amd64 and arm64 images must pass before canonical multiarch publication.
Trivy uses HIGH,CRITICAL with ignore-unfixed=false and exit-code1; no broad ignore gate was added. All four actual downloaded current CI reports have zero HIGH/CRITICAL findings.
A clean container scan is a bounded observation, not proof of total application security. Separate exact-credential and secret scans checked the public tree/history; credentials and local state stay outside Git.
''')
d.rect(64, 124, 393, 250, 'FFFFFF', radius=8)
d.text('Before', 86, 145, 16, color=MUTED, w=345)
d.text('Strict scan failed', 86, 181, 29, w=345, bold=True)
d.text('Debian runtime findings were preserved in the original report.', 86, 241, 20, w=338)
d.rect(481, 124, 415, 250, 'E4F1F2', radius=8)
d.text('After', 503, 145, 16, color=TEAL, w=365)
d.text('4 clean CI reports', 503, 181, 29, w=365, bold=True, color=TEAL)
d.text('Backend + frontend\namd64 + arm64\n0 HIGH / CRITICAL', 503, 240, 21, w=365)
d.text('Gate: --severity HIGH,CRITICAL --ignore-unfixed=false --exit-code 1', 64, 408, 17, w=832, bold=True)
d.text('A clean scan is evidence about that image at that time; it is not a security guarantee.', 64, 456, 16, color=MUTED)

d.page('Helm release 2 is running in the dedicated local cluster', '07 · Kubernetes', '''
Show the exact labledger-capstone context rather than relying on the current global context. The older coursework cluster is preserved.
Both UI and API Deployments have two Ready replicas. Their Services are ClusterIP. PostgreSQL is a StatefulSet with a PVC; the migration Job completed successfully.
A Completed migration Job is expected and does not mean application Pods are unhealthy. Probes gate application readiness on migration/database state.
The local storage class is standard, not the prepared AWS gp3 class. These are genuine local Kubernetes results, not EKS results.
''')
d.image('evidence/presentation/terminal-kubernetes.png', 64, 106, 832, 367)
d.text('Local context: labledger-capstone. UI/API Running; migration Job Completed as designed.', 64, 482, 12, color=MUTED)

d.page('Resilience was exercised, not only configured', '08 · HPA and troubleshooting', '''
Use the retained original load/drill logs; this evidence is historical and no new fault or load is injected during this presentation capture.
The actual HPA rose from 2 to 4 Ready API Pods under CPU load and later returned to 2. The persistent read load recorded 2338 requests with zero failures.
A deliberately broken Service selector produced503/no endpoints; restoring the selector restored200. One earlier drill was affected by controller reconciliation and is retained separately.
Explain readiness vs liveness, Service selectors vs Pod labels, and why Metrics Server and CPU requests are required for HPA. HPA scales Pods, not worker nodes.
''')
d.text('2 → 4 Ready → 2', 64, 123, 44, color=TEAL, bold=True)
d.text('Observed API HPA response under controlled local CPU load.', 64, 188, 20, color=MUTED)
d.rect(64, 245, 393, 139, 'FFFFFF', radius=8)
d.text('2,338 reads · 0 failures', 84, 264, 25, w=350, bold=True)
d.text('Persistent HTTP connections; original request log retained.', 84, 311, 18, w=350, color=MUTED)
d.rect(481, 245, 415, 139, 'FFFFFF', radius=8)
d.text('200 → 503 → 200', 501, 264, 25, w=370, bold=True)
d.text('Service selector fault, diagnosis and real recovery.', 501, 311, 18, w=370, color=MUTED)
d.text('Original logs: evidence/local-cluster/README.md. No new failure was injected for these slides.', 64, 433, 16, color=MUTED)

d.page('Actual application scraping is healthy', '09 · Observability', '''
This is the genuine unfiltered School-profile browser screenshot after the documented local-only configuration repair:14 applicable targets UP across13 pools.
The original three optional loopback-only control-plane endpoint failures are still retained. Their endpoints did not become reachable; the local override excludes those inapplicable component scrapes.
Both API replicas remain scraped. Grafana authenticated API previously returned the six-panel dashboard with positive actual traffic samples, but no populated browser screenshot is claimed.
Open the real Grafana UI using legitimate private login in the School profile. Never show a login page or dashboard JSON as evidence of a populated panel.
''')
d.image('evidence/prometheus-applicable-targets-summary-updated.jpg', 64, 104, 832, 335)
d.text('14 applicable targets UP; original loopback-endpoint failures and local fix retained.', 64, 449, 14, color=MUTED)
d.text('Grafana: real API data verified; populated browser-panel capture still pending login.', 64, 477, 14, color=TEAL, bold=True)

d.page('AWS is prepared, but has not been deployed', '10 · Honest cloud status', '''
The actual read-only personal-account plan proposes62 creates, zero changes and zero deletes. Nine mock tests and provider validation passed, but these are not proof of a running EKS cluster.
The proposed isolated Mumbai environment contains a VPC, two public/two private subnets, one NAT, one EKS cluster/worker and a Terraform-owned HTTP NLB.
Official API prices support a two-hour bounded illustrative estimate of2.432349USD before tax; the approved conditional ceiling is10USD/max2h. This is not a hard automated billing cap.
Exact IAM/temporary admin/controller RBAC/public-network and package-visibility decisions remain pending. No access grant, AWS resource, cost, Console screenshot or destroy success is claimed.
''')
y = d.bullet('Observed: a real read-only account plan', '62 creates · 0 updates · 0 deletes. No apply, access grant or cloud teardown.', 117, w=820)
y = d.bullet('Prepared: reproducible infrastructure and bootstrap', 'VPC + EKS + one worker + NLB; restricted API; Helm and monitoring; project-only cleanup.', y, w=820)
y = d.bullet('Remaining: approval and genuine cloud evidence', 'Exact access/visibility decisions, actual apply, Console/runtime verification and complete teardown.', y, w=820)
d.text('Pricing scenario: about US$2.43 before tax. Conditional ceiling: US$10 / maximum 2 hours.', 64, 461, 16, color=TEAL, w=832, bold=True)

d.page('Present the verified work, then review the submission', '11 · Handoff and limits', '''
Use the PDF or editable slides as a speaking guide. Play the separate native Terminal-only recording as supporting evidence, not a claim that the complete app/browser demo was recorded.
For a full live/remote walkthrough, open local UI/Swagger/Prometheus/Grafana in the School Chrome profile, show the genuine green run and package pages, and explain the retained change-to-rollout sequence.
Finish any actual AWS work only after the pending access/visibility decisions and legitimate Console authentication. Capture and clean up real resources before claiming the cloud module.
The school form is filled for Jaivardhan D Rao, Group A, roll 10117 and the official SST email. The user reviews and submits manually. No submission or receipt is claimed.
''')
y = d.bullet('Ready to review', 'Original app, tests, containers, green CI, local Kubernetes, native evidence and these editable slides.', 116, w=820)
y = d.bullet('Still required for the complete presentation', 'Live browser/Swagger CRUD, populated Grafana and package-page captures; genuine AWS evidence after approval.', y, w=820)
d.bullet('Final submission stays with the student', 'Form filled for Group A / roll 10117. Review the public repository and evidence before pressing Submit.', y, w=820)
d.link('Public repository and complete evidence index', 'https://github.com/jaivardhandrao/labledger-devops-capstone', y=480)
d.save()
print('Built 12-slide PDF and editable PPTX with speaker notes; genuine evidence images retained unchanged.')
