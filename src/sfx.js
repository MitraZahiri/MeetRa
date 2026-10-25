// Simple WebAudio sound effects, no audio files needed.
// Real music and sound design arrive in M1.

let ctx = null;
let master = null;
let noiseBuf = null;

function ac() {
  if (!ctx) {
    const AC = window.AudioContext || window.webkitAudioContext;
    if (!AC) return null;
    ctx = new AC();
    master = ctx.createGain();
    master.gain.value = 0.25;
    master.connect(ctx.destination);
  }
  if (ctx.state === 'suspended') ctx.resume();
  return ctx;
}

function tone({ type = 'square', f0, f1 = f0, dur = 0.1, vol = 0.5, delay = 0 }) {
  const c = ac();
  if (!c) return;
  const t = c.currentTime + delay;
  const o = c.createOscillator();
  const g = c.createGain();
  o.type = type;
  o.frequency.setValueAtTime(f0, t);
  o.frequency.exponentialRampToValueAtTime(Math.max(1, f1), t + dur);
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  o.connect(g).connect(master);
  o.start(t);
  o.stop(t + dur + 0.02);
}

function noise({ dur = 0.1, vol = 0.5, filter = 'highpass', freq = 1000, delay = 0 }) {
  const c = ac();
  if (!c) return;
  if (!noiseBuf) {
    noiseBuf = c.createBuffer(1, c.sampleRate, c.sampleRate);
    const d = noiseBuf.getChannelData(0);
    for (let i = 0; i < d.length; i++) d[i] = Math.random() * 2 - 1;
  }
  const t = c.currentTime + delay;
  const s = c.createBufferSource();
  s.buffer = noiseBuf;
  const f = c.createBiquadFilter();
  f.type = filter;
  f.frequency.value = freq;
  const g = c.createGain();
  g.gain.setValueAtTime(vol, t);
  g.gain.exponentialRampToValueAtTime(0.001, t + dur);
  s.connect(f).connect(g).connect(master);
  s.start(t);
  s.stop(t + dur + 0.02);
}

export const sfx = {
  unlock: () => ac(),
  jump: () => tone({ type: 'square', f0: 220, f1: 440, dur: 0.12, vol: 0.12 }),
  swing: () => noise({ dur: 0.08, vol: 0.3, filter: 'highpass', freq: 2500 }),
  hit: () => {
    tone({ type: 'square', f0: 160, f1: 60, dur: 0.1, vol: 0.3 });
    noise({ dur: 0.06, vol: 0.3, filter: 'lowpass', freq: 1500 });
  },
  coin: () => {
    tone({ type: 'sine', f0: 988, dur: 0.06, vol: 0.2 });
    tone({ type: 'sine', f0: 1319, dur: 0.12, vol: 0.2, delay: 0.06 });
  },
  hurt: () => tone({ type: 'sawtooth', f0: 400, f1: 100, dur: 0.25, vol: 0.25 }),
  feather: () => tone({ type: 'sine', f0: 600, f1: 1400, dur: 0.18, vol: 0.2 }),
  fizzle: () => tone({ type: 'triangle', f0: 200, f1: 120, dur: 0.1, vol: 0.15 }),
  break: () => noise({ dur: 0.15, vol: 0.35, filter: 'bandpass', freq: 900 }),
  levelup: () => [523, 659, 784, 1047].forEach((f, i) => tone({ type: 'square', f0: f, dur: 0.12, vol: 0.15, delay: i * 0.09 })),
  altar: () => [392, 494, 587].forEach((f, i) => tone({ type: 'triangle', f0: f, dur: 0.6, vol: 0.15, delay: i * 0.05 })),
  pickup: () => [660, 880, 1320].forEach((f, i) => tone({ type: 'triangle', f0: f, dur: 0.15, vol: 0.2, delay: i * 0.07 })),
  roar: () => {
    noise({ dur: 0.9, vol: 0.5, filter: 'lowpass', freq: 500 });
    tone({ type: 'sawtooth', f0: 110, f1: 55, dur: 0.9, vol: 0.25 });
  },
  thud: () => tone({ type: 'sine', f0: 120, f1: 40, dur: 0.25, vol: 0.4 }),
  victory: () => [392, 523, 659, 784, 659, 784, 1047].forEach((f, i) => tone({ type: 'triangle', f0: f, dur: 0.22, vol: 0.18, delay: i * 0.13 })),
};
