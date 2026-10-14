from pathlib import Path
import json
R=Path(__file__).resolve().parents[1]
def obj(i,l,icon,x,y,**kw):return dict(id=i,label=l,icon=icon,pos=[x,y],**kw)
def step(kind,prompt,items=None,targets=None,**kw):return dict(kind=kind,prompt=prompt,items=items or [],targets=targets or [],**kw)
def inspect(prompt,items):return step('inspect',prompt,items)
def place(prompt,items,targets,**kw):return step('place',prompt,items,targets,**kw)
def seq(prompt,items):return step('sequence',prompt,items)
def choose(prompt,options,key):return step('choice',prompt,[dict(id=x[0],label=x[1],icon=x[2],pos=[.28+.44*i,.55]) for i,x in enumerate(options)],key=key)
def at(i,l,icon,x,y,target,**kw):return obj(i,l,icon,x,y,target=target,**kw)
def target(i,l,icon,x,y):return obj(i,l,icon,x,y)
S={}
S[1]=[inspect('Hvor kommer lyden fra? Undersøg de tre støvringe.',[obj('ring_1','Den første støvring','ring',.27,.75),obj('ring_2','Den anden støvring','ring',.53,.8),obj('ring_3','Den tredje støvring','ring',.77,.7)]),seq('Der er noget under brættet. Løft ringen.',[obj('lift','Løft gulvbrættet','lift',.53,.76)])]
S[2]=[step('rotate','Drej kompasringen, så bladet møder lysstriben.',[obj('dial','Drej kompasringen','compass',.5,.53)],initial=[2],goal=[0])]
S[3]=[place('Pak reb, træske og lanterne. Tryk en ting, og derefter tasken.',[at('rope','Reb','rope',.2,.35,'bag'),at('spoon','Træske','spoon',.5,.35,'bag'),at('lantern','Lanterne','lantern',.8,.35,'bag'),obj('shoe','Noor: Vi har allerede sko på.','stone',.2,.72,decoy=True),obj('pillow','Liv: Den pude vil have hele tasken.','moss',.8,.72,decoy=True),obj('teacup','Noor: Edda skal nok savne sin tekop.','cup',.5,.55,decoy=True)],[target('bag','Tasken','bag',.5,.78)])]
S[4]=[place('Læg kompasset i portens bladformede hul.',[at('compass','Kompasset','compass',.26,.75,'lock')],[target('lock','Bladets nøglehul','leaf',.7,.46)])]
S[5]=[inspect('Kig efter spor efter nogen, der er alene.',[obj('moss','Mosset er trykket fladt.','moss',.26,.6),obj('scale','Et skæl. Det er stadig varmt.','leaf',.55,.72),obj('footprint','Et lille aftryk går mod brønden.','paw',.79,.58),obj('feather','En fjer. Fuglene har også været her.','feather',.2,.85,decoy=True)])]
S[6]=[seq('Tag i håndtaget og vip vandkanden.',[obj('can','Vip vandkanden','cup',.48,.62)])]
S[7]=[place('Byg broen. Hver planke passer til et hul med samme længde.',[at('short','Kort planke','plank',.2,.79,'short_gap'),at('medium','Mellem planke','plank',.5,.79,'medium_gap'),at('long','Lang planke','plank',.8,.79,'long_gap')],[target('short_gap','Kort hul','plank',.24,.26),target('medium_gap','Mellem hul','plank',.5,.43),target('long_gap','Langt hul','plank',.73,.59)])]
S[8]=[choose('To veje til den samme ven. Hvilken vil du udforske?',[('A','Træstien · et vindblad','leaf'),('B','Rodgangen · en dugkop','cup')],'k01_rute')]
S[9]=[place('Hjulet sidder fast. Skub metalbladet fri fra siden.',[at('spoon','Træske','spoon',.22,.8,'wheel'),obj('rope','Rebet kan ikke skubbe bladet fri.','rope',.75,.8,decoy=True)],[target('wheel','Bladet mellem egerne','wheel',.5,.35)])]
S[10]=[inspect('Tag vindbladet med. Det kan blive en gave til Mos.',[obj('windleaf','Vindblad','leaf',.5,.43)]),seq('Brønden er lige nedenunder. Find rebtrappen.',[obj('ladder','Gå ned ad rebtrappen','rope',.72,.75)])]
S[11]=[step('maze','Følg de tørre rødder til dugkoppen. Du kan altid gå tilbage.')]
S[12]=[inspect('Løft dugkoppen fra nichen.',[obj('dewcup','Dugkop','cup',.58,.38)]),seq('Åbn rodtæppet, så I kan komme ud.',[obj('curtain','Løft rodtæppet','root',.46,.72)])]
S[13]=[inspect('Lys med lanternen. Find en hale, en pote og en vinge.',[obj('tail','En hale bevæger sig.','root',.72,.8),obj('paw','En lille pote.','paw',.4,.7),obj('wing','En vinge af blade.','leaf',.62,.51)])]
S[14]=[seq('Følg roden med bladpar fra vingen til slusen.',[obj('root_1','Ved vingen','leaf',.25,.78),obj('root_2','Det første bladpar','leaf',.43,.58),obj('root_3','Det næste bladpar','leaf',.64,.45),obj('root_4','Ved slusen','leaf',.78,.23)])]
S[15]=[step('pipes','Drej renderne, så de åbne ender mødes. Følg vandets vej.',[obj('pipe_0','Den første rende','root',.28,.27),obj('pipe_1','Den anden rende','root',.28,.67),obj('pipe_2','Den tredje rende','root',.68,.67)],initial=[1,3,2],goal=[0,2,1]),seq('Vandvejen er samlet. Løft stopklodsen.',[obj('stop','Løft stopklodsen','plank',.5,.6)])]
S[16]=[choose('Lad dragen få plads til at svare.',[('ask','Spørg dragen','hand'),('wait','Vent lidt sammen','leaf')],'samtaletone')]
S[17]=[place('Læg kompasset på kanten, et stykke fra Mos.',[at('compass','Kompasset','compass',.25,.75,'edge')],[target('edge','En rolig plads på kanten','stone',.68,.35)]),seq('Hold hånden åben. Mos vælger selv at komme nærmere.',[obj('hand','Giv Mos tid til at snuse','hand',.43,.65)])]
S[18]=[inspect('Se, hvad Mos prøver at vise jer.',[obj('root','Roden strammer om vingen.','root',.7,.62),obj('paw','Mos peger på roden.','paw',.39,.7),obj('wing','Vingen skal have mere plads.','leaf',.67,.36)]),seq('Rør den løse rodløkke, så Mos kan se planen.',[obj('loop','Den løse rodløkke','root',.5,.64)])]
S[19]=[inspect('Undersøg redskaberne. Hvad kan nå ind uden at klemme?',[obj('hook','Trækrogen kan nå rundt om roden.','hook',.37,.45),obj('rake','Noor: Vi skal ikke rede et helt træ.','root',.73,.42,decoy=True),obj('bucket','Liv: En spand kan bære vand, men ikke løsne løkken.','bowl',.23,.78,decoy=True),obj('broom','Noor: Den kan feje, når Mos er fri.','spoon',.77,.78,decoy=True)])]
S[20]=[step('wipe','Gnid mosset væk, eller tryk på de tre grønne felter.',[obj('wipe_1','Rens venstre side','moss',.3,.48),obj('wipe_2','Rens midten','moss',.5,.6),obj('wipe_3','Rens højre side','moss',.72,.43)])]
S[21]=[step('difference','Sammenlign den gamle plan med jeres ankomst. Find fem ændringer.')]
S[22]=[choose('Vis Mos, hvordan I vil give vingen plads.',[('A','Løft roden med rebet','rope'),('B','Byg støtte under roden','plank')],'k01_redning')]
S[23]=[seq('Løft roden lidt ad gangen. Mos får en pause mellem hvert løft.',[obj('lift_1','Løft til første mærke','rope',.35,.62),obj('lift_2','Løft til andet mærke','rope',.67,.37)])]
S[24]=[place('Fastgør rebet i den solide pæls ring.',[at('rope','Rebets ende','rope',.23,.78,'stake')],[target('stake','Den faste pæl','plank',.68,.42),obj('branch','Den løse gren kan ikke holde roden.','root',.77,.78,decoy=True)])]
S[25]=[place('Byg en bred bund. Læg kilen i midten og det bløde stykke øverst.',[at('base','Bred bund','plank',.16,.75,'base_slot'),at('wedge','Kile','stone',.5,.8,'wedge_slot',requires='base'),at('top','Blødt topstykke','moss',.84,.75,'top_slot',requires='wedge')],[target('base_slot','Bunden','plank',.5,.58),target('wedge_slot','Midten','stone',.5,.4),target('top_slot','Mod roden','moss',.5,.22)]),seq('Tryk let på støtten. Står den fast?',[obj('test','Afprøv støtten','hand',.5,.51)])]
S[26]=[seq('Skub kilen forsigtigt ind til stopmærket.',[obj('push_1','Skub lidt','stone',.32,.61),obj('push_2','Skub til stopmærket','stone',.69,.61)])]
S[27]=[inspect('Mos har fået øje på noget. Lys på de tre frøkapsler.',[obj('seed_1','Et frø på den nederste hylde.','seed',.25,.8),obj('seed_2','Et frø mellem rødderne.','seed',.54,.65),obj('seed_3','Et frø på den høje afsats.','seed',.77,.48)])]
S[28]=[place('Forbind rødderne til hylderne. Mos bøjer dem for dig.',[at('low','Nederste rod','root',.19,.78,'A'),at('mid','Midterste rod','root',.22,.51,'B'),at('high','Øverste rod','root',.26,.25,'C')],[target('A','Hylde A','stone',.71,.75),target('B','Hylde B','stone',.73,.48),target('C','Brøndkant C','stone',.77,.21)])]
S[29]=[place('Lav en vippe. Sæt den runde klods mellem håndtaget og stenen.',[at('fulcrum','Rund klods','stone',.22,.8,'under_hook')],[target('under_hook','Under krogen','hook',.55,.51)]),seq('Tryk håndtaget ned. Mos tager det sidste frø.',[obj('lever','Tryk håndtaget ned','hook',.32,.54)])]
S[30]=[seq('Åbn sluserne fra kilden mod bækken. Lad vandet vise vejen.',[obj('sluice_1','Ved kilden','wheel',.25,.27),obj('sluice_2','Ved brønden','wheel',.52,.51),obj('sluice_3','Ved bækken','wheel',.74,.75)])]
S[31]=[choose('Lad Mos vælge afstanden.',[('hand','Hold hånden frem','hand'),('space','Bliv ved hans side','leaf')],'kontakt')]
S[32]=[seq('Følg kompaslyset hjem. Mos kommer med af egen lyst.',[obj('anchor_1','Det første hjemanker','compass',.25,.76),obj('anchor_2','Lyset gennem lunden','leaf',.5,.5),obj('anchor_3','Porten hjem','house',.76,.25)])]
S[33]=[place('Sæt velkomstskålen inden for den åbne port.',[at('bowl','Vandskålen','bowl',.22,.77,'inside')],[target('inside','En fri plads inden for porten','water',.69,.6)])]
S[34]=[place('Læg mærket fra slusen ved mærket på Eddas kortmappe.',[at('clue','Hånden med stjernen','hand',.25,.72,'folder')],[target('folder','Kortmappen','book',.7,.44)])]
S[35]=[choose('Et hjem til Mos. Hvilken have skal Rodhytten have?',[('piledam','Ved piledammen','cup'),('moslund','I en blød moslund','moss')],'k01_hjem'),place('Byg et hus med en dør, der altid er åben.',[at('foundation','Fundament','stone',.16,.8,'base'),at('house','Rodhytten','house',.5,.81,'home',requires='foundation'),at('door','Den åbne dør','plank',.84,.8,'doorway',requires='house')],[target('base','Husets grund','stone',.24,.48),target('home','Huset','house',.5,.27),target('doorway','Den åbne indgang','plank',.77,.49)]),place('Gør det rart at flytte ind. Sæt rede og vand frem.',[at('nest','Reden','moss',.2,.8,'bed'),at('bowl','Vandskålen','bowl',.8,.8,'water')],[target('bed','Inde i hytten','moss',.4,.52),target('water','Ved døren','bowl',.72,.56)])]
S[36]=[step('decorate','Læg tre bløde mosstykker, hvor du vil i reden.',[obj('cushion_1','Første mosstykke','moss',.2,.82),obj('cushion_2','Andet mosstykke','moss',.5,.82),obj('cushion_3','Tredje mosstykke','moss',.8,.82)],zone=[.18,.18,.64,.44]),choose('Vælg en lille ting ved døren.',[('stone','En glat sten','stone'),('leaf','Et bladskilt','leaf')],'decoration')]
S[37]=[place('Vælg Mos, og lad ham puste på det tomme bed.',[at('mos','Mos’ naturpust','mos',.22,.73,'garden')],[target('garden','Det tomme bed','seed',.69,.52)])]
S[38]=[place('Giv jeres fund en plads ved Rodhytten.',[at('gift','Jeres gave','gift',.24,.75,'gift_spot')],[target('gift_spot','Ved Mos’ hjem','house',.67,.43)]),seq('Prøv gaven sammen med Mos.',[obj('activate','Brug jeres gave','gift',.5,.56)])]
S[39]=[step('album','Vælg det øjeblik, du vil huske i dagbogen.'),step('decorate','Sæt dit bladstempel, hvor du vil på siden.',[obj('stamp','Bladstempel','leaf',.5,.86)],zone=[.12,.12,.76,.58])]
S[40]=[place('Gem den varme gnist i journalens næste felt.',[at('spark','Gnisten fra fyret','spark',.28,.68,'next_page')],[target('next_page','En ny side i journalen','book',.7,.39)])]
source=json.loads((R/'content/source/Spildata.json').read_text())
data={'chapter':source['chapters'][0],'maze':source['mazes']['maze-1'],'farm':source['farm'],'minigame':source['minigames'][0]}
for page in data['chapter']['pages']:
 page['runtime']={'stages':S[page['page']], 'overlay_status':'implemented', 'coordinate_space':'art_rect' if page['page'] in [1,5,13,14,18,27,30,32] else 'closeup_rect'}
(R/'content/runtime/chapter_01.json').write_text(json.dumps(data,ensure_ascii=False,indent=2))
assert len(S)==40
print('40 explicit scene configurations,',sum(len(v) for v in S.values()),'physical stages.')
