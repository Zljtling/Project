"""Editable, original SVG artwork. No downloaded/AI bitmap assets are embedded.

Rebuilds four-direction, eight-pose atlases and the shared forest UI icon family.
Frame 0 is rest, 1..6 gait, 7 anticipation. 128 x 144 feet-aligned cells.
"""
from pathlib import Path
import math
import json
import shutil
import hashlib

ROOT = Path(__file__).resolve().parents[1]

def save(path, text):
    target = ROOT / path
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_text(text, encoding="utf-8")

def svg(content, w=128, h=128, defs=""):
    return f'<svg xmlns="http://www.w3.org/2000/svg" width="{w}" height="{h}" viewBox="0 0 {w} {h}"><defs>{defs}</defs>{content}</svg>'

def path(d, fill, stroke="#443d31", width=2.5):
    return f'<path d="{d}" fill="{fill}" stroke="{stroke}" stroke-width="{width}" stroke-linecap="round" stroke-linejoin="round"/>'

def ellipse(x,y,rx,ry,fill,stroke="none",width=2.5):
    return f'<ellipse cx="{x}" cy="{y}" rx="{rx}" ry="{ry}" fill="{fill}" stroke="{stroke}" stroke-width="{width}"/>'

COLORS = {"player":("#f4d5a0","#b77b55"), "ghoul":("#b2c78e","#5b7e66"),
          "charger":("#d59e7b","#875e58"), "spitter":("#c3aed9","#786c9a"),
          "elite":("#a7b6ad","#536b69"), "hunter":("#d1ae86","#775c54"),
          "poison_guardian":("#c7d99a","#6c9467"), "fire_guardian":("#e5a16c","#975752"),
          "stone_guardian":("#bdc7bc","#73847b")}

def actor_cell(role, frame, direction):
    step = math.sin((frame-1)*math.tau/6) if 1 <= frame <= 6 else 0
    bob = -abs(step)*3
    anticipating = frame == 7
    side = direction in (1,3)
    back = direction == 2
    a = []
    # Legs are independent drawings: alternating reach / lift with planted stance.
    for x, sign in [(46,1),(81,-1)]:
        y = 123 - max(0,step*sign)*7
        a.append(path(f'M{x-9} 104 Q{x-12} 116 {x-11+step*sign*5:.2f} {y} Q{x} {y+10} {x+14} {y+2} L{x+9} 106Z', '#665441' if role=='player' else COLORS[role][1]))
        a.append(path(f'M{x-5} {y+2} L{x+8} {y+2}', 'none','#b8b88d',1.7))
    a.append(f'<g transform="translate(0 {bob+ (5 if anticipating else 0)})">')
    if role == 'player':
        a.append(path(f'M35 62 Q19 81 {24+step*5} 115 Q63 126 106 111 L93 59Z','#4c7965'))
        a.append(path(f'M34 72 Q26 94 {35+step*4} 112 L52 116 L47 69Z','#7da487', 'none'))
    # Reaching hands / claws move in opposition to the feet.
    for x, sign in [(28,1),(100,-1)]:
        cy = 88+step*sign*7-(12 if anticipating else 0)
        a.append(ellipse(x,cy,10,15,COLORS[role][1],'#443d31'))
        if role in ('hunter','charger'):
            a.append(path(f'M{x-5} {cy+6} l-2 10 5-5 3 7 3-11', '#efe0bb',width=1.8))
    if role in ('elite','stone_guardian'):
        a.append(path('M31 49Q64 30 97 49L108 101L85 118H44L20 101Z',f'url(#body_{role})'))
        a.append(path('M41 60L64 53L88 60L83 102L64 113L43 101Z','#d0cfb4'))
        a.append(path('M64 55V109M45 83H83','none','#879b8e',3))
    elif role == 'spitter':
        a.append(path('M28 56Q36 23 66 31Q101 37 101 74Q110 109 87 115Q56 127 31 105Q18 82 28 56Z',f'url(#body_{role})'))
    else:
        a.append(path('M27 57Q25 28 62 27Q99 25 102 63L101 88Q99 119 65 119Q25 119 25 85Z',f'url(#body_{role})'))
    if role == 'player':
        a.append(path('M30 54Q24 20 56 18L85 19Q103 24 103 51L91 60Q71 48 30 60Z','#436c56'))
        a.append(path('M33 50Q62 36 103 50L105 58Q62 46 30 61Z','#97b483'))
        a.append(path('M72 26Q87 2 106 10Q101 30 78 34Z','#b9cb85'))
        a.append(path('M78 31L100 14','none','#6c865f',1.5))
        a.append(path('M31 91Q62 104 96 90L89 111Q64 120 39 110Z','#527962'))
        a.append(path('M37 86L88 109','none','#d1ae75',6))
        a.append(path('M75 101L94 105L91 121L74 116Z','#a87648'))
        a.append(ellipse(84,109,2.4,2.4,'#e8ce8c'))
    elif role in ('charger','hunter'):
        a.append(path('M34 48Q17 40 19 16Q31 27 48 33Z','#e9d9b7'))
        a.append(path('M82 34Q103 27 112 10Q113 37 98 50Z','#e9d9b7'))
        if role == 'hunter':
            a.append(path('M32 51L19 64L29 72L16 86L32 90L26 107L44 104L64 120L84 103L102 108L98 91L111 82L98 68L106 57L91 49Z','#8e725f'))
            a.append(path('M40 50Q64 40 88 50L93 82L80 104L64 112L46 102L35 80Z',f'url(#body_{role})'))
    elif role == 'ghoul':
        a.append(path('M43 35Q31 14 48 14Q61 21 59 33M67 30Q78 7 89 18Q93 32 80 38','#718e65'))
        a.append(path('M42 94Q64 85 87 96L78 108L51 110Z','#d5d9ad','none'))
        for x,y in [(31,62),(92,79),(39,90)]: a.append(ellipse(x,y,3,4,'#668764'))
    elif role == 'spitter':
        a.append(path('M41 37Q27 12 19 23M83 37Q102 7 110 25','none','#827398',6))
        a.append(ellipse(19,23,7,7,'#d9cf9c','#443d31',2))
        a.append(ellipse(110,25,7,7,'#d9cf9c','#443d31',2))
    elif role == 'poison_guardian':
        a.append(path('M11 53Q20 12 58 13Q99 7 119 50Q67 68 11 53Z','#6a8b65'))
        a.append(path('M18 47Q39 22 68 20Q98 20 112 44Q62 38 18 47Z','#aabd78','none'))
        for x,y in [(36,34),(70,25),(92,40)]: a.append(ellipse(x,y,7,4,'#e7dbab'))
        a.append(path('M24 55Q67 65 108 53','none','#ded7a5',4))
    elif role == 'fire_guardian':
        a.append(path('M26 54Q12 28 33 16L47 34Q51 14 66 3Q69 25 82 30L104 14Q101 37 106 52Z','#db854c'))
        a.append(path('M43 47L56 34L66 17L72 40L89 36L91 50Z','#f5d57d','none'))
        a.append(path('M36 94L51 85L62 107L76 86L91 96','none','#f4d193',4))
    elif role in ('elite','stone_guardian'):
        a.append(path('M24 54L28 24L44 27L51 14L79 14L87 27L101 25L105 56Z','#718c83'))
        a.append(path('M29 48H101V62H29Z','#d8ca93'))
        if role == 'elite': a.append(path('M14 70L37 63L43 93L27 111L12 94Z','#729184'))
    # Face changes orientation; the back genuinely hides facial features.
    if back:
        a.append(path('M46 62Q64 55 83 62','none',COLORS[role][1],2))
        if role=='player': a.append(path('M42 68Q63 59 84 68L87 97L42 98Z','#90754f'))
    else:
        shift = 11 if side else 0
        for x in ([70,88] if side else [48,80]):
            a.append(ellipse(x,67,4,6,'#343e35'))
            a.append(ellipse(x-1,65,1.3,1.7,'#fff3d6'))
        if role in ('charger','hunter','elite','stone_guardian'):
            a.append(path(f'M{39+shift} 58l13 4M{75+shift} 62l12-5','none','#50453a',3))
        if role in ('spitter','poison_guardian'):
            a.append(ellipse(64+shift,88,12 if anticipating else 9,13 if anticipating else 8,'#536155','#d9d3a7',3))
        else:
            a.append(path(f'M{57+shift} 83q7 5 14-1','none','#775542',2))
        if role=='player':
            a.append(ellipse(38+shift,78,5,2.5,'#d98d73'))
            a.append(ellipse(87+shift,78,5,2.5,'#d98d73'))
    a.append('</g>')
    group=''.join(a)
    if direction==3: group=f'<g transform="translate(128 0) scale(-1 1)">{group}</g>'
    return group

def actors():
    for role,(light,dark) in COLORS.items():
        defs=f'<linearGradient id="body_{role}" x1="0" y1="0" x2="0.8" y2="1"><stop stop-color="{light}"/><stop offset="1" stop-color="{dark}"/></linearGradient>'
        cells=[]
        for direction in range(4):
            for frame in range(8):
                cells.append(f'<g transform="translate({frame*128} {direction*144})">{actor_cell(role,frame,direction)}</g>')
        save(f'assets/actors/cartoon/sheets/{role}.svg',svg(''.join(cells),1024,576,defs))

def icons():
    # Filled, recognizable objects instead of tiny abstract line glyphs.
    motifs={
      'dash':path('M29 29L57 30L56 69L82 82Q99 85 100 99H32Q22 88 32 74Z','#8c6447')+path('M28 34L58 34M34 56H54M17 65H8M20 79H4','none','#d2b67c',5),
      'step':path('M40 20L68 23L62 68L88 84Q100 91 94 104H33L28 83Z','#719d8e')+path('M23 40L7 53L24 58M23 63L12 75L25 78','none','#e1bc6d',4),
      'haste':path('M60 26Q80 8 97 18L83 43L98 35Q92 65 68 74L80 70Q59 102 30 105L37 75Z','#c5d6b0')+path('M35 99L80 30','none','#6f8e74',3),
      'turret':path('M32 87L19 108H39L53 89M76 86L90 108H109L91 84','#856549')+path('M29 56L76 44L87 81L43 92Z','#6b8c80')+path('M64 51L103 32L113 53L76 72Z','#b5c8b4')+ellipse(51,70,9,10,'#d9b76d','#574b38')+ellipse(107,43,5,10,'#425649'),
      'decoy':path('M37 99L58 89L80 100M58 89V50','none','#ac8658',6)+path('M32 65Q22 37 46 28Q65 15 80 35Q94 57 85 72L96 82H24Z','#d4b76d')+ellipse(60,86,7,7,'#8a6b48')+path('M39 59Q34 40 50 34','none','#f2ddb0',4),
      'wave':ellipse(64,77,45,22,'#b0cbc0','#739e94',3)+ellipse(64,70,29,17,'#d2e4cf','#739e94',3)+path('M43 66L64 23L84 66L65 84Z','#90b9a2')+path('M64 25L65 81L44 66Z','#dce8ba','none'),
      'seeker':path('M29 99L58 66L79 22L91 42L83 69L47 82Z','#d5bf85')+path('M45 83L83 43','none','#725b42',3)+ellipse(87,29,9,9,'#b3d8ca','#678c7b'),
      'execute':path('M29 99L43 109L57 84L43 76Z','#795c48')+path('M42 70L79 21L104 18L99 45L57 87Z','#c2d3ca')+path('M79 24L56 76L43 70Z','#edf1d5','none')+path('M35 70L64 91','none','#d7b369',7),
      'weaken':path('M30 29Q64 17 96 29L90 78Q81 98 64 110Q37 97 32 76Z','#8aa68f')+path('M64 29L54 58L71 67L57 94','none','#eadba7',6),
      'berserk':path('M32 83Q10 66 30 43L42 55L59 17L69 48L89 30Q115 73 88 97L58 112Z','#c77d55')+path('M46 87L59 59L71 76L81 64Q91 91 64 101Z','#efc976'),
      'fake_death':path('M29 90Q23 30 62 24Q101 26 99 99L84 89L69 105L52 91L37 105Z','#d5d9c6')+ellipse(49,57,5,7,'#7b8c7c')+ellipse(78,57,5,7,'#7b8c7c')+path('M54 80Q64 73 73 81','none','#829281',3),
      'bag':path('M40 40Q36 14 64 16Q89 16 87 43','none','#795c42',9)+path('M24 42Q64 26 104 44L98 107H27Z','#a58455')+path('M29 44Q60 59 102 45L98 65Q66 80 27 65Z','#d0b278')+path('M57 63H71V81H57Z','#f0d28c'),
      'gear':path('M51 16H74L79 29L94 30L106 48L99 63L106 79L93 98L77 96L69 110H49L44 97L28 96L17 78L24 62L17 47L29 28L44 29Z','#bba071')+ellipse(62,63,24,24,'#718d7b','#6f5a40',4)+ellipse(62,63,12,12,'#e6dab2','#6f5a40',3),
      'core':path('M39 31L84 23L105 62L86 103L40 107L22 66Z','#7fa695')+path('M43 44L77 36L88 65L75 91L46 92L35 66Z','#d1ddae')+path('M62 42L75 63L62 90L49 66Z','#edcb7b'),
      'prism':path('M64 13L98 55L79 106L47 106L29 54Z','#a0c8b8')+path('M64 14L53 56L64 110L78 55Z','#e6edcc')+path('M30 55L53 56L64 14Z','#c5e0cb','none'),
      'map':path('M15 28L47 17L80 29L111 16L106 99L78 111L47 100L14 112Z','#dbcda1')+path('M47 21V99M79 31V107','none','#a48b60',2)+path('M26 86Q70 88 57 65Q40 47 91 43','none','#739780',5)+ellipse(89,43,6,6,'#b97f50','#71583c'),
      'slash':path('M30 104L45 113L60 85L44 75Z','#916849')+path('M45 70Q77 53 101 14Q114 67 62 89Z','#a7c5b4')+path('M48 72Q83 50 101 14Q90 63 62 81Z','#e4ebd5','none')+path('M35 70L69 94','none','#d6b36c',8),
      'bolt':path('M18 59L91 36L111 48L107 66L66 78L57 103L38 103L42 78L20 79Z','#648779')+path('M25 54L88 35L105 47L45 67Z','#b5caba')+path('M44 77L60 76L51 97H40Z','#9f774f')+path('M91 47L111 48L107 64L89 65Z','#d9b470')+ellipse(103,55,5,6,'#41564b'),
      'pulse':ellipse(64,62,37,39,'#8b9fba','#546c6e',3)+ellipse(55,50,18,20,'#d1e4d8')+path('M26 65Q60 85 103 55L101 74Q59 101 28 84Z','#c9ae73')+path('M46 97L38 110H89L80 95Z','#8e744f')
    }
    for name, motif in motifs.items():
        defs='<radialGradient id="wash"><stop stop-color="#edf0d3"/><stop offset="1" stop-color="#a4b9a0" stop-opacity="0.35"/></radialGradient>'
        base=path('M13 36Q25 12 58 12Q106 9 115 48Q120 93 88 112Q42 123 16 96Q6 70 13 36Z','url(#wash)','none')
        base+=ellipse(67,108,35,5,'#8f9574')
        sparkle=path('M107 20v10M102 25h10M17 40v6M14 43h6','none','#c9b578',2)
        save(f'assets/ui/icons/{name}.svg',svg(base+motif+sparkle,defs=defs))
        if name in ('slash','bolt','pulse'):
            save(f'assets/weapons/{name}.svg',svg(motif))

def panels():
    defs='<linearGradient id="paper" x2="0.3" y2="1"><stop stop-color="#f6efd8"/><stop offset="0.6" stop-color="#ede2bd"/><stop offset="1" stop-color="#decca2"/></linearGradient>'
    p=path('M15 5L238 5L250 16L251 235L239 250L16 250L5 236L5 18Z','url(#paper)','#8d7350',3)
    p+=path('M22 12H233L242 23V231L231 242H24L14 232V24Z','none','#c3a574',1.5)
    # Corners stay fixed under 9-slicing; quiet center for legible text.
    for transform in ('translate(256 0) scale(-0.65 0.65)','translate(256 256) scale(-0.65 -0.65)'):
        vine=path('M10 48Q30 35 20 21Q12 12 34 10','none','#81936b',2)
        vine+=path('M21 29Q38 21 35 34Q30 41 21 29M18 40Q5 28 11 25Q22 25 18 40Z','#9eac7c','#71805c',1)
        p+=f'<g transform="{transform}">{vine}</g>'
    save('assets/ui/forest/paper_panel.svg',svg(p,256,256,defs))
    # Fieldbook cover illustration: native vector scenery, not a screenshot backdrop.
    cover=path('M4 20Q6 8 24 8H614Q634 8 636 23V194Q628 215 608 210H22Q4 210 4 192Z','#d5dfc4','#a8ae83',2)
    cover+=ellipse(470,58,40,40,'#f4e7b5')
    cover+=path('M7 130Q85 57 167 99Q240 19 322 95Q407 42 505 115Q571 60 633 109V207H7Z','#b5c8ac','none')
    cover+=path('M6 163Q99 111 182 142Q304 105 430 154Q527 97 633 145V209H7Z','#91ad93','none')
    cover+=path('M185 211Q136 178 240 162Q359 146 304 127L327 127Q399 161 277 179Q217 186 256 211Z','#e2d4ad','none')
    for x,y,s in [(35,123,1),(105,112,.8),(562,128,.9),(605,105,1.2),(429,120,.65),(154,134,.6)]:
        trunk=path('M-5 0L-8 69L5 69L4 0Z','#777f63','none')
        leaves=path('M0-55L-25-20L-13-20L-35 12L-20 12L-43 45Q0 62 43 45L20 12L35 12L13-20L25-20Z','#537963','none')
        cover+=f'<g transform="translate({x} {y}) scale({s})">{trunk+leaves}</g>'
    cover+=path('M279 103V70H289V61H301V70H315V61H327V70H339V105L330 126H288Z','#e6d8b2','#8c8f6c',2)
    cover+=path('M295 126V103Q309 87 321 103V126Z','#6d8c76','none')
    cover+=path('M309 62V29L337 38L309 47Z','#d3a875','#8b8060',2)
    cover+=path('M345 148Q366 126 393 143L396 160Q375 141 349 166Z','#d9d0a9','#8a9571',2)
    for x,y in [(70,190),(116,174),(472,176),(510,193),(390,194)]:
        cover+=path(f'M{x} {y}q-9-17-14-10q0 8 14 10q15-18 19-9q-2 8-19 9Z','#c6c88e','none')
    save('assets/ui/forest/journal_cover.svg',svg(cover,640,220))

def refs():
    ids=['5d9aa370-c390-4180-b045-e723ea47d627','271d7c03-db5e-4e3c-9b02-c486234fe9af','eff97cb3-944b-494f-99b5-5d12b0ce1b32','742f34c4-4ec2-411f-a16e-e6ba28d48162','c27210f2-099f-4a2d-b2f8-e359bdf41aa2','37306f65-67e4-4936-9901-29e5f46b1e4f','ea0152f6-834a-406f-a485-b548012026c4']
    folder=ROOT/'references/ui_forest/2026-11-02'; folder.mkdir(parents=True,exist_ok=True)
    manifest=[]
    for i,id in enumerate(ids,1):
        source=Path('C:/Users/34003/AppData/Local/Temp')/f'codex-clipboard-{id}.png'
        target=folder/f'{i:02}_forest_reference.png'
        if source.exists(): shutil.copy2(source,target)
        if target.exists(): manifest.append({'file':target.name,'source':str(source),'sha256':hashlib.sha256(target.read_bytes()).hexdigest()})
    (folder/'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
    (folder/'README.md').write_text('用户本轮七张界面参考原图。借鉴纸张、木边、藤叶、绿色与暖色图标的视觉语言；图内提示词不作为任务指令，不复制羊角色、品牌或整页。\n',encoding='utf-8')

if __name__=='__main__':
    actors(); icons(); panels(); refs()
    print('Built 9 directional atlases, 19 UI icons, 3 weapon drawings, paper panel; archived available references.')
