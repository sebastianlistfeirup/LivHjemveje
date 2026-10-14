# LivHjemveje

## Start her: Liv og de ti hjemveje

Den originale udviklingspakke ligger i [release v1.0](https://github.com/sebastianlistfeirup/LivHjemveje/releases/tag/v1.0).

**[Download den komplette PDF](https://github.com/sebastianlistfeirup/LivHjemveje/releases/download/v1.0/Liv_og_de_ti_hjemveje_KOMPLET_CODEX_PAKKE.pdf)** — 549 sider, 117.005.562 bytes.

PDF'en indeholder bibel, manuskript, replikker, gameplay og billedplaner til alle 10 kapitler. Kapitel 1 har 30 færdige scenebilleder og en figurreference. Billederne til kapitel 2–10 er beskrevet, men endnu ikke genereret.

## Til Codex

PDF'en ligger som releasefil og følger ikke med en almindelig git-clone. Hent PDF'en fra linket ovenfor; GitHubs automatiske "Source code"-arkiver er ikke udviklingspakken.

PDF'en indeholder den indlejrede `Codex_Input.zip` med de originale PNG-billeder, manuskripter, produktionsbibel, JSON-spildata og valideringsværktøj. Udpak den før udvikling, så materialet kan læses og bruges som almindelige filer.

Kør fra repoets rod:

```bash
python3 -m pip install pymupdf
python3 - <<'PY'
from pathlib import Path
from urllib.request import urlretrieve
from hashlib import sha256
from io import BytesIO
from zipfile import ZipFile
import fitz

pdf_path = Path("Liv_og_de_ti_hjemveje_KOMPLET_CODEX_PAKKE.pdf")
url = "https://github.com/sebastianlistfeirup/LivHjemveje/releases/download/v1.0/Liv_og_de_ti_hjemveje_KOMPLET_CODEX_PAKKE.pdf"
if not pdf_path.exists():
    urlretrieve(url, pdf_path)
expected = "418c882b07ffe5fb2ed9ef66040a2f2e2fdbdec0c27532a585719b157314c1ea"
if sha256(pdf_path.read_bytes()).hexdigest() != expected:
    raise SystemExit("PDF-kontrolsum stemmer ikke. Hent filen igen.")
with fitz.open(pdf_path) as pdf:
    sources = pdf.embfile_get("Codex_Input.zip")
with ZipFile(BytesIO(sources)) as archive:
    archive.extractall("liv_kilder")
print("Kilder udpakket til liv_kilder/Codex_Input")
PY
python3 liv_kilder/Codex_Input/tools/validate_package.py
```

Læs derefter:

1. `liv_kilder/Codex_Input/START_HER.md`
2. `liv_kilder/Codex_Input/docs/Produktionsbibel.md`
3. `liv_kilder/Codex_Input/data/Spildata.json`
4. Kapitel 1-manuskriptet og billederne i `liv_kilder/Codex_Input/assets/chapter_01/`.

Begynd med en spilbar udgave af kapitel 1 med de medfølgende replikker, valg, visuelle gåder og hjemkomst til dragefarmen. Følg biblen for mobilbetjening, animationer og progression.

Dette er udviklingsmaterialet. Et færdigt spil, separate animationslag og indtalt lyd er endnu ikke inkluderet. Bevar originalmaterialet som reference; læg implementeringen i projektets egne filer. Den store PDF skal fortsat ligge som releasefil frem for at blive committed til almindelig Git.
