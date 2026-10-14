"""Authored expansion. The original production package remains untouched.

Generate deterministic chapter additions, including a real maze with dead ends.
Run after make_runtime.py; AdventureBook merges this overlay at load time.
"""
import json
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
patches = {}
extra = []


def item(id, label, icon=None, **kw):
    return dict(id=id, label=label, icon=icon or id, **kw)


def stage(kind, prompt, items=None, **kw):
    return dict(kind=kind, prompt=prompt, items=items or [], targets=[], **kw)


def lines(*pairs):
    return [dict(speaker=speaker, text=text) for speaker, text in pairs]


def update(n, **kw):
    patches[f'K01_S{n:02}'] = kw


def scene(n, title, image, narrator, dialogue, stages, success, following, music='wonder'):
    extra.append(dict(id=f'K01_S{n:02}', page=n, title=title, image_id=image,
                      narrator=narrator, dialogue=lines(*dialogue),
                      success_text=dict(speaker='Liv', text=success),
                      runtime=dict(stages=stages, coordinate_space='scene', overlay_status='implemented'),
                      next=dict(success=f'K01_S{following:02}'), music=music,
                      presentation=dict(anchor=['left', 'right', 'lower'][n % 3], focus=[.5,.43])))


def choice(key, prompt, options):
    return stage('choice', prompt, [item(i, label, icon, response=response, pos=[.2+j*.3,.5])
                                    for j,(i,label,icon,response) in enumerate(options)], key=key)


def maze():
    rng = random.Random(4721)
    width, height = 9, 7
    edges, seen, stack = [], {0}, [0]
    while stack:
        at = stack[-1]
        x, y = at % width, at // width
        candidates = [ny*width+nx for nx,ny in [(x-1,y),(x+1,y),(x,y-1),(x,y+1)]
                      if 0 <= nx < width and 0 <= ny < height and ny*width+nx not in seen]
        if candidates:
            nxt = rng.choice(candidates)
            edges.append([at,nxt]); seen.add(nxt); stack.append(nxt)
        else:
            stack.pop()
    return dict(width=width, height=height, edges=edges, start=0, goal=62)


update(1, wide_image='kitchen', presentation=dict(anchor='left', focus=[.5,.40]),
       narrator='Tre små bank. Så ét til. Jeg lagde hånden på gulvet. Noget dernede bankede tilbage.',
       dialogue=lines(('Liv','Edda? Hvis det her er en kat, har den lært et meget mærkeligt trick.'),
                      ('Edda','Lyt godt efter, Liv. Nogle døre åbner kun for den, der svarer.'),
                      ('Liv','Så svarede jeg. Og et sted under mine fingre begyndte noget at lyse.')))
update(2, append_stages=[choice('edda_spoergsmaal','Edda bliver pludselig stille. Hvad vil du vide?',[
    ('owner','Hvem havde det?','key','Edda: Iben. Hun kunne finde en vej, selv når alle andre kun så en mur.'),
    ('magic','Hvor fører det hen?','moon','Edda: Til nogen, der savner et hjem. Kompasset kender dem før os.'),
    ('promise','Må jeg beholde det?','leaf','Edda: Ja. Hvis du lover at lytte, før du bestemmer, hvor andre hører til.')])])
update(3, wide_image='kitchen', title='Kortet i seks stykker',
       narrator='Noor trak kortet frem for at finde porten. Det kom ud i seks stykker. Den gyldne streg glimtede stadig, men nu løb den i seks forskellige retninger.',
       dialogue=lines(('Noor','Jeg ville bare folde det lidt mindre. Det blev meget mindre.'),
                      ('Liv','Så samler vi vejen igen. Se — mit navn lyser stadig.'),
                      ('Noor','Godt. Jeg ville nødig følge en vej, der ender i min lomme.')),
       stages=[stage('jigsaw','Træk de seks kortbrikker på plads. Se på stierne og billedets kanter.', image='map', columns=3, rows=2)],
       success_text=dict(speaker='Liv',text='Der var brønden igen. Stjernen. Den lille grønne dør. Kortet var helt, tasken var pakket, og nu vidste vi, hvor vi skulle begynde.'))
update(4, image_id='runes', stages=[stage('runes','Se runerne lyse. Spil derefter deres melodi. Du kan høre den igen.',
    [item('leaf','Blad'),item('moon','Måne'),item('fire','Flamme'),item('water','Vand')],
    sequences=[['leaf','moon','water','fire'],['water','leaf','fire','moon','leaf','water']])],
    dialogue=lines(('Liv','Fire tegn. Ingen nøgle.'),('Noor','Hør … porten synger! Måske skal vi svare med den samme melodi.'),('Liv','Okay, port. Vi tager den lige én gang til.')))
update(5, next=dict(success='K01_S41'),
    stages=[stage('search','Lunden gemmer tre spor. Flyt luppen over billedet, og tryk dér, hvor du finder noget.',
        [item('scratch','Et frisk klomærke','scratch',pos=[.21,.33]),
         item('thread','En blå tråd i barken','thread',pos=[.72,.54]),
         item('scale','Et lille grønt skæl','scale',pos=[.48,.79])])],
    success_text=dict(speaker='Noor',text='Blå tråd. Grønne skæl. Og spor, som stopper midt på stien. Der er nogen, der har forsøgt at skjule vejen.'))
scene(41,'Kortet, tågen spiser','mist',
      'Tågen gled hen over kortet. Stierne forsvandt én efter én. Kun når kompasset lyste, kunne vi se dem igen.',
      [('Noor','Jeg husker bollen i min taske. Resten må du hjælpe med.'),
       ('Liv','Vi ser på kortet sammen. Så følger vi lyset, inden tågen tager det.'),
       ('Noor','Og hvis vi går forkert, ser vi bare igen. Aftale?')],
      [stage('memory_map','Husk lysstien. Når tågen falder, fører du lyset frem. »Se kortet« viser det igen.',
             route=['up','right','up','left','up','right','right','up'], width=5, height=5, start=[0,4])],
      'På den anden side ventede en frø. Den så ud, som om den havde ventet meget længere end os.',6)
update(6, wide_image='frog', narrator='En frø sad højt på en rusten vandkande. Den havde stillet tre skatte foran sig og nægtede at flytte sig.',
       dialogue=lines(('Frø','Ingen krydser min bæk uden at løse min gåde!'),
                      ('Liv','Der er jo ikke noget vand i den.'),
                      ('Frø','Principper, unge menneske. Principper bliver ikke tørre.')),
       stages=[stage('riddle','Jeg har tænder, men bider aldrig. Jeg går gennem hår, men har ingen fødder. Hvad er jeg?',
          [item('comb','En gylden kam',response='Frø: Korrekt. Mine egne krøller er ganske vist usynlige.'),
           item('key','En gammel nøgle',response='Frø: Den har tænder, ja. Men jeg ville ikke rede hår med den. Prøv igen.'),
           item('moon','En perlemåne',response='Frø: Smuk. Men månen lader vist andre om frisurerne.')],answer='comb')],
       next=dict(success='K01_S42'), success_text=dict(speaker='Frø',text='En kam! Jeg vidste, I havde forstand på noget. Så kan vi tale forretning.'))
scene(42,'En meget rimelig frø','frog',
      'Frøen ville bytte et vådt blad for en historie. Den fandt en lille messingvægt frem. Jeg spurgte ikke, hvor den havde haft den.',
      [('Frø','For lidt historie er kedeligt. For meget historie gør mig søvnig.'),
       ('Noor','Så handler vi om en helt tilpas mængde eventyr.'),
       ('Liv','Tre gode sætninger. Du får endda en drage med i den sidste.')],
      [stage('balance','Stop vægtens lys i det gyldne felt. Tre gode handler giver jer det våde blad.', goal=3)],
      'Frøen lagde bladet i min hånd. »Det lugter af den lukkede kilde,« hviskede den. »Nogen ønsker, at lunden glemmer sin vej.«',7,'playful')
update(8, presentation=dict(anchor='lower',focus=[.5,.4]))
update(10, next=dict(success='K01_S43'))
update(11, stages=[stage('labyrinth','Find dugkoppen i rodgangen. Træk langs stierne, eller brug pilene. Der er mange blindgyder.', maze=maze())])
update(12, next=dict(success='K01_S43'))
scene(43,'Rødderne vågner','roots',
      'Først troede jeg, at jorden rystede. Så så jeg roden løfte sig. Hele stien var ved at lukke sig bag os.',
      [('Noor','Liv. Den her sti har alt for mange ben.'),
       ('Liv','Følg ildfluerne! De ved, hvor der er plads.'),
       ('Noor','Så håber jeg, de ved, at jeg ikke kan flyve!')],
      [stage('runner','Stryg til siden mellem de tre spor. Undvig rødderne, og saml mindst tre ildfluer.', duration=16)],
      'Vi væltede ud i en lysning. Bag os faldt rødderne til ro. Foran os trak nogen vejret, ganske forsigtigt.',13,'danger')
update(13, wide_image='well-meeting', presentation=dict(anchor='left',focus=[.5,.42]),
       narrator='Vi genkendte brønden fra bogens tegning. På kanten lå noget grønt og sammenkrøllet. Så åbnede to gyldne øjne sig. Bogen havde ikke vist, hvor bange en drage kunne se ud.',
       dialogue=lines(('Liv','Bladvinger. Barkskæl. Det må være ham.'),
                      ('Noor','Sådan så han ikke ud i bogen.')),
       success_text=dict(speaker='Liv',text='Vi har fundet ham. Nu skal vi finde ud af, hvordan vi hjælper.'))
update(15, next=dict(success='K01_S44'),
       success_text=dict(speaker='Liv',text='Renderne passer. Men hvorfor kommer vandet ikke? Se — der sidder en lås under slusen.'))
scene(44,'Ti nøgler og tre forsøg','key-cabinet',
      'Renderne var åbne, men vandet stod stadig stille. Et nøgleskab hang under slusen. Ti nøgler. Én lås. På låsen lyste tre små stjerner.',
      [('Noor','Tre stjerner, tre forsøg, før låsen falder i søvn. Vi skal se os godt for.'),
       ('Liv','Se rillerne inde i låsen. Nøglens fire tænder skal have præcis de samme højder.'),
       ('Noor','Du kan undersøge alle nøglerne først. Det tæller kun, når du prøver én i låsen.')],
      [stage('keymatch','Undersøg låsens fire riller. Vælg blandt ti nøgler. Du har tre forsøg.',
             [item('key_'+str(i), 'Nøgle '+str(i+1), teeth=teeth) for i,teeth in enumerate([[1,2,3,1],[3,1,2,3],[2,3,1,2],[1,3,2,3],[2,1,3,1],[3,2,1,3],[1,3,2,1],[2,3,1,3],[3,1,3,2],[1,2,1,3]])], answer='key_6', attempts=3),
       stage('lock','Nøglen passer! Stop lyset i den gyldne åbning for at dreje låsens tre stifter.',goal=3)],
      'Klik. Klik. Klik. Et tyndt bånd af vand fandt vej gennem stenen. Fra brønden lød et lille, lettet suk.',16,'danger')
update(16, title='Lad ham fortælle selv',
       narrator='Bogen kaldte ham Mos. Alligevel ville jeg høre det fra ham selv. Noor havde også et navneforslag. Et meget langt et.',
       dialogue=lines(('Noor','Hvad med Sir Grønspids den Tredje?'),
                      ('Liv','Måske kan han bedre lide sit eget navn. Vi spørger.')),
       stages=[choice('samtaletone','Dragen ser på dig. Hvordan vil du begynde?',[
    ('ask','Spørg helt stille','leaf','Liv: Du behøver ikke være modig lige nu. Hvad hedder du?'),
    ('wait','Vent ved dens side','moon','Vi sagde ingenting. For første gang slap dragen øjnene fra den lukkede port.'),
    ('joke','Fortæl noget fjollet','comb','Liv: Jeg hedder Liv. Jeg var egentlig på udkig efter en kat. Dragen pustede næsten en latter.')])])
update(17, next=dict(success='K01_S45'))
scene(45,'En skefuld stjernelys','alchemy',
      'Mos skubbede en opskrift hen til os. Under det store træ stod en sort gryde. På siden var den samme stjerne som på mit kompas.',
      [('Mos','Rødderne er bange. Giv dem noget, der husker solen.'),
       ('Noor','To dråber dug. En stjerneblomst. Tre rolige omrøringer …'),
       ('Liv','… og en dråbe månemos. Det er godt, vi tog en ske med!')],
      [stage('potion','Bryg solminde: 2 dugdråber, 1 stjerneblomst, rør 3 gange, og tilsæt månemos.',
          [item('dew','Dugdråbe'),item('flower','Stjerneblomst'),item('bottle','Månemos')],
          recipe=['dew','dew','flower','stir','stir','stir','bottle'])],
      'Gryden sendte små lys op mellem bladene. Da de landede på rødderne, blev deres greb en anelse blødere. Mos så på mig, som om jeg havde tændt solen.',18,'wonder')
extra[-1]['presentation']=dict(anchor='left',focus=[.76,.43])
update(18, next=dict(success='K01_S46'),
       narrator='Jeg ville hjælpe så hurtigt, at min hånd allerede var på vej mod vingen. Mos foldede sig sammen. Så huskede jeg bogens advarsel. Jeg standsede og prøvede at se problemet fra hans side af brønden.')
scene(46,'Tre kræfter i én rod','elements',
      'Miksturen havde vækket rodens gamle vogtere: ild, vand og jord. De dansede foran os. Hver kraft ventede på den, der kunne bringe den til ro.',
      [('Mos','Vand dæmper ild. Jord samler vand. Ild løsner jord.'),
       ('Noor','Det er sten-saks-papir. Bare med væsentlig mere jord på skoene.'),
       ('Liv','Vi behøver ikke vinde over skoven. Vi skal få den til at lytte.')],
      [stage('elements','Vælg kraften, der skaber balance. Vand dæmper ild · jord samler vand · ild løsner jord.',
          [item('fire','Ild'),item('water','Vand'),item('stone','Jord')],opponents=['fire','water','stone'])],
      'Den sidste flamme blev til en varm gnist. Vogterne sænkede deres lys. Nu kunne vi komme tæt på roden uden at skade Mos.',19,'danger')
update(20, next=dict(success='K01_S47'))
scene(47,'Den, der overstregede stjernen','clues',
      'Under det blå kridt var der ridset noget ganske småt. Tre tegn. Ikke en ordre. En besked til den næste, der ville lede.',
      [('Noor','Der er et mærke helt inde i revnen. Har du Eddas lup?'),
       ('Liv','Ja. Og nu vil jeg vide, hvem der har prøvet at viske det væk.'),
       ('Noor','Se langs kanterne. Det er der, hemmeligheder gemmer sig.')],
      [stage('search','Undersøg stenen med luppen. Find den lille stjerne, det blå segl og det skjulte blad.',
          [item('star','En stjerne under kridtet','rune',pos=[.27,.23]),
           item('seal','Et lille blåt segl','thread',pos=[.73,.62]),
           item('hidden_leaf','Et blad i en revne','leaf',pos=[.44,.79])])],
      '»Lukket er ikke det samme som tryg,« stod der mellem tegnene. Jeg gemte ordene. Jeg havde en fornemmelse af, at Edda ville genkende dem.',21)
update(22, narrator='Vi kunne løfte roden med rebet eller støtte den nedefra med klodser. Mos fulgte vores hænder med blikket. Det vigtigste var, at han kunne se, hvad vi ville gøre.')
update(23, narrator='Rebet gled over den tykke gren, og vi prøvede bevægelsen uden at løfte. Mos så fra mine hænder til Noor. Først da han nikkede, trak vi forsigtigt.')
update(27, next=dict(success='K01_S48'),
       narrator='Mos kunne være fløjet sin vej med det samme, men blev siddende på kanten. Han pegede ned i mørket. Der var åbenbart nogen, som havde brug for hjælp endnu.')
scene(48,'Lys til den nederste hylde','well',
      'Vi kunne se frøene, men ikke den sti, der førte ned til dem. Mos gav mig tre små lysfrø. De var lune og summede i min hånd.',
      [('Mos','Send dem til klokkeblomsterne. Så åbner de lyset.'),
       ('Noor','Et kastespil. Med blomster, der klapper, når man rammer.'),
       ('Liv','Det er langt rarere end dem med bamser, man aldrig vinder.')],
      [stage('aim','Tryk »Send lys«, når ildfluen er inde i blomstens gyldne ring. Tænd alle tre blomster.',goal=3)],
      'Tre blomster foldede sig ud, og hele brønden glimtede. Selv den nederste hylde havde nu en lille sol.',28,'playful')
update(28, next=dict(success='K01_S49'))
scene(49,'Den sovende rodvogter','guardian',
      'Den sidste vej var spærret af en rodvogter. En lille nøgle hang i dens mos. Den sov med et øje, der af og til glemte at lukke.',
      [('Noor','Vi kunne vække den og spørge pænt.'),
       ('Mos','Den har sovet i hundrede år. Den er gnaven de første halvtreds minutter.'),
       ('Liv','Så låner vi nøglen. Stille og roligt. Og lægger den tilbage bagefter.')],
      [stage('stealth','Hold fingeren på nøglen, mens vogteren sover. Slip, når den begynder at vågne.',goal=1)],
      'Nøglen gled fri. Jeg åbnede det lille gitter foran den nederste hylde og hængte straks nøglen tilbage i mosset. Rodvogteren mumlede »fem minutter mere« og trak en bregne op over næsen.',29,'danger')
update(29, narrator='Bag gitteret sad det sidste frø under en sten, der var tungere, end den så ud. Noor fandt en rund klods til krogen. Pludselig havde vores to små ting en stor virkning.')
update(31, stages=[choice('kontakt','Mos har aldrig haft en gæst. Hvad vil du love ham?',[
    ('hand','Jeg går ved din side','leaf','Mos lægger forsigtigt sin pote i din hånd. »Også når jeg går langsomt?«'),
    ('space','Du bestemmer selv','moon','Mos ser tilbage på brønden. »Så vil jeg gerne følges. Bare ikke bæres.«'),
    ('home','En dør, der er åben','key','Mos folder vingen en lille smule ud. »Også når jeg vil ud igen?«')])])
update(33, append_stages=[choice('velkomst','Edda smiler. Hvad skal Mos opleve først?',[
    ('water','En skål friskt vand','water','Mos drikker med hele snuden. Noor må hente en klud. Og en større skål.'),
    ('garden','Et sted i solen','flower','Mos lægger sig i solpletten. Tre små blomster springer ud under hans pote.'),
    ('story','Fortæl vores historie','book','Edda lytter uden at afbryde. Først da vi nævner det blå kridt, bliver hendes hånd stille.')])])
update(34, next=dict(success='K01_S50'))
scene(50,'Ibens sidste besked','letter',
      'Edda foldede et gammelt brev ud. Det var fra Iben. Ved underskriften stod en hånd med en stjerne — præcis som på kompasset. Edda så længe på det blå kridt, vi havde taget med.',
      [('Noor','Så lunden tørrede ikke bare ud?'),
       ('Edda','Fortæl mig, hvad I så. Hvilken forklaring passer til jeres spor?'),
       ('Liv','Vand bag en låst sluse. Blåt kridt. Og en stjerne, nogen prøvede at skjule.')],
      [stage('truth','Hvilken forklaring passer til sporene, I fandt?',[
          item('weather','Solen tørrede kilden','fire',response='Edda: Men I fandt jo vand bag slusen. Solen forklarer ikke låsen.'),
          item('closed','Nogen lukkede vejen','key',response='Edda: Ja. Nogen troede, en lukket vej var en sikker vej.'),
          item('mos','Mos skjulte vandet','leaf',response='Mos: Jeg sad fast. Edda nikker. Han kunne ikke nå slusen.')],answer='closed')],
      'Edda læste en linje fra brevet: »Hvis jeg lukker vejene, kan ingen komme til skade.« Så så hun på Mos. »Iben var bange. Måske behøver hun også nogen, der viser hende en vej hjem.« For første gang tænkte jeg på hende som et menneske. Ikke bare et mysterium.',35)
update(37, dialogue=lines(('Noor','Kan du også få en bolle til at gro?'),
                          ('Mos','Den er død dej.'),
                          ('Liv','Først får et af de reddede frø lidt jord. Så er det din tur, Mos.')),
       stages=[dict(kind='place', prompt='Vælg Mos, og lad ham puste på det nysåede bed.',
                    items=[item('mos','Mos’ naturpust','mos',pos=[.22,.73],target='garden')],
                    targets=[item('garden','Det nysåede bed','seed',pos=[.69,.52])])])
update(40, append_stages=[choice('loefte','Et rødt lys blinker ude fra havet. Hvad hvisker du til kompasset?',[
    ('follow','Vi finder dig','spark','Jeg lagde hånden om kompasset. Vi finder dig, tænkte jeg. Også hvis vejen ikke findes endnu.'),
    ('together','Vi kommer sammen','leaf','Mos lænede sig mod mit ben. Næste gang var vi ikke to. Vi var tre.'),
    ('home','Her er også plads til dig','house','Jeg så på den tomme grund ved siden af Rodhytten. Et hjem kan begynde, længe før nogen flytter ind.')])])

# Scene-specific responses make the choices audible later in the story, too.
callbacks = {
    'K01_S17': {'key':'samtaletone','values':{
        'ask':'Jeg havde spurgt stille. Nu kom svaret, lige så stille: Mos. Det var navnet fra bogen. Men nu tilhørte det en, der sad lige foran mig og turde svare.',
        'wait':'Vi havde ventet. Nu løftede Mos selv hovedet. Mos, sagde han. Som om navnet var en gave, han først nu turde række os.',
        'joke':'Dragen pustede igen. Denne gang lød det som en latter. Så kom et ord, helt tydeligt: Mos. Jeg havde fundet noget meget bedre end en kat.'}},
    'K01_S35': {'key':'kontakt','values':{
        'hand':'Jeg havde lovet at gå ved hans side. Nu stod vi på en tom grund sammen. Her kunne Mos få et sted, hvor nogen blev, også når han gik langsomt.',
        'space':'Mos skulle selv bestemme. Det havde jeg lovet ved brønden. Derfor pegede jeg på de to steder og ventede, til han var klar til at vælge sammen med os.',
        'home':'En dør, der altid er åben. Det havde jeg lovet. Nu skulle vi bygge den — og et lille hus, der var værd at komme tilbage til.'}},
    'K01_S40': {'key':'velkomst','values':{
        'water':'Mos havde drukket det meste af sin nye vandskål. Nu landede en varm rød gnist i det sidste vand. Langt ude på havet stod et fyr uden lys.',
        'garden':'De blomster, Mos havde vækket, lyste stadig i aftenen. Så landede en rød gnist mellem dem. Ude på havet stod et fyr uden lys.',
        'story':'Edda havde lyttet til hele vores historie. Netop som jeg troede, den var slut, landede en rød gnist i Mos’ skål. Ude på havet stod et fyr uden lys.'}}
}

# A reusable chapter-opening contract: bestiary, physical bag puzzle, route map.
scene(51,'Bogen, der kendte mit navn','book',
      'På Eddas bord lå en bog i grønt drageskind. Den var varm, som om nogen lige havde læst i den. Da jeg rørte omslaget, åbnede den sig på en drage med blade i vingerne.',
      [], [stage('book','Læs om Mos, lundens lille vogter.', spreads=[
        dict(title='Mos · lundens lille vogter',subtitle='NATURDRAGE · HJEMVEJ I',image='mos',
             text='I de ældste lunde lever en drage, som de fleste går lige forbi. Mos er på størrelse med en stor hund, men han kan rulle sig sammen til noget, der ligner en ganske almindelig mostue. Hans skæl ligner bark, og mellem dem vokser fine blade. Når han ligger stille, kan selv en fugl finde på at lande på hans hoved. Han bor dér, hvor rødder møder rent vand: ved kilder, gamle brønde og skyggefulde piledamme. Han bygger sin rede af blødt mos og tabte fjer. Finder du tre små blomster midt om vinteren, har Mos måske sovet netop dér. Gå langsomt. Han ser dig længe før du ser ham.',
             facts=['LEVESTED  Kilder, brønde og piledamme','KENDTEGN  Barkskæl · bladvinger · gyldne øjne','SPOR  Små klomærker og blomster i skyggen']),
        dict(title='Et pust, der vækker livet',subtitle='KRÆFTER · FORSVAR · SVAGHEDER',image='breath',
             text='Mos spytter ikke ild. Hans naturpust kan vække et frø, få en vissen gren til at blomstre og bøje en rod, der har glemt at give plads. Når han må forsvare sig, sender han en sky af blade mod sin modstander eller kalder på rødderne, så de danner et blødt skjold. Hans styrke vokser nær levende planter og rindende vand. Tørke gør ham træt. Stærk røg forvirrer hans lugtesans. Og bliver hans vinge klemt, kan han ikke flyve fri, selv om han kan høre hele skoven kalde. Træk aldrig i vingen. Hjælp det, der holder ham, med at slippe.',
             facts=['ANGREB  Bladsky og rodgreb','STYRKER  Naturpust · rodskjold · skovens hørelse','SVAGHEDER  Tørke, røg og fastklemte vinger']),
        dict(title='Brønden, der holdt vejret',subtitle='EN GAMMEL HISTORIE · ET NYT LØFTE',image='moon',
             text='Engang viste Mos vandet vej gennem den stille lund. Han kendte hvert frø og hvert lille dyr, der kom for at drikke. Så blev en sluse lukket. De gamle hjemveje forsvandt, og en hånd med en stjerne blev streget over med blåt kridt. Mos fløj ned for at hjælpe de sidste frø. Men i mørket lukkede rødderne sig om hans vinge. Siden har lunden ventet. Bogen fortæller ikke, om han stadig er der. Kun dette: En hjemvej kan ikke låses op med magt. Nogen må lytte, finde sporene og give plads. Da Liv læser den sidste linje, lyser hendes navn i bogens kant.',
             facts=['MISSION  Find Mos og giv vingen fri','MYSTERIET  Hvem lukkede slusen — og hvorfor?','HUSK  En ven er noget, man får lov at blive'])
      ])], 'Jeg lukkede bogen. Hvis bare halvdelen var sandt, var der nogen derude, der havde ventet alt for længe. Først skulle tasken pakkes.',52)
extra[-1]['runtime']['direct']=True
scene(52,'Alt skal kunne være i tasken','kitchen',
      'Noor fandt den gode taske med de mange lommer. Edda lagde en lup oven på tingene. »Til det, man ikke ser ved første øjekast,« sagde hun og satte en flaske månemos ved siden af.',
      [('Noor','Reb, lanterne, ske, bog, månemos og lup. Det skal kunne være her. På en eller anden måde.'),
       ('Liv','Så pakker vi klogt. Og holder den store lomme fri for krummer.')],
      [stage('packing','Træk tingene ind i taskens rum, så de ikke overlapper. Drej en valgt ting, hvis den ikke passer.',[
        item('book','Dragebogen','book',shape=[2,2]),item('spoon','Træske','spoon',shape=[1,3]),
        item('lantern','Lanterne','lantern',shape=[1,2]),item('rope','Reb','rope',shape=[2,1]),
        item('bottle','Månemos','bottle',shape=[1,1]),item('lens','Lup','lens',shape=[1,1])],width=4,height=4)],
      'Klik. Spændet holdt! Noor løftede tasken. »Vi er klar til alt. Bortset fra måske at løbe op ad bakke.«',53,'playful')
extra[-1]['presentation']=dict(anchor='left',focus=[.8,.43])
scene(53,'En vej, der endnu ikke findes','map',
      'Edda lagde et kort på bordet. En gylden streg begyndte at bevæge sig gennem skoven. Den tegnede ikke bare steder. Den tegnede alt det, vi endnu ikke vidste, vi turde.',
      [],[stage('journey','Følg rejsens lys fra farmen gennem lunden — og hjem med en ny ven.',stops=[
        ['Farmen',.16,.68],['Porten',.30,.57],['Tågeskoven',.45,.39],['Frøens bro',.55,.54],
        ['To stier',.60,.37],['Mos’ brønd',.80,.25],['Miksturen',.71,.48],['Den frie vinge',.66,.64],['Et nyt hjem',.83,.76]])],
      'Stregen sluttede ved en lille grøn dør. Så bankede noget under køkkengulvet. Tre små bank. Som om eventyret allerede vidste, vi var klar.',1)
extra[-1]['runtime']['direct']=True

out = dict(revision=2, patches=patches, extra=extra, callbacks=callbacks,
           music=dict(playful=[3,6,7,9,10,12,27,33,36,37,42,48],
                      danger=[14,15,18,22,23,24,25,26,43,44,46,49], evening=[30,31,32,34,35,38,39,40,50]))
path = ROOT/'content/runtime/adventure_01.json'
path.write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n')
print(f'Authored expansion: {len(extra)} new scenes, {len(patches)} revised scenes.')
