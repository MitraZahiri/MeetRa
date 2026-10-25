import { TILE, T } from '../config.js';

// Joins ASCII chunks side by side into tilemap data plus an object list.
// Each chunk is bottom-aligned; short rows are padded with '.'.
//
// Legend:
//   #  ground (grass on top, dirt below)   =  one-way platform
//   B  stone brick   ^  thorns
//   P  player        A  hearth (checkpoint)   S  signpost
//   D  imp           V  bat      v  vase     *  bush     C  chest
//   F  Saena's feather   L  lion boss   [ ]  boss arena walls   G  exit gate
export function buildLevel(def) {
  const height = def.rows;
  const rows = Array.from({ length: height }, () => '');
  for (const chunk of def.chunks) {
    const w = Math.max(...chunk.map((r) => r.length));
    const padded = [...Array(height - chunk.length).fill(''), ...chunk].map((r) => r.padEnd(w, '.'));
    padded.forEach((r, i) => { rows[i] += r; });
  }

  const cols = rows[0].length;
  const data = [];
  const objects = [];
  for (let y = 0; y < height; y++) {
    const line = [];
    for (let x = 0; x < cols; x++) {
      const c = rows[y][x];
      let t = -1;
      if (c === '#') t = y > 0 && rows[y - 1][x] === '#' ? T.DIRT : T.GRASS;
      else if (c === '=') t = T.PLATFORM;
      else if (c === 'B') t = T.BRICK;
      else if (c === '^') t = T.SPIKES;
      else if (c !== '.' && c !== ' ') {
        objects.push({ type: c, tx: x, ty: y, x: x * TILE + TILE / 2, y: (y + 1) * TILE });
      }
      line.push(t);
    }
    data.push(line);
  }

  return { data, objects, cols, rows: height, width: cols * TILE, height: height * TILE };
}
