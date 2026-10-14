# Status — kapitel 1

## Implementeret

- Alle 40 noder, alle originale replikker, 30 originale sceneillustrationer og de fire 36-siders gennemløb AA, AB, BA og BB.
- Konkrete scenehandlinger: spor, pakning, værktøjer, plankebro, kompas, graf-labyrint, vandrender, oprydning, præcis forskelsgåde, to redninger, frøenes vej op og hjemkomst.
- Rodhytten, piledam/moslund, fri placering af rede, sten/bladskilt, eksklusiv rutegave, reb/bænk og album med eget stempel.
- Fri farm med Mos, seks figurstillinger, blink, reaktioner, husindretning, dagbog og rejsekort.
- Mos’ levende have i tre størrelser, vandpreview, naturpust, fri blomstertegning og tre gemte arrangementer.
- Automatisk gemning af deltrin, genoptagelse, backup, eksport/import og genbesøg isoleret fra hovedfarmen.
- Mus og touch, tryk/tryk-alternativ til træk, tastaturfokus, 100/125/150 % tekst, rolig bevægelse, musik, effekter og valgfri oplæsning/vibration.
- Selvstændig Godot-webeksport og projekt, som kan køres i Godot 4.6.3.
- Liggende telefon og iPad som anbefalet format, fuldt stående layout og fri skærmrotation midt i gåder og haveleg.
- Hjemmeskærmsapp med eget Mos-ikon, hele kapitlet til spil uden net og lydpause ved appskift.

## Afgrænsninger

- Kapitel 2–10 er manuskript og fremtidigt indhold. De kan ikke startes i denne version.
- Originale scener er malede billeder med nye interaktive lag og miljøeffekter. Der er ikke et fuldt figur-rig eller en særskilt ansigtsanimation for alle Livs og Noors positurer.
- Dansk oplæsning afhænger af en installeret systemstemme; der er ikke indtalte skuespillerstemmer.
- Browserprøver omfatter Chromium med emuleret touch og flere vinduesstørrelser. En fysisk iPhone/Android-enhed og en gennemspilning med Liv er endnu ikke afprøvet. Det er den resterende brugerprøve, især for læsetempo, scroll ved stor tekst og enhedens lyd/lager.
- Godots WebGL 2-runtime skal hentes første gang. Et statisk webhotel skal servere `.wasm` som `application/wasm`; HTTPS anbefales til normal brug.

Se `TEKNIK.md` for opbygning og kontrolkommandoer og `assets/PROVENANCE.md` for grafik og lyd.
