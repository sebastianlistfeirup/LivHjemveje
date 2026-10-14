# Teknisk overblik

Spillet bruger **Godot 4.6.3**, GDScript og Compatibility-rendering. Webeksporten bruger én tråd og WebGL 2, uden krav om COOP/COEP. Der er ingen backend, konto eller telemetri.

## Indhold og progression

`content/source/Spildata.json` er den uændrede produktionskilde. `tools/make_runtime.py` udleder den oprindelige kapitelkonfiguration. `tools/make_adventure.py` skriver udvidelsen til `content/runtime/adventure_01.json`; `AdventureBook` sammenfletter dem ved indlæsning. Udvidelsen indeholder 13 nye scener, reviderede replikker, valg og minispil. Senere replikker afhænger blandt andet af Livs samtale med Mos og løftet ved brønden.

`StoryRuntime` ejer sceneskift, læsning, deltrin og belønninger. Der er 53 noder og 49 noder pr. rute. Åbningen er S51 (dragebog), S52 (taske), S53 (rejsekort), derefter S01. S08 og S22 gemmer de to A/B-valg før overgangen. S32 redder Mos, S35 bygger huset, S38 gemmer eksklusiv rutegave og redningsdetalje, og S40 åbner farmen. Kapitel 2 bliver opdaget, men kan ikke startes.

`AdventureGame` indeholder deterministiske regler for de nye udfordringer, adskilt fra tegning og input. Pakning kontrollerer form, drejning, overlap og taskens grænser. Labyrinten er en reproducerbar 9 × 7-graf med blindgyder. Nøglerne har ti forskellige firetandsprofiler; kun afprøvning bruger et af tre forsøg. Efter tre fejl kræves fornyet undersøgelse, før tre nye forsøg åbnes. Runer, potion og hukommelsessti gemmer deres rækkefølge; løb og rodvogter gemmer fremgangen i små tidsskridt.

Der findes ingen generisk fortsætknap til en uløst opgave. Hints har tre trin; det sidste viser ét korrekt deltrin. Læsning har ingen tidsfrist. De nye spil med timing kan gentages og bliver langsommere med rolig bevægelse.

## Grafik og mobilinput

`WorldView` fylder hele skærmen med sceneillustrationen og bruger langsom zoom/panorering, krydsfade, lys, ildfluer, sommerfugle og damp. `living_picture.gdshader` flytter blikket ganske lidt i specifikt markerede øjenområder i udvalgte illustrationer. Disse effekter slås fra ved rolig bevægelse; søgebilleder og forskelsgåder fryses under undersøgelsen.

`GrimoireView` viser tre illustrerede opslag med faktalister. Hele teksten er tilgængelig, og et ord ad gangen får gyldent lys i læseretningen. Læseren kan pause, starte forfra, rulle eller bladre videre. Læsepositionen gemmes løbende. Dagbogen kan åbne bogen i en separat runtime med et hukommelsesbaseret SaveStore; læsning dér ændrer ikke eventyrets fremgang. `AdventureView` tegner de nye spil oven på scenen; `PuzzleView` håndterer de bevarede oprindelige handlinger. Forskelsgåden bruger ét fælles, stillestående motiv med præcis fem ændringslag.

Replikker skrives frem bogstav for bogstav. Første tryk viser hele replikken, næste går videre. Korte replikker får smallere felter; lange passager placeres nederst. Tekstfelterne har farvede, gennemsigtige slør. Anvisninger ligger under spilområdet. Store bogstaver kan rulles inden i feltet.

Input og layout bruger CSS-pixels, mens Godot tegner med enhedens fulde pixeltæthed. `orientation: any` og sensororientering tillader både stående og liggende spil. Kontroller bygges igen ved rotation; løst indhold, valgte genstande, drejninger og gemt fremgang bevares. Træk har et tryk/vælg/placer-alternativ. Labyrinten har også retningsknapper, og gryden kan omrøres med en cirkel eller et tryk.

De mindste mål i sporjagten er bevidst små og skal findes med luppens faktiske 3× skærmforstørrelse. Puslespilsfelter følger brikkernes geometri. Almindelige knapper har mindst 48 pixels i højden. På meget små skærme er stående format mest rummeligt til pakning og læsning.

Farmen har separate baggrunde til stående og liggende format, genstande og Mos ovenpå. Gemningen bruger altid den kanoniske grund `[0.18, 0.30]`; `FarmView.anchor()` giver dens visuelle placering i hver komposition. Havevalget, rede, pynt, rutegave og blomster tilhører samme hus.

## Gemning og lyd

Version 2 gemmer hvert fysisk deltrin, før dets effekt vises. Den eksisterende webnøgle `liv-hjemveje-v1` beholdes for at finde version 1-gemninger. Migrering bevarer belønninger og afsluttede scener; kun ændrede, ufærdige opgaver nulstiller deres gamle trin. Et ikke påbegyndt eventyr får dragebogen som ny åbning.

Native gemning bruger midlertidig fil, validering, backup og erstatning. På web er localStorage-journalen autoritativ; IndexedDB/filen er fallback. Import validerer version, noder, scenetrin, endelige tal, koordinater, pakkeformer, valg og have/hus. Genbesøg bruger en separat `replay`-tilstand og ændrer ikke hovedfarmen uden spillerens udtrykkelige valg efter afslutning.

Fire musiksløjfer følger stemningen med krydsfade. Rune-melodier har egne toner. Musik/effekter kan slås fra hver for sig, og lyd pauses ved appskift. Valgfri oplæsning bruger enhedens danske systemstemme; den er ikke nødvendig for at spille.

## Byg og kontrollér

```bash
godot --headless --editor --import --quit
mkdir -p test-results
godot --headless --script tests/test_chapter.gd
godot --headless --script tests/test_layouts.gd
godot --headless --script tests/test_adventure.gd
./tools/export_web.sh
python3 -m http.server 8765 --directory builds/web
```

`test_chapter.gd` gennemfører AA, AB, BA og BB og genindlæser efter hvert deltrin. Den kontrollerer permanente belønninger, genbesøg, alle haveniveauer og ugyldig import. Den skriver checkpoints til de følgende browserprøver. `test_adventure.gd` prøver blandt andet fejl i pakning, nøgler, sekvenser, timing, rute og migrering. `test_layouts.gd` kontrollerer alle sceners trykpunkter i otte formater fra 568 × 320 og 320 × 568 til iPad.

En debug-eksport har `window.__livQA`: kun læsning af tilstand, inputkoordinater og animationsfase. Ingen funktion kan springe over eller løse en gåde. Browserprøverne bruger almindelige touch-, træk- og musehændelser.

```bash
mkdir -p builds/qa
godot --headless --export-debug Web builds/qa/index.html
python3 -m http.server 8766 --directory builds/qa
# I en anden terminal med Playwright og Chromium installeret:
ROUTE=AA node tests/adventure-play.cjs
ROUTE=BB node tests/adventure-play.cjs
node tests/adventure-mobile.cjs
node tests/adventure-visual.cjs
```

Mobilprøven drejer enheden med en valgt brik, bevarer pakkerotation, bruger luppen, bladrer ved 150 % tekst og planter i samtlige 16 jordfelter. Visuelle prøver gemmer skærmbilleder til gennemgang. `PLAYWRIGHT_PATH` kan angive et eksisterende Playwright-modul. `browser.cjs`, `mobile.cjs` og `orientation.cjs` er kompatible indgange til de opdaterede prøver.

`tests/release.cjs` bruger registrerede trykpunkter mod den faktiske release, som ikke indeholder diagnosefladen. Den kontrollerer berøring, en delvist læst bog, manifest, installationshjælp og fuld offline-genstart. `RELEASE_ORIENTATION=landscape` vælger den liggende prøve. Koordinaterne opdateres fra debug-eksporten med `CAPTURE_CONTROLS=1 GAME_URL=http://127.0.0.1:8766`.

## Hjemmeskærm og udgivelse

`prepare_pwa.py` tilføjer manifest, ikon og en versionsbestemt service worker. Hele eksporten hentes til én cache, før den aktiveres. Opdatering bruger netværksgenhentning og venter, til gamle spilvinduer er lukket. Motor og indhold blandes derfor ikke, og spillerens gemning ligger separat. `tests/pwa-update.cjs` kontrollerer dette forløb med varm HTTP-cache og offline-genstart.

Den offentlige version ligger på `gh-pages`. `deploy-pages.yml` udgiver de færdige eksportfiler gennem GitHub Actions. Kildekode, tests og original-PDF indgår ikke på spilsiden. Nye ZIP-pakker gemmes også i udgivelsesgrenens `downloads/`. Installeret hjemmeskærmsapp kræver Safari/Chrome-installation; der er ingen App Store/Google Play-pakke.
