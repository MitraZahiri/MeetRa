// Simple synthesized sound effects, no audio files needed.
// Each effect is rendered once to a WAV file at startup, then played from a small pool of players.
// Real music and sound design arrive in M1.

import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:audioplayers/audioplayers.dart';
import 'package:path_provider/path_provider.dart';

const _rate = 22050;
const _master = 0.25;

class _Voice {
  const _Voice.tone({required this.type, required this.f0, double? f1, this.dur = 0.1, this.vol = 0.5, this.delay = 0})
      : f1 = f1 ?? f0,
        filter = null,
        freq = 0;
  const _Voice.noise({this.dur = 0.1, this.vol = 0.5, this.filter = 'highpass', this.freq = 1000, this.delay = 0})
      : type = 'noise',
        f0 = 0,
        f1 = 0;

  final String type;
  final double f0, f1, dur, vol, delay, freq;
  final String? filter;
}

_Voice _tone(String type, double f0, {double? f1, double dur = 0.1, double vol = 0.5, double delay = 0}) =>
    _Voice.tone(type: type, f0: f0, f1: f1, dur: dur, vol: vol, delay: delay);
_Voice _noise({double dur = 0.1, double vol = 0.5, String filter = 'highpass', double freq = 1000, double delay = 0}) =>
    _Voice.noise(dur: dur, vol: vol, filter: filter, freq: freq, delay: delay);

final Map<String, List<_Voice>> _effects = {
  'jump': [_tone('square', 220, f1: 440, dur: 0.12, vol: 0.12)],
  'swing': [_noise(dur: 0.08, vol: 0.3, filter: 'highpass', freq: 2500)],
  'hit': [_tone('square', 160, f1: 60, dur: 0.1, vol: 0.3), _noise(dur: 0.06, vol: 0.3, filter: 'lowpass', freq: 1500)],
  'coin': [_tone('sine', 988, dur: 0.06, vol: 0.2), _tone('sine', 1319, dur: 0.12, vol: 0.2, delay: 0.06)],
  'hurt': [_tone('sawtooth', 400, f1: 100, dur: 0.25, vol: 0.25)],
  'feather': [_tone('sine', 600, f1: 1400, dur: 0.18, vol: 0.2)],
  'fizzle': [_tone('triangle', 200, f1: 120, dur: 0.1, vol: 0.15)],
  'break': [_noise(dur: 0.15, vol: 0.35, filter: 'bandpass', freq: 900)],
  'levelup': [for (final (i, f) in [523.0, 659.0, 784.0, 1047.0].indexed) _tone('square', f, dur: 0.12, vol: 0.15, delay: i * 0.09)],
  'altar': [for (final (i, f) in [392.0, 494.0, 587.0].indexed) _tone('triangle', f, dur: 0.6, vol: 0.15, delay: i * 0.05)],
  'pickup': [for (final (i, f) in [660.0, 880.0, 1320.0].indexed) _tone('triangle', f, dur: 0.15, vol: 0.2, delay: i * 0.07)],
  'roar': [_noise(dur: 0.9, vol: 0.5, filter: 'lowpass', freq: 500), _tone('sawtooth', 110, f1: 55, dur: 0.9, vol: 0.25)],
  'thud': [_tone('sine', 120, f1: 40, dur: 0.25, vol: 0.4)],
  'victory': [
    for (final (i, f) in [392.0, 523.0, 659.0, 784.0, 659.0, 784.0, 1047.0].indexed)
      _tone('triangle', f, dur: 0.22, vol: 0.18, delay: i * 0.13),
  ],
};

double _osc(String type, double phase) {
  final p = phase - phase.floorToDouble();
  switch (type) {
    case 'square':
      return p < 0.5 ? 1 : -1;
    case 'sawtooth':
      return 2 * p - 1;
    case 'triangle':
      return 1 - 4 * (p - 0.5).abs();
    default:
      return math.sin(p * 2 * math.pi);
  }
}

// RBJ biquad, like WebAudio's BiquadFilterNode
class _Biquad {
  _Biquad(String type, double freq) {
    final w = 2 * math.pi * freq / _rate;
    final cw = math.cos(w), sw = math.sin(w);
    final q = type == 'bandpass' ? 1.0 : 0.7071;
    final alpha = sw / (2 * q);
    double b0x, b1x, b2x;
    switch (type) {
      case 'lowpass':
        b0x = (1 - cw) / 2;
        b1x = 1 - cw;
        b2x = (1 - cw) / 2;
      case 'highpass':
        b0x = (1 + cw) / 2;
        b1x = -(1 + cw);
        b2x = (1 + cw) / 2;
      default:
        b0x = alpha;
        b1x = 0;
        b2x = -alpha;
    }
    final a0 = 1 + alpha;
    b0 = b0x / a0;
    b1 = b1x / a0;
    b2 = b2x / a0;
    a1 = -2 * cw / a0;
    a2 = (1 - alpha) / a0;
  }

  late final double b0, b1, b2, a1, a2;
  double _x1 = 0, _x2 = 0, _y1 = 0, _y2 = 0;

  double process(double x) {
    final y = b0 * x + b1 * _x1 + b2 * _x2 - a1 * _y1 - a2 * _y2;
    _x2 = _x1;
    _x1 = x;
    _y2 = _y1;
    _y1 = y;
    return y;
  }
}

Uint8List _render(List<_Voice> voices) {
  final len = voices.map((v) => v.delay + v.dur).reduce(math.max) + 0.03;
  final n = (len * _rate).ceil();
  final mix = Float64List(n);
  final rnd = math.Random(1);
  for (final v in voices) {
    final start = (v.delay * _rate).floor();
    final count = (v.dur * _rate).floor();
    final filter = v.type == 'noise' ? _Biquad(v.filter!, v.freq) : null;
    var phase = 0.0;
    for (var i = 0; i < count && start + i < n; i++) {
      final t = i / count;
      // exponential ramps, like exponentialRampToValueAtTime
      final gain = v.vol * math.pow(0.001 / v.vol, t);
      double s;
      if (filter != null) {
        s = filter.process(rnd.nextDouble() * 2 - 1);
      } else {
        final f = v.f0 * math.pow(math.max(1, v.f1) / v.f0, t);
        phase += f / _rate;
        s = _osc(v.type, phase);
      }
      mix[start + i] += s * gain;
    }
  }

  // 16-bit mono PCM WAV
  final bytes = ByteData(44 + n * 2);
  void str(int o, String s) {
    for (var i = 0; i < s.length; i++) {
      bytes.setUint8(o + i, s.codeUnitAt(i));
    }
  }

  str(0, 'RIFF');
  bytes.setUint32(4, 36 + n * 2, Endian.little);
  str(8, 'WAVE');
  str(12, 'fmt ');
  bytes.setUint32(16, 16, Endian.little);
  bytes.setUint16(20, 1, Endian.little);
  bytes.setUint16(22, 1, Endian.little);
  bytes.setUint32(24, _rate, Endian.little);
  bytes.setUint32(28, _rate * 2, Endian.little);
  bytes.setUint16(32, 2, Endian.little);
  bytes.setUint16(34, 16, Endian.little);
  str(36, 'data');
  bytes.setUint32(40, n * 2, Endian.little);
  for (var i = 0; i < n; i++) {
    final s = (mix[i] * _master).clamp(-1.0, 1.0);
    bytes.setInt16(44 + i * 2, (s * 32767).round(), Endian.little);
  }
  return bytes.buffer.asUint8List();
}

class Sfx {
  final Map<String, List<AudioPlayer>> _pools = {};
  final Map<String, Source> _sources = {};
  final Map<String, int> _next = {};
  bool _ready = false;

  Future<void> init() async {
    try {
      final dir = await getTemporaryDirectory();
      final lowLatency = Platform.isAndroid;
      for (final e in _effects.entries) {
        final file = File('${dir.path}/meetra_${e.key}.wav');
        await file.writeAsBytes(_render(e.value), flush: true);
        _sources[e.key] = DeviceFileSource(file.path);
        final pool = <AudioPlayer>[];
        for (var i = 0; i < (e.key == 'coin' || e.key == 'hit' ? 4 : 2); i++) {
          final p = AudioPlayer();
          if (lowLatency) await p.setPlayerMode(PlayerMode.lowLatency);
          await p.setReleaseMode(ReleaseMode.stop);
          pool.add(p);
        }
        _pools[e.key] = pool;
      }
      _ready = true;
    } catch (_) {
      // Sound is optional: the game plays fine without it
    }
  }

  void _play(String name) {
    if (!_ready) return;
    final pool = _pools[name]!;
    final i = _next[name] = ((_next[name] ?? -1) + 1) % pool.length;
    pool[i].play(_sources[name]!).catchError((_) {});
  }

  void jump() => _play('jump');
  void swing() => _play('swing');
  void hit() => _play('hit');
  void coin() => _play('coin');
  void hurt() => _play('hurt');
  void feather() => _play('feather');
  void fizzle() => _play('fizzle');
  void breakIt() => _play('break');
  void levelup() => _play('levelup');
  void altar() => _play('altar');
  void pickup() => _play('pickup');
  void roar() => _play('roar');
  void thud() => _play('thud');
  void victory() => _play('victory');
}

final sfx = Sfx();
