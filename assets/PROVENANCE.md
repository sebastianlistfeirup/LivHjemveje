# Grafik, skrifter og lyd

- `chapter_01/K01_B01.webp`–`K01_B30.webp`: alle 30 originale sceneillustrationer fra den indlejrede `Codex_Input.zip` i repositoryets v1.0-PDF. Uændret komposition og 1024 × 1536 pixels, konverteret til WebP ved kvalitet 88. Ingen genereret dansk tekst er tilføjet billederne.
- `characters/mos-atlas.png`: seks nye, transparente stillinger af Mos, genereret med originalens fælles figurreference. Hvil, se, blink, stræk vinge, naturpust og gå. Atlas: 3 × 2 felter à 512 pixels.
- `farm/farm.webp`: ny, separat farmbaggrund uden dragehuse eller beboere, genereret med den originale Rodhytteillustration som stilreference. Vedvarende objekter tegnes ovenpå.
- `farm/objects.png`: nye transparente lag til Rodhytten, piledammen, moslunden og et tomt bed, baseret på originalens Rodhytteillustration.
- `ui/*.svg`: originale vektorobjekter til håndtering, værktøjer, spor og præcise gåder. Kilden findes i `tools/make_assets.py`.
- `ui/app-icon.png`: nyt appikon med Mos og kompasset, genereret med Mos-atlasset som figurreference.
- `audio/`: to originale 48-sekunders, proceduralt komponerede musiksløjfer og fire syntetiserede handlingslyde. Ingen eksterne musikoptagelser. Generator: `tools/make_audio.py` (NumPy og FFmpeg).
- `fonts/`: Noto Sans, Noto Serif og DejaVu Sans-symbolfallback. De medfølgende licensfiler skal følge distributionen.

Original-PDF: `418c882b07ffe5fb2ed9ef66040a2f2e2fdbdec0c27532a585719b157314c1ea` (SHA-256). De nye billeder erstatter ingen af de 30 originale fortællescener.
