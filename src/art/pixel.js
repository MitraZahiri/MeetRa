// Helpers for generating pixel art from code.
// Each frame is an array of strings; each character maps to a palette color ('.' = transparent).

export function pixelSheet(scene, key, frames, palette) {
  const h = Math.max(...frames.map((f) => f.length));
  const w = Math.max(...frames.flatMap((f) => f.map((r) => r.length)));
  const tex = scene.textures.createCanvas(key, w * frames.length, h);
  const ctx = tex.getContext();
  frames.forEach((rows, i) => {
    rows.forEach((row, y) => {
      for (let x = 0; x < row.length; x++) {
        const col = palette[row[x]];
        if (!col) continue;
        ctx.fillStyle = col;
        ctx.fillRect(i * w + x, y, 1, 1);
      }
    });
    tex.add(i, 0, i * w, 0, w, h);
  });
  tex.refresh();
  return tex;
}

export function canvasTexture(scene, key, w, h, draw) {
  const tex = scene.textures.createCanvas(key, w, h);
  draw(tex.getContext(), w, h);
  tex.refresh();
  return tex;
}

// Seeded random generator (mulberry32) so generated art is identical on every load
export function rng(seed) {
  return () => {
    seed = (seed + 0x6d2b79f5) | 0;
    let t = Math.imul(seed ^ (seed >>> 15), 1 | seed);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const mirror = (rows) => rows.map((r) => [...r].reverse().join(''));
