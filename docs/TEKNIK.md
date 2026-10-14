# Kapitel 1 — teknisk overblik

Motoren er **Godot 4.6.3 stable**, GDScript og Compatibility-rendering. Webeksporten bruger én tråd og kræver derfor ikke COOP/COEP-headere. Der er ingen backend, konti, telemetri eller køb. Indholdet kan også køres direkte i Godot på en computer.

## Fortælling og controllere

`content/source/Spildata.json` er den uændrede kilde med alle 400 scenenoder. `tools/make_runtime.py` udleder kapitel 1 og tilføjer **40 konkrete scenekonfigurationer og 53 handlingstrin** i `content/runtime/chapter_01.json`. Fortæller, replikker, slutreplikker, side-ID'er, billed-ID'er og `next` bevares fra kilden.

`StoryRuntime` er tilstandsmaskinen; den bruges både af spillet og rutetesten. De eksplicitte controllere er undersøg, sekvens, placer, drej, render, valg, graf-labyrint, rens, fem forskelle, fri placering og album. Ukendte controllere udløser en udviklerfejl. Der findes ingen generisk Fortsæt-erstatning for en uløst handling.

Læsning består af fortæller, to oprindelige replikker, handling og oprindelig slutreplik. Læsning har ingen tidsfrist. Figurernes små reaktioner og hint er supplerende; de oprindelige replikker er ikke omskrevet. Taleboblerne kan genlæses, og tidligere besøgte sider findes i dagbogen.

S08 og S22 gemmer A/B før overgangen. Begge grene samles ved henholdsvis S13 og S27. Et gennemløb har 36 noder, og de fire kombinationer dækker alle 40. S32 registrerer Mos og hjemvejen, S35 huset, S38 gaven og redningsdetaljen, S40 kapitelafslutning og fri farm. Kapitel 2 markeres som opdaget, men er ikke implementeret og starter aldrig automatisk.

## Grafik og input

De oprindelige illustrationer vises ubeskåret i 2:3. Brede skærme får tekst ved siden af billedet; telefoner får et tekstfelt, som tilpasses den aktuelle replik. Ved 125/150 % tekst kan feltet rulles. Alle nødvendige mål har mindst 48 logiske pixels. På meget små eller lave skærme udvides de præcise gådeudsnit, så genstandene fortsat kan betjenes.

Webversionen tegner ved skærmens fulde pixeltæthed, men bruger CSS-pixels til layout og input via Godots canvas-skalering. Derfor har en iPhone med DPR 3 samme 390-pixel brede betjening som en 390-pixel browserprøve, samtidig med at billeder og tekst tegnes skarpt. Skift af orientering genberegner størrelsen. Portrættilstand afhænger også af forholdet mellem højde og bredde, så en stående 820-pixel iPad beholder portrætlayoutet. Prøverne omfatter DPR 1, 2 og 3 samt rotation med et gemt bed åbent.

Scenegenstande, overlays og input bruger samme `art_rect` eller eksplicitte `closeup_rect`. En trækhandling har tryk-på-ting/tryk-på-mål som alternativ. Labyrinten bruger kun de 11 kanter i `maze-1`. De tre L-formede render har synlige åbne ender og faktisk orientering; vandet standser ved første brud. G01's lige render accepterer begge vandrette orienteringer.

Forskelsgåden er ét deterministisk nært diagram med fem separate ændringslag inden for de originale normaliserede mål. Alt andet i sammenligningsfeltet er identisk og uden animation. Skift mellem plan og ankomst er eksplicit, og fund markeres i begge visninger.

`WorldView` giver lokalt støv, lys, ildfluer, vandringe og succespartikler. `PuzzleView` viser objekters tilstand og flytning. Mos har seks særskilte stillinger og blink, små bevægelser samt naturpust på farmen. Rolig bevægelse slukker bevægelse og partikler; løsninger og statisk feedback består.

Farmen har en separat baggrund og selvstændige objekter. Den gemte grund er altid `house_01.position = [0.18, 0.30]`. `FarmView.ART_ANCHORS` er den faste projektion til det nye skrå oversigtsbillede, hvis malede geometri afviger fra det konceptuelle kort. Projektionen ændres aldrig af spillerens valg. Den valgte have, rede, pynt, gave, redningsdetalje og blomster tilhører samme grund.

## Gemning og genbesøg

Hvert deltrin gemmes, inden reaktionen afspilles. En versioneret JSON-envelope indeholder `data` og en eventuel separat `replay`. Native gemning skriver en midlertidig fil, validerer den, beholder backup og erstatter hovedfilen. På web er det synkrone localStorage-journal autoritativt, fordi Godots IndexedDB-filsynkronisering kan være forsinket ved en øjeblikkelig genindlæsning. Fil og backup er fallback.

Importer valideres før tilstanden ændres: version, node-ID'er, scenetrin, tal, koordinater, valg, hus, album og havetilstand. Eksport/import findes i indstillinger. En blokeret lagerplads giver en synlig besked med mulighed for eksport.

Genbesøg starter med en ny kapiteltilstand og egne delmål. Hovedfarmen ændres ikke. Efter et afsluttet genbesøg kan spilleren udtrykkeligt vælge den nye have/gave eller vende hjem til sin oprindelige farm.

G01 gemmer frø og rør efter hvert input. De tre niveauer er 3 felter, 6 felter og et frit 4 × 4-bed. Tre arrangementspladser kan gemmes og vælges som varig pynt. Ingen plante visner ved fravær.

## Lyd

Lyd afbrydes, når spillet mister fokus, og musik genoptages efter spillerens indstillinger. Sceneskift har en kort billedovergang; berøringer har ringe og handlinger har selvstændig feedback. Rolig bevægelse fjerner disse effekter.

Musik og effekter kan indstilles hver for sig. Musikken looper; den starter efter første brugerhandling. Valgfri dansk oplæsning bruger browserens/enhedens danske stemme. Hvis ingen dansk stemme er installeret, fortæller spillet det og bevarer den samme læseoplevelse. Ingen gåde afhænger af lyd, vibration eller timing.

## Byg og kontrollér

`tools/prepare_pwa.py` tilføjer manifest, Mos-ikon og en versionsbestemt service worker. Hele eksporten lægges i én cache, før offline-udgaven aktiveres. Nye versioner venter, til åbne spilvinduer er lukket, så motor og indhold ikke blandes. Spillerens gemmefil ligger separat og slettes aldrig af cacheopdatering. Installation er en hjemmeskærmsapp, ikke en udgivelse i App Store/Google Play. Safari/iOS' installations- og lageradfærd skal stadig prøves på fysisk enhed.

Den kompakte have bruger hele den ledige bredde og en separat vandret opsætning på lave skærme. Alle 16 jordfelter og hver frøtype kontrolleres med berøringshændelser i `tests/mobile.cjs`; prøven slår derefter nettet fra og genåbner spillet med det gemte bed.

Den offentlige udgave ligger på `gh-pages`. Repositoryets Pages-kilde er GitHub Actions; `deploy-pages.yml` udgiver den færdige eksport ved push til denne gren. Workflowet findes også på udgivelsesgrenen. Kildekode og tunge originalpakker indgår ikke på spilsiden. Ved opdatering bygges og kontrolleres spillet med `export_web.sh`, hvorefter eksportfilerne erstattes på `gh-pages`, mens `.github/workflows/deploy-pages.yml` bevares.

```bash
godot --headless --editor --import --quit
mkdir -p test-results
godot --headless --script tests/test_chapter.gd
./tools/export_web.sh
python3 -m http.server 8080 --directory builds/web
```

Web-export templates skal være installeret til Godot 4.6.3. Browserprøver køres mod en **debug-eksport**; kun den har `window.__livQA`, et skrivebeskyttet udsnit af tilstand og kontrolkoordinater. Der er ingen spring-over- eller løs-gåden-funktion i diagnosefladen. Browserprøverne bruger rigtige mus-/touchhændelser.

```bash
godot --headless --export-debug Web builds/web/index.html
python3 tools/prepare_pwa.py
GAME_URL=http://127.0.0.1:8080 ROUTE=BB node tests/browser.cjs
GAME_URL=http://127.0.0.1:8080 ROUTE=AA MOBILE=1 node tests/browser.cjs
GAME_URL=http://127.0.0.1:8080 node tests/mobile.cjs
```

Efter `./tools/export_web.sh` kontrollerer `node tests/release.cjs` den faktiske release-udgave med berøringer, gemning midt i første gåde og en fuld offline-genstart. Den sikrer også, at diagnosefladen er fjernet. `tests/release-controls.json` indeholder de registrerede trykpunkter til den faste 390 × 844-prøve.

Installér Playwright lokalt, eller sæt `PLAYWRIGHT_PATH` til dets modul. `CHROMIUM_PATH` kan angive en installeret Chromium. Slutleverancen er en release-eksport uden diagnosefladen.
