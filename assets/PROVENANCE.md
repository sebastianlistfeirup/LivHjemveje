# Grafik, skrifter og lyd

- `chapter_01/K01_B01.webp`–`K01_B30.webp`: alle 30 originale sceneillustrationer fra den indlejrede `Codex_Input.zip` i repositoryets v1.0-PDF. Uændret komposition og 1024 × 1536 pixels, konverteret til WebP ved kvalitet 88. Ingen genereret dansk tekst er tilføjet billederne.
- `characters/mos-atlas.png`: seks nye, transparente stillinger af Mos, genereret med originalens fælles figurreference. Hvil, se, blink, stræk vinge, naturpust og gå. Atlas: 3 × 2 felter à 512 pixels.
- `farm/farm.webp`: ny, separat farmbaggrund uden dragehuse eller beboere, genereret med den originale Rodhytteillustration som stilreference. Vedvarende objekter tegnes ovenpå.
- `farm/objects.png`: nye transparente lag til Rodhytten, piledammen, moslunden og et tomt bed, baseret på originalens Rodhytteillustration.
- `ui/*.svg`: originale vektorobjekter til håndtering, værktøjer, spor og præcise gåder. Kilden findes i `tools/make_assets.py`.
- `ui/app-icon.png`: nyt appikon med Mos og kompasset, genereret med Mos-atlasset som figurreference.
- `adventure/*.webp`: 18 nye baggrunde og illustrationer til den magiske bog, rejsekortet, køkkenet, tågeskoven, rødderne, runeporten, frøens handel, miksturen, elementerne, sporstenen, rodvogteren, brønden, Ibens brev, nøgleskabet, mødet ved brønden og farmens landskabsformat. Genereret med OpenAI ImageGen til denne udgave; farmen og brøndmødet bruger de originale billeder som kompositions- og figurreference. Alkymiscenen har tre matchende versioner: før brygningen, turkis omrøring og færdig gyldengrøn solminde. Billederne er kodet som WebP; dansk tekst tegnes af spillet.
- `adventure/garden-treasures.png`: seks transparente, individuelt illustrerede frø og blomster til haven: ravfrø/guldlilje, stjernefrø/blåviolet stjerneblomst og rosenfrø/koralrose. Genereret med OpenAI ImageGen i et 3 × 2-atlas.
- `adventure/treasures.png`: nyt transparent 4 × 4-atlas med gryde, mikstur, dug, blomst, taske, reb, lanterne, ske, ild, vand, blad, sten, kam, nøgle, måne og rune. Genereret med OpenAI ImageGen.
- `adventure/props.png`: nyt transparent 2 × 2-atlas med lup, bog i drageskind, kompas og rod. Genereret med OpenAI ImageGen.
- `audio/`: fire originale, proceduralt komponerede musiksløjfer og fire syntetiserede handlingslyde. `woodland`/`evening` kommer fra `tools/make_audio.py`; `playful`/`danger` fra `tools/make_adventure_music.py` (NumPy og FFmpeg). Ingen eksterne musikoptagelser.
- Nøglernes præcise tænder, låseprofilen, rute, labyrint og spor tegnes deterministisk af spillet, så løsningerne er entydige. Nye replikker og dragebog er skrevet til denne udvidelse i `tools/make_adventure.py`.
- `fonts/`: Noto Sans, Noto Serif og DejaVu Sans-symbolfallback. De medfølgende licensfiler skal følge distributionen.

Original-PDF: `418c882b07ffe5fb2ed9ef66040a2f2e2fdbdec0c27532a585719b157314c1ea` (SHA-256). Alle 30 originale illustrationer bevares. Enkelte scener bruger nye brede kompositioner i liggende format.
