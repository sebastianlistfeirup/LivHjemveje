# Verifikation af kapitel 1 · 2.0.0

Kontroller udført 14. oktober 2026 med Godot 4.6.3 og Chromium/Playwright. Den spilbare fortælling har 53 scener, 70 interaktionstrin og ni valgsteder; hvert af de fire hovedforløb besøger 49 scener.

## Indhold, regler og gemning

- `tests/test_chapter.gd`: 2.914 kontroller, ingen fejl. AA, AB, BA og BB; genindlæsning efter hvert deltrin; permanente belønninger, farm, genbesøg og tre haveniveauer.
- `tests/test_layouts.gd`: 5.824 kontroller, ingen fejl. Trykpunkter inklusive bogens bladreknap i otte skærmformater fra 320 × 568 til 1180 × 820.
- `tests/test_adventure.gd`: 47 kontroller, ingen fejl. Blandt andet forkerte nøgler og tre brugte forsøg efter genindlæsning, fejl i sekvenser og pakning, vægge i labyrinten, vogterens reaktion, migrering, blokeret import og bevarelse af scenens skrevne slutreplik. Valgsvar får den korrekte afsender.

I alt **8.785 automatiske kontroller**. Produktionsbygningen kører alle tre sæt før eksport.

## Spil med faktiske inputhændelser

`tests/adventure-play.cjs` gennemførte AA og BB med touch, træk og timinginput: 49 scener hver, alle respektive udfordringer, hjemkomst, tre havestørrelser og eksport af gemt spil. Ingen JavaScript-/browserfejl blev registreret. Diagnosefladen læser kun tilstanden; den kan ikke løse eller springe over opgaver.

`tests/adventure-mobile.cjs` bestod ved:

| Format | Pixeltæthed | Kontroller |
|---|---:|---|
| 390 × 844 | 3× | Telefon, begge orienteringer |
| 820 × 1180 | 2× | Tablet, begge orienteringer |
| 568 × 320 | 1× | Lille telefon, begge orienteringer |

Prøven drejer en valgt puslespilsbrik og en roteret taske-genstand, genindlæser fremgang, bruger luppen, læser alle tre bogopslag fra dagbogen uden at ændre eventyret, bladrer ved 150 % tekst og planter samtlige 16 jordfelter med rotation undervejs.

Grafikken gennemgås på skærmbilleder fra spillets egen renderer: fuldskærmsmotiver, tekstplacering, bog, kort, nøgleprofiler, minispil og have. Miksturen er kontrolleret i sine tre billedstadier. Bogens gemte ordposition er også kontrolleret med automatisk rulning til det relevante tekststed.

## Færdig webudgave og opdatering

Den faktiske release uden diagnoseflade bestod `tests/release.cjs` både stående (390 × 844) og liggende (844 × 390), med 3× pixeltæthed. Kontrollen bruger almindelige tryk, gemmer midt i dragebogen, kontrollerer installationsmanifest og iPhone-hjælp, genstarter hele spillet uden net og fortsætter den samme bog. Ingen browserfejl.

`tests/pwa-update.cjs` bestod: en ny version hentes trods varm HTTP-cache, det allerede åbne spil beholder sammenhængende gamle filer, og gemningen overlever skiftet til den nye udgave og en offline-genstart.

Den pakkede eksport fylder 73,2 MiB. Service worker-version: `c5bdff41c4828312`.

- `index.pck` SHA-256: `14496af1e38353d6ef42f02ab8752f9c11a275e6675c5a78e253d6e9d1f9b8c7`.
- `LivHjemveje-Kapitel-1-v2.0.0-Web.zip`: 47.706.256 bytes; SHA-256 `f617f2501a7a8c8b1c6b1b3f231d649d341119563cfb9ec53ad44a2271369215`. ZIP-kontrollen fandt ingen CRC-fejl; den indeholder samme PCK som den afprøvede release, spillevejledning og tredjepartslicenser.

## Praktisk afgrænsning

Kontrollerne bruger emuleret touch i Chromium med softwaregrafik. De erstatter ikke en afprøvning på fysisk iPhone/iPad eller en gennemspilning med Liv. Kapitel 2–10 er endnu ikke udgivet. Spillet kræver WebGL 2; offlinebrug kræver første fulde indlæsning.
