"""Draws the MeetRa world map as an SVG string (parchment style, ornamental, print-ready)."""

import math
import random

from stories import STORIES

W, H = 1600, 1100
INK = "#3b2a1a"
SEA = "#9cc3c0"
SEA_DEEP = "#7fb0ad"
GOLD = "#b8892e"
LAPIS = "#1b2a6b"
RED = "#a8322a"


def smooth(points, closed=True):
    """Catmull-Rom spline through points, as an SVG path."""
    pts = list(points)
    n = len(pts)
    if closed:
        get = lambda i: pts[i % n]
        rng_ = range(n)
    else:
        get = lambda i: pts[max(0, min(n - 1, i))]
        rng_ = range(n - 1)
    d = f"M{pts[0][0]:.1f},{pts[0][1]:.1f}"
    for i in rng_:
        p0, p1, p2, p3 = get(i - 1), get(i), get(i + 1), get(i + 2)
        c1 = (p1[0] + (p2[0] - p0[0]) / 6, p1[1] + (p2[1] - p0[1]) / 6)
        c2 = (p2[0] - (p3[0] - p1[0]) / 6, p2[1] - (p3[1] - p1[1]) / 6)
        d += f" C{c1[0]:.1f},{c1[1]:.1f} {c2[0]:.1f},{c2[1]:.1f} {p2[0]:.1f},{p2[1]:.1f}"
    return d + (" Z" if closed else "")


def along(points, step):
    """Evenly spaced points along a polyline."""
    out = []
    for (x1, y1), (x2, y2) in zip(points, points[1:]):
        dist = math.hypot(x2 - x1, y2 - y1)
        k = max(1, int(dist / step))
        for i in range(k):
            t = i / k
            out.append((x1 + (x2 - x1) * t, y1 + (y2 - y1) * t))
    out.append(points[-1])
    return out


def mountain(x, y, s, snow=False):
    w, h = 22 * s, 26 * s
    left = f"M{x - w:.1f},{y:.1f} L{x:.1f},{y - h:.1f} L{x + w:.1f},{y:.1f} Z"
    shade = f"M{x:.1f},{y - h:.1f} L{x + w:.1f},{y:.1f} L{x + w * 0.15:.1f},{y:.1f} Z"
    g = f'<path d="{left}" fill="#d9c08f" stroke="{INK}" stroke-width="1.4" stroke-linejoin="round"/>'
    g += f'<path d="{shade}" fill="#b4935c" opacity="0.8"/>'
    if snow:
        cap = f"M{x - w * 0.32:.1f},{y - h * 0.68:.1f} L{x:.1f},{y - h:.1f} L{x + w * 0.32:.1f},{y - h * 0.68:.1f} L{x + w * 0.1:.1f},{y - h * 0.6:.1f} L{x - w * 0.1:.1f},{y - h * 0.72:.1f} Z"
        g += f'<path d="{cap}" fill="#fbf7ee" stroke="{INK}" stroke-width="0.8"/>'
    return g


def cypress(x, y, s=1.0, color="#3e6b4a", dark="#2b4d35"):
    return (
        f'<line x1="{x:.1f}" y1="{y:.1f}" x2="{x:.1f}" y2="{y + 4 * s:.1f}" stroke="{INK}" stroke-width="1.2"/>'
        f'<path d="M{x:.1f},{y - 22 * s:.1f} C{x + 7 * s:.1f},{y - 12 * s:.1f} {x + 6 * s:.1f},{y:.1f} {x:.1f},{y:.1f} '
        f'C{x - 6 * s:.1f},{y:.1f} {x - 7 * s:.1f},{y - 12 * s:.1f} {x:.1f},{y - 22 * s:.1f} Z" fill="{color}" stroke="{INK}" stroke-width="0.9"/>'
        f'<path d="M{x:.1f},{y - 20 * s:.1f} C{x + 4 * s:.1f},{y - 12 * s:.1f} {x + 4 * s:.1f},{y - 2 * s:.1f} {x:.1f},{y - 1 * s:.1f} Z" fill="{dark}"/>'
    )


def city(x, y, name, big=False, dx=0, dy=24):
    s = 1.4 if big else 1.0
    w, h = 12 * s, 16 * s
    arch = (
        f'<rect x="{x - w:.1f}" y="{y - h:.1f}" width="{2 * w:.1f}" height="{h:.1f}" fill="{LAPIS}" stroke="{GOLD}" stroke-width="1.5"/>'
        f'<path d="M{x - w * 0.5:.1f},{y:.1f} L{x - w * 0.5:.1f},{y - h * 0.5:.1f} Q{x - w * 0.5:.1f},{y - h * 0.85:.1f} {x:.1f},{y - h * 0.92:.1f} '
        f'Q{x + w * 0.5:.1f},{y - h * 0.85:.1f} {x + w * 0.5:.1f},{y - h * 0.5:.1f} L{x + w * 0.5:.1f},{y:.1f} Z" fill="#f2e6c9"/>'
    )
    if big:
        arch += f'<circle cx="{x:.1f}" cy="{y - h - 6:.1f}" r="5" fill="{GOLD}" stroke="{INK}" stroke-width="1"/>'
    label = f'<text x="{x + dx:.1f}" y="{y + dy:.1f}" class="city">{name}</text>'
    return arch + label


def region(x, y, name, sub=None, size=26, rot=0):
    t = f'<text x="{x}" y="{y}" class="region" font-size="{size}" transform="rotate({rot} {x} {y})">{name}</text>'
    if sub:
        t += f'<text x="{x}" y="{y + size * 0.8 + 4}" class="sub" transform="rotate({rot} {x} {y})">{sub}</text>'
    return t


def relax_pins(pins, min_d=27, iters=300, fixed=()):
    """Pushes pins apart, and away from fixed points (city icons), so nothing overlaps."""
    pos = {n: [x, y] for n, (x, y) in pins.items()}
    for _ in range(iters):
        moved = False
        for p in pos.values():
            for fx, fy, fr in fixed:
                dx, dy = p[0] - fx, p[1] - fy
                d = math.hypot(dx, dy) or 0.01
                if d < fr:
                    p[0] += dx / d * (fr - d + 0.2)
                    p[1] += dy / d * (fr - d + 0.2)
                    moved = True
        keys = list(pos)
        for i, a in enumerate(keys):
            for b in keys[i + 1:]:
                dx = pos[b][0] - pos[a][0]
                dy = pos[b][1] - pos[a][1]
                d = math.hypot(dx, dy) or 0.01
                if d < min_d:
                    push = (min_d - d) / 2 + 0.2
                    ux, uy = dx / d, dy / d
                    pos[a][0] -= ux * push
                    pos[a][1] -= uy * push
                    pos[b][0] += ux * push
                    pos[b][1] += uy * push
                    moved = True
        if not moved:
            break
    return pos


def build_map():
    rnd = random.Random(7)
    out = []
    out.append(f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {W} {H}" class="worldmap">')
    out.append(
        """<defs>
  <radialGradient id="paper" cx="50%" cy="45%" r="75%">
    <stop offset="0%" stop-color="#f6ecd2"/><stop offset="70%" stop-color="#ead9b0"/><stop offset="100%" stop-color="#d6bd8a"/>
  </radialGradient>
  <filter id="grain" x="0" y="0" width="100%" height="100%">
    <feTurbulence type="fractalNoise" baseFrequency="0.9" numOctaves="2" seed="4" result="n"/>
    <feColorMatrix type="matrix" values="0 0 0 0 0.35  0 0 0 0 0.25  0 0 0 0 0.12  0 0 0 0.16 0"/>
  </filter>
  <pattern id="waves" width="46" height="22" patternUnits="userSpaceOnUse">
    <path d="M2,12 q9,-8 18,0 q9,8 18,0" fill="none" stroke="#5f908d" stroke-width="1.1" opacity="0.55"/>
  </pattern>
  <pattern id="sand" width="18" height="18" patternUnits="userSpaceOnUse">
    <circle cx="3" cy="4" r="1" fill="#a0783c" opacity="0.55"/><circle cx="12" cy="11" r="0.9" fill="#a0783c" opacity="0.5"/>
    <circle cx="7" cy="15" r="0.7" fill="#a0783c" opacity="0.45"/>
  </pattern>
  <radialGradient id="fog" cx="30%" cy="20%" r="60%">
    <stop offset="0%" stop-color="#4a4658" stop-opacity="0.38"/><stop offset="100%" stop-color="#4a4658" stop-opacity="0"/>
  </radialGradient>
</defs>"""
    )
    out.append(f'<clipPath id="frame"><rect x="22" y="22" width="{W - 44}" height="{H - 44}"/></clipPath>')
    out.append('<g clip-path="url(#frame)">')
    out.append(f'<rect width="{W}" height="{H}" fill="url(#paper)"/>')
    out.append(f'<rect width="{W}" height="{H}" filter="url(#grain)"/>')

    # Seas
    seas = {
        "inner": [(700, 150), (780, 108), (880, 118), (962, 168), (992, 250), (952, 322), (870, 346), (780, 332), (712, 290), (690, 220)],
        "west": [(0, 220), (120, 245), (262, 236), (362, 282), (392, 362), (334, 432), (364, 522), (300, 604), (180, 642), (0, 626)],
        "south": [(0, 1040), (250, 1062), (420, 1022), (560, 942), (640, 862), (720, 800), (792, 832), (806, 902), (900, 962),
                  (1100, 982), (1300, 962), (1450, 902), (1600, 880), (1640, 1140), (-40, 1140)],
    }
    for key, pts in seas.items():
        d = smooth(pts)
        out.append(f'<path d="{d}" fill="none" stroke="{SEA_DEEP}" stroke-width="16" opacity="0.35"/>')
        out.append(f'<path d="{d}" fill="{SEA}" stroke="{INK}" stroke-width="2.2"/>')
        out.append(f'<path d="{d}" fill="url(#waves)"/>')

    # Rivers
    rivers = [
        [(1250, 700), (1185, 565), (1100, 432), (1032, 322), (978, 262)],  # Ashen River
        [(430, 420), (520, 560), (604, 700), (706, 806)],
        [(492, 395), (566, 560), (646, 715), (716, 810)],
        [(1350, 560), (1420, 650), (1470, 760), (1500, 890)],
    ]
    for r in rivers:
        d = smooth(r, closed=False)
        out.append(f'<path d="{d}" fill="none" stroke="{INK}" stroke-width="5" stroke-linecap="round"/>')
        out.append(f'<path d="{d}" fill="none" stroke="{SEA}" stroke-width="3" stroke-linecap="round"/>')

    # Deserts
    deserts = [
        [(330, 700), (470, 680), (600, 740), (620, 860), (520, 930), (380, 920), (300, 820)],
        [(990, 600), (1090, 590), (1130, 650), (1080, 700), (1000, 690)],
    ]
    for dpts in deserts:
        out.append(f'<path d="{smooth(dpts)}" fill="url(#sand)" stroke="#a0783c" stroke-width="1" stroke-dasharray="3 5"/>')
    for _ in range(26):
        x, y = rnd.uniform(350, 590), rnd.uniform(720, 900)
        out.append(f'<path d="M{x:.0f},{y:.0f} q8,-6 16,0" fill="none" stroke="#a0783c" stroke-width="1.1" opacity="0.7"/>')

    # Lightless Land fog
    out.append('<ellipse cx="300" cy="90" rx="330" ry="150" fill="url(#fog)"/>')

    # Forests
    for _ in range(46):  # Frostwood (pale)
        x, y = rnd.uniform(712, 862), rnd.uniform(358, 396)
        out.append(cypress(x, y, rnd.uniform(0.7, 1.0), "#c9d9dc", "#9db6bb"))
    for area, n in [((90, 330, 300, 420), 18), ((1000, 760, 1220, 830), 16), ((560, 470, 660, 540), 9), ((1350, 300, 1520, 360), 12)]:
        for _ in range(n):
            out.append(cypress(rnd.uniform(area[0], area[2]), rnd.uniform(area[1], area[3]), rnd.uniform(0.7, 1.1)))

    # Mountain ranges
    ranges = [
        ([(590, 440), (700, 425), (790, 450), (880, 422), (1000, 446), (1090, 470)], 1.0),  # Sky Spine
        ([(560, 500), (590, 590), (620, 660)], 0.8),
        ([(1240, 590), (1340, 560), (1460, 520), (1540, 470)], 0.9),
        ([(1270, 440), (1330, 450)], 1.1),
        ([(1420, 110), (1500, 128), (1560, 100)], 0.9),
        ([(420, 360), (500, 380)], 0.8),
    ]
    mts = []
    for pts, s in ranges:
        for (x, y) in along(pts, 34):
            mts.append((x + rnd.uniform(-6, 6), y + rnd.uniform(-8, 8), s * rnd.uniform(0.8, 1.15)))
    for x, y, s in sorted(mts, key=lambda m: m[1]):
        out.append(mountain(x, y, s, snow=y < 470 and rnd.random() < 0.5))
    out.append(mountain(820, 452, 1.9, snow=True))  # Chain Mountain
    out.append(mountain(905, 430, 2.2, snow=True))  # Saena's Peak
    # Saena (bird) above her peak
    out.append(f'<path d="M932,380 q20,-26 36,-4 q16,-22 36,4 q-18,-6 -36,8 q-18,-14 -36,-8 Z" fill="#2bb3a8" stroke="{INK}" stroke-width="1.4"/>')
    out.append(f'<path d="M968,384 l6,16 l-12,0 Z" fill="{GOLD}" stroke="{INK}" stroke-width="1"/>')

    # Wall of Yag
    out.append(f'<path d="M1100,70 L1340,98" stroke="{INK}" stroke-width="7"/>')
    out.append(f'<path d="M1100,70 L1340,98" stroke="#c8b08a" stroke-width="4" stroke-dasharray="6 3"/>')

    # Seven Trials route
    route = [(1120, 760), (1082, 706), (1040, 640), (992, 568), (944, 505), (908, 470), (864, 418), (826, 380)]
    out.append(f'<path d="{smooth(route, closed=False)}" fill="none" stroke="{RED}" stroke-width="3.2" stroke-dasharray="9 7"/>')
    for i, (x, y) in enumerate(route[1:], 1):
        roman = "I II III IV V VI VII".split()[i - 1]
        out.append(f'<circle cx="{x}" cy="{y}" r="11" fill="{RED}" stroke="#fbf3df" stroke-width="2"/>')
        out.append(f'<text x="{x}" y="{y + 4}" class="trial">{roman}</text>')

    # Cities
    out.append(city(760, 600, "", big=True))
    out.append(city(1120, 760, "", big=True))
    out.append(city(1262, 640, "Kabulmere", dy=-22))
    out.append(city(1420, 380, "Aven's City", dy=26))
    out.append(city(222, 330, "Marble Throne", dy=26))
    out.append(city(380, 1000, "Copper Keep", dy=-24))
    out.append(city(1332, 520, "Silverhill", dy=-22))
    out.append(city(660, 820, "Wormhold", dy=-22))
    out.append(city(1450, 820, "Spice Port", dy=26))

    # Region names
    out.append(region(560, 160, "THE LIGHTLESS LAND", "where the Water of Life is hidden", 22))
    out.append(region(840, 232, "THE INNER SEA", None, 22))
    out.append(region(790, 352, "FROSTWOOD", None, 14))
    out.append(region(500, 445, "SKY SPINE", "Saena's Peak · Chain Mountain", 18))
    out.append(region(780, 700, "CROWNHOLD", "the heartland", 30))
    out.append(region(1330, 180, "THE DUSKLAND", "realm of the Dusk Khan", 32))
    out.append(region(1175, 470, "Ashen River", None, 15, 52))
    out.append(region(1480, 70, "THE SILK EAST", None, 18))
    out.append(region(1200, 128, "Wall of Yag", None, 13, 6))
    out.append(region(180, 470, "THE WESTERN SEA", None, 22))
    out.append(region(210, 300, "THE MARBLE WEST", None, 22))
    out.append(region(480, 770, "THE SERPENT SANDS", None, 22))
    out.append(region(560, 600, "Two Rivers", None, 15, 58))
    out.append(region(250, 1015, "THE COPPER COAST", None, 15))
    out.append(region(1470, 765, "THE SPICE SHORE", None, 18))
    out.append(region(950, 1045, "THE SOUTHERN SEA", None, 26))
    out.append(region(1130, 880, "HEARTHVALE", "home of Ra", 22))
    out.append(region(1300, 690, "Shadewell", None, 15))
    out.append(region(1200, 282, "Stone Pit", None, 13))

    # Chapter pins (relaxed so they never overlap)
    raw = {s["n"]: s["pin"] for s in STORIES}
    pos = relax_pins(raw, fixed=[(760, 590, 34), (1120, 750, 34)])
    for n, (ox, oy) in raw.items():
        x, y = pos[n]
        if math.hypot(x - ox, y - oy) > 3:
            out.append(f'<line x1="{ox}" y1="{oy}" x2="{x:.1f}" y2="{y:.1f}" stroke="{INK}" stroke-width="1" opacity="0.6"/>')
            out.append(f'<circle cx="{ox}" cy="{oy}" r="2.2" fill="{INK}"/>')
    for n in raw:
        x, y = pos[n]
        out.append(f'<circle cx="{x:.1f}" cy="{y:.1f}" r="12" fill="#fbf3df" stroke="{LAPIS}" stroke-width="2.2"/>')
        out.append(f'<text x="{x:.1f}" y="{y + 4.2:.1f}" class="pin">{n}</text>')

    # Compass rose
    cx, cy = 170, 740
    for a, l in [(0, 60), (90, 40), (180, 40), (270, 40), (45, 26), (135, 26), (225, 26), (315, 26)]:
        r = math.radians(a - 90)
        tip = (cx + math.cos(r) * l, cy + math.sin(r) * l)
        lft = (cx + math.cos(r - 1.4) * 8, cy + math.sin(r - 1.4) * 8)
        rgt = (cx + math.cos(r + 1.4) * 8, cy + math.sin(r + 1.4) * 8)
        out.append(f'<path d="M{lft[0]:.1f},{lft[1]:.1f} L{tip[0]:.1f},{tip[1]:.1f} L{rgt[0]:.1f},{rgt[1]:.1f} Z" fill="{GOLD if a % 90 == 0 else LAPIS}" stroke="{INK}" stroke-width="1"/>')
    out.append(f'<circle cx="{cx}" cy="{cy}" r="7" fill="{RED}" stroke="{INK}"/>')
    out.append(f'<text x="{cx}" y="{cy - 68}" class="region" font-size="18">N</text>')

    # Cartouche
    out.append(f'<rect x="1210" y="990" width="360" height="86" rx="6" fill="#f6ecd2" stroke="{GOLD}" stroke-width="3"/>')
    out.append(f'<rect x="1218" y="998" width="344" height="70" rx="4" fill="none" stroke="{LAPIS}" stroke-width="1.2"/>')
    out.append('<text x="1390" y="1032" class="carto" font-size="17">THE REALM OF THE DAWNFIRE</text>')
    out.append('<text x="1390" y="1056" class="sub" font-size="15">World of MeetRa · numbered pins = saga chapters</text>')

    # Legend
    lx, ly = 34, 850
    out.append(f'<rect x="{lx}" y="{ly}" width="330" height="96" rx="6" fill="#f6ecd2" stroke="{GOLD}" stroke-width="2" opacity="0.95"/>')
    out.append(f'<circle cx="{lx + 22}" cy="{ly + 24}" r="10" fill="#fbf3df" stroke="{LAPIS}" stroke-width="2"/><text x="{lx + 22}" y="{ly + 28}" class="pin" font-size="11">7</text>')
    out.append(f'<text x="{lx + 42}" y="{ly + 29}" class="legend">Saga chapter (see chapter number)</text>')
    out.append(f'<circle cx="{lx + 22}" cy="{ly + 52}" r="10" fill="{RED}"/><text x="{lx + 22}" y="{ly + 56}" class="trial" font-size="10">IV</text>')
    out.append(f'<text x="{lx + 42}" y="{ly + 57}" class="legend">The Seven Trials route (episode one)</text>')
    out.append(f'<rect x="{lx + 13}" y="{ly + 68}" width="18" height="16" fill="{LAPIS}" stroke="{GOLD}"/>')
    out.append(f'<text x="{lx + 42}" y="{ly + 82}" class="legend">City · Hearth</text>')

    out.append("</g>")

    # Ornamental border
    out.append(f'<rect x="8" y="8" width="{W - 16}" height="{H - 16}" fill="none" stroke="{LAPIS}" stroke-width="10"/>')
    out.append(f'<rect x="8" y="8" width="{W - 16}" height="{H - 16}" fill="none" stroke="{GOLD}" stroke-width="3" stroke-dasharray="14 6"/>')
    out.append(f'<rect x="22" y="22" width="{W - 44}" height="{H - 44}" fill="none" stroke="{INK}" stroke-width="1.2"/>')
    out.append("</svg>")
    return "\n".join(out)
