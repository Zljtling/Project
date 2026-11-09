"""Build original, deterministic pixel textures. Python standard library only."""
from pathlib import Path
import random
import struct
import zlib

OUT = Path(__file__).resolve().parents[1] / 'assets' / 'regions' / 'shared'


def png(name, rows):
    height, width = len(rows), len(rows[0])
    raw = b''.join(b'\0' + bytes(c for pixel in row for c in pixel) for row in rows)
    def chunk(kind, data):
        return struct.pack('!I', len(data)) + kind + data + struct.pack('!I', zlib.crc32(kind + data))
    OUT.mkdir(parents=True, exist_ok=True)
    (OUT / name).write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('!2I5B', width, height, 8, 6, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(raw)) + chunk(b'IEND', b''))


def surfaces():
    rng = random.Random(417)
    for name, base in [('plaster', (162, 153, 121)), ('stone', (105, 115, 104)), ('roof', (73, 103, 109)), ('wood', (106, 75, 49)), ('grass', (77, 96, 65)), ('dirt', (125, 113, 83))]:
        rows = []
        for y in range(64):
            row = []
            for x in range(64):
                shade = rng.choice([-7, -3, 0, 0, 3, 6])
                if name in ('stone', 'roof'):
                    course = 8 if name == 'roof' else 16
                    if y % course == 0 or (x + (y // course % 2) * 8) % 16 == 0:
                        shade -= 25
                    elif y % course == 1:
                        shade += 14
                if name == 'wood' and x % 8 in (0, 1):
                    shade -= 23
                row.append(tuple(max(0, min(255, v + shade)) for v in base) + (255,))
            rows.append(row)
        png(name + '.png', rows)


def traveler():
    # Four directions (south, west, east, north), four walk poses each.
    palette = {'.': (0, 0, 0, 0), 'o': (37, 36, 40, 255), 'h': (78, 50, 37, 255), 's': (222, 170, 116, 255), 'l': (248, 204, 145, 255), 'c': (54, 108, 115, 255), 't': (87, 149, 147, 255), 'b': (117, 72, 42, 255), 'p': (56, 64, 74, 255), 'g': (207, 162, 68, 255)}
    face = ['.....oooooo.....', '....ohhhhhho....', '...ohhhhhhhho...', '...ohllllllho...', '....sosssos.....', '....sslllss.....', '.....sssss......']
    back = ['.....oooooo.....', '....ohhhhhho....', '...ohhhhhhhho...', '...ohhhhhhhho...', '....ohhhhho.....', '....ohhhhho.....', '.....sssss......']
    rows = [[palette['.']] * 64 for _ in range(112)]
    for direction in range(4):
        for frame in range(4):
            art = ['................'] * 3 + (back if direction == 3 else face) + ['....otttttto....', '...octtttttco...', '..osccctgcccso..', '..osccccccccso..', '...scccbcccbs...', '....cbbbbbbc....', '....occcccco....', '....occcccco....', '.....pppppp.....', '.....pp..pp.....', '.....pp..pp.....', '....obb..bbo....', '....ooo..ooo....', '................', '................', '................', '................', '................']
            for y, line in enumerate(art):
                for x, key in enumerate(line):
                    xx = x
                    if direction in (1, 2) and key in ('s', 'l') and y < 10:
                        xx = max(2, x - 1) if direction == 1 else min(13, x + 1)
                    yy = y - (1 if frame in (1, 3) and y < 18 else 0)
                    if y >= 19 and y <= 22 and frame in (1, 3):
                        yy += (1 if (x < 8) == (frame == 1) else -1)
                    if 0 <= yy < 28:
                        rows[direction * 28 + yy][frame * 16 + xx] = palette[key]
    png('traveler.png', rows)


if __name__ == '__main__':
    surfaces()
    traveler()
    print('Built six surface textures and traveler sheet:', OUT)
