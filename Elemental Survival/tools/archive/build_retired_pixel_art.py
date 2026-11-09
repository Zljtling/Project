from PIL import Image, ImageDraw, ImageFilter
from pathlib import Path
import math, random
OUT=Path('assets/art_refresh'); OUT.mkdir(parents=True,exist_ok=True)
# Small authored silhouettes with four directions and a four-frame walk cycle.
def actor(kind):
 sheet=Image.new('RGBA',(192,256))
 for row in range(4):
  for frame in range(4):
   im=Image.new('RGBA',(48,64)); d=ImageDraw.Draw(im); bob=[0,-1,0,-1][frame]; stride=[0,2,0,-2][frame]
   def box(r,c): d.rectangle((r[0],r[1]+bob,r[2],r[3]+bob),fill=c)
   def poly(ps,c): d.polygon([(x,y+bob) for x,y in ps],fill=c)
   ink='#293b3c'; skin='#e5be91'; dark='#38474b'
   if kind in ['player','hunter','elite']:
    coat={'player':'#4f8f8b','hunter':'#965e58','elite':'#899a9e'}[kind]
    light={'player':'#91bab0','hunter':'#c19374','elite':'#ced1bd'}[kind]
    poly([(12,29),(35,29),(39,49),(31,53),(24,49),(15,53),(9,48)],ink)
    poly([(14,29),(33,29),(35,46),(28,49),(23,46),(15,49),(12,44)],coat)
    box((15,47,21,56+stride),dark);box((27,47,32,56-stride),dark)
    box((13,56+stride,21,59+stride),ink);box((27,56-stride,35,59-stride),ink)
    box((9,32,13,43),light);box((34,33,38,44),light)
    box((10,43,13,46),skin);box((35,44,38,47),skin)
    box((16,35,30,37),'#d7be83');box((22,36,25,40),'#7d663c')
    if kind=='player':
     poly([(13,26),(20,25),(28,30),(19,36),(11,34)],'#e2d3a2')
     box((29,37,35,46),'#70553f');box((30,38,34,40),'#b38d5b')
    d.ellipse((14,9+bob,34,31+bob),fill=ink)
    box((16,13,32,27),skin);box((18,26,30,30),skin)
    if kind=='player':
     poly([(13,17),(15,9),(23,6),(32,9),(35,17),(29,15),(25,12),(20,17)],'#e5dfc9')
     box((14,16,17,23),'#c4c7b8')
    elif kind=='hunter':
     poly([(12,20),(14,11),(24,4),(35,13),(36,24),(31,20),(29,14),(18,16),(17,23)],coat)
     box((18,25,32,29),'#534d48')
     poly([(7,39),(5,49),(10,47),(14,39)],'#d4d0b4');poly([(37,39),(43,48),(39,49),(34,40)],'#d4d0b4')
    else:
     box((13,12,35,25),'#a8b4af');box((14,20,34,24),ink);box((18,21,30,21),'#d5b36d')
     poly([(19,11),(23,1),(28,4),(29,11)],'#b18a67')
     box((7,31,15,39),'#a8b4af');box((33,31,41,39),'#a8b4af')
     poly([(39,29),(44,31),(42,51),(36,51),(35,37)],'#555e61');box((39,34,41,45),'#ceb77d')
    if row!=3 and kind!='elite':
     if row==0: box((19,20,21,22),ink);box((28,20,30,22),ink)
     else: box((29 if row==2 else 17,20,31 if row==2 else 19,22),ink)
    if row==3: box((15,14,33,23),'#d3d3bc' if kind=='player' else coat)
   elif kind=='ghoul':
    poly([(9,25),(15,19),(31,20),(39,32),(36,50),(27,53),(15,50)],ink)
    poly([(11,28),(17,22),(30,24),(35,33),(31,48),(15,47)],'#798b64')
    box((12,46,18,56+stride),'#4b6155');box((28,46,34,56-stride),'#4b6155')
    box((10,55+stride,20,58+stride),ink);box((27,55-stride,36,58-stride),ink)
    poly([(10,29),(5,39),(6,51),(10,53),(14,35)],'#8e9d77');poly([(34,30),(41,39),(40,52),(35,52),(30,34)],'#8e9d77')
    d.ellipse((14,9+bob,34,31+bob),fill=ink);d.ellipse((16,11+bob,32,29+bob),fill='#b7b38a')
    box((18,19,21,22),'#e4c575');box((27,19,30,22),'#e4c575');box((21,26,29,28),'#48574a')
    for x,y in [(15,26),(29,30),(17,37)]: box((x,y,x+4,y+3),'#a0ac72')
   else:
    fire=kind=='fire_guardian'; body='#7e6453' if fire else '#78858a' if kind=='stone_guardian' else '#657f68'; lit='#e6a458' if fire else '#d0c9a1' if kind=='stone_guardian' else '#bed38a'
    poly([(5,28),(13,20),(34,20),(44,30),(42,51),(32,58),(14,57),(4,46)],ink)
    poly([(8,29),(16,23),(33,24),(40,32),(37,49),(30,53),(14,51),(8,43)],body)
    for x,y in [(10,31),(26,29),(18,42),(32,40)]:
     poly([(x,y),(x+9,y-2),(x+10,y+8),(x+3,y+11)],'#a49575' if fire else '#85966e')
    box((7,49,15,59+stride),body);box((32,49,41,59-stride),body)
    d.ellipse((11,9+bob,37,30+bob),fill=ink);d.ellipse((13,11+bob,35,28+bob),fill=body)
    box((16,18,21,21),lit);box((28,18,33,21),lit);box((20,27,29,29),lit)
    for x,y in [(9,24),(34,26),(21,35)]:
     poly([(x,y+2),(x-2,y-7),(x+3,y-13),(x+6,y-5),(x+4,y+3)],lit)
   if kind=='poison_guardian':
    d.ellipse((2,42+bob,16,59+bob),fill='#6f8667'); d.ellipse((31,42+bob,46,59+bob),fill='#6f8667')
    for x in [8,37]:
     d.rectangle((x-2,12+bob,x+2,26+bob),fill='#455e50');d.ellipse((x-6,9+bob,x+6,16+bob),fill='#a2b880')
   if kind=='fire_guardian':
    poly([(10,15),(6,2),(17,10)],'#d49c61');poly([(31,10),(42,1),(37,17)],'#d49c61')
    box((1,29,9,46),'#65554c');box((39,29,47,46),'#65554c')
    for x,y in [(21,32),(25,39),(20,45)]: box((x,y,x+2,y+5),'#f4bf72')
   sheet.alpha_composite(im,(frame*48,row*64))
 sheet.save(OUT/(kind+'.png'))
for k in ['player','ghoul','hunter','elite','poison_guardian','fire_guardian','stone_guardian']: actor(k)
r=random.Random(704)
im=Image.new('RGBA',(256,256));d=ImageDraw.Draw(im)
for i in range(1000):
 x=r.gauss(127,48); y=r.gauss(132,44)
 if ((x-127)/108)**2+((y-126)/106)**2>1:continue
 size=r.uniform(5,14); c=r.choice(['#607c65','#6e8d6b','#819f76','#91ab7c','#a8bd8b','#bfce9e'])
 if y<100:c=r.choice(['#9bb680','#b5c896','#c8d5ac'])
 d.ellipse((x-size,y-size*.45,x+size,y+size*.45),fill=c)
im.save(OUT/'canopy.png')
im=Image.new('RGBA',(128,128));d=ImageDraw.Draw(im)
for i in range(32):
 x=r.uniform(14,114); y=r.uniform(110,126);h=r.uniform(20,72);lean=r.uniform(-24,24)
 d.polygon([(x-2,y),(x+lean,y-h),(x+3,y)],fill=r.choice(['#67815c','#7d9569','#94a87a','#b4bc8b']))
im.save(OUT/'meadow_blades.png')
print('Created six animated actor sheets, canopy and meadow blades')
