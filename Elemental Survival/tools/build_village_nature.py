"""Original clustered pixel foliage and broad-value architectural textures.

These are authored from shapes/palettes, never sampled from reference pictures.
Run after build_village_textures.py. Standard library only.
"""
import math
import random
from build_village_textures import png


def foliage():
    rng = random.Random(903)
    palette = [(28, 65, 57), (38, 83, 63), (57, 103, 66), (85, 124, 67), (117, 145, 75), (145, 163, 88)]
    clusters = [(64, 58, 49)]
    clusters += [(rng.randrange(24, 105), rng.randrange(29, 94), rng.randrange(13, 28)) for _ in range(34)]
    rows = [[(0, 0, 0, 0)] * 128 for _ in range(128)]
    for cx, cy, radius in clusters:
        for y in range(max(0, cy-radius-3), min(128, cy+radius+4)):
            for x in range(max(0, cx-radius-3), min(128, cx+radius+4)):
                dx, dy = x-cx, (y-cy)*1.13
                angle = math.atan2(dy, dx)
                edge = radius + 2*math.sin(angle*11 + cx) + math.sin(angle*23)
                if dx*dx+dy*dy > edge*edge:
                    continue
                # Leaf shapes are clustered into pixels, not independent white noise.
                leaf = math.sin((x//7)*1.7 + (y//5)*2.1) + math.cos((x//9)*2.6 - (y//7))
                light = 3.0 - 1.35*dy/radius - 0.75*dx/radius - 0.012*(cy-50) + 0.28*leaf
                index = max(0, min(5, int(light)))
                if dx*dx+dy*dy > (edge-2)**2:
                    index = max(0, index-1)
                rows[y][x] = palette[index] + (255,)
    png('foliage.png', rows)


def grass_clump():
    rows = [[(0, 0, 0, 0)] * 32 for _ in range(24)]
    rng = random.Random(717)
    for i in range(13):
        x = rng.randrange(3, 29)
        top = rng.randrange(3, 16)
        lean = rng.choice([-3, -2, 2, 3])
        color = rng.choice([(67, 100, 55, 255), (91, 123, 64, 255), (123, 145, 78, 255)])
        for y in range(top, 23):
            xx = x + int(lean*(23-y)/(23-top))
            rows[y][max(0, min(31, xx))] = color
            if y > top+4:
                rows[y][max(0, min(31, xx+1))] = color
    png('grass_clump.png', rows)


def surfaces():
    rng = random.Random(123)
    # Quiet plaster, broad roof shingles and grass masses avoid noisy miniature bricks.
    for name, base in [('plaster', (190, 177, 145)), ('wood', (116, 79, 65)), ('roof', (92, 120, 137)), ('grass', (93, 121, 64)), ('dirt', (139, 122, 89)), ('stone', (138, 148, 142))]:
        rows = []
        for y in range(64):
            row = []
            for x in range(64):
                noise = math.sin(x/9)*math.cos(y/11) + math.sin((x+y)/17)
                shade = int(noise)*3
                if name == 'grass':
                    shade = int(noise)*7 + (1 if rng.random() < 0.03 else 0)
                elif name == 'roof':
                    course = y//16
                    column = ((x + (course%2)*16)//32)%2
                    shade = [0, 12, -10, 5][(course+column)%4]
                    seam = (x+(course%2)*16)%32
                    if y%16 < 2 or seam < 2:
                        shade = -35
                    elif y%16 < 4:
                        shade += 17
                    if seam > 26 and y%16 > 9:
                        shade -= 9
                elif name == 'wood':
                    shade += -24 if y%16 < 2 else 0
                    if (x//4+y//3)%17 == 0:
                        shade -= 9
                elif name == 'stone':
                    if y%32 < 2 or (x + (y//32)*16)%32 < 2:
                        shade -= 28
                row.append(tuple(max(0, min(255, v+shade)) for v in base)+(255,))
            rows.append(row)
        png(name+'.png', rows)


if __name__ == '__main__':
    foliage()
    grass_clump()
    surfaces()
    print('Built clustered foliage, grass and refined surfaces.')
