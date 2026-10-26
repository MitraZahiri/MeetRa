// Procedural background music, rendered once at startup in a background isolate.
//
// - Exploring: a calm santur melody in the mode of Shur (with its quarter-flat second),
//   a drone and a soft daf (frame drum) in 6/8.
// - Boss: a faster, darker theme in a Chahargah-like mode over a pounding daf ostinato.
// Plucked strings are Karplus-Strong; every note's tail wraps around so the loop is seamless.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:math' as math;

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'sfx.dart';

enum Track { explore, boss }

const _sr = 22050;

double _hz(int semis, [double quarter = 0]) => 293.66 * math.pow(2, (semis + quarter) / 12); // from D4

class _Mix {
  _Mix(double seconds) : out = Float64List((seconds * _sr).round());
  final Float64List out;
  int get len => out.length;

  void add(int i, double v) => out[i % len] += v;

  // Karplus-Strong string; two slightly detuned strings like a santur course
  void pluck(double t, double freq, double vol, {double dur = 1.4, double decay = 0.996, math.Random? r}) {
    final rnd = r ?? math.Random(freq.round());
    for (final (detune, v) in [(1.0, 1.0), (1.0035, 0.55)]) {
      final period = math.max(2, (_sr / (freq * detune)).round());
      final buf = Float64List(period);
      var prev = 0.0;
      for (var i = 0; i < period; i++) {
        final n = rnd.nextDouble() * 2 - 1;
        prev = prev * 0.4 + n * 0.6; // soften the attack a little
        buf[i] = prev * vol * v;
      }
      final start = (t * _sr).round();
      final n = (dur * _sr).round();
      var idx = 0;
      for (var i = 0; i < n; i++) {
        final next = (idx + 1) % period;
        final s = buf[idx];
        buf[idx] = (buf[idx] + buf[next]) * 0.5 * decay;
        final fade = i > n - 400 ? (n - i) / 400 : 1.0;
        add(start + i, s * fade);
        idx = next;
      }
    }
  }

  // Santur tremolo (riz): fast repeated strikes that swell and fade
  void tremolo(double t, double freq, double vol, double dur, math.Random r) {
    const step = 0.065;
    final count = (dur / step).floor();
    for (var i = 0; i < count; i++) {
      final env = math.sin(math.pi * (i + 0.5) / count);
      pluck(t + i * step, freq, vol * (0.35 + 0.5 * env), dur: 0.5, r: r);
    }
  }

  // Low frame-drum stroke (dum)
  void dum(double t, double vol) {
    final start = (t * _sr).round();
    final n = (0.4 * _sr).round();
    var phase = 0.0;
    for (var i = 0; i < n; i++) {
      final k = i / n;
      final f = 120 * math.pow(0.45, k * 3);
      phase += f / _sr;
      add(start + i, math.sin(phase * 2 * math.pi) * vol * math.pow(1 - k, 3));
    }
  }

  // Bright rim stroke (tak / ka)
  void tak(double t, double vol, math.Random r, {double length = 0.07}) {
    final start = (t * _sr).round();
    final n = (length * _sr).round();
    var lp = 0.0, prev = 0.0;
    for (var i = 0; i < n; i++) {
      final x = r.nextDouble() * 2 - 1;
      lp = lp * 0.55 + x * 0.45;
      final hp = lp - prev; // crude band-pass
      prev = lp;
      add(start + i, hp * vol * math.pow(1 - i / n, 4));
    }
  }

  // A soft drone on the tonic and fifth that breathes slowly
  void drone(List<double> freqs, double vol, double breath) {
    final phases = List.filled(freqs.length, 0.0);
    for (var i = 0; i < len; i++) {
      final t = i / _sr;
      final env = vol * (0.75 + 0.25 * math.sin(2 * math.pi * t / (len / _sr) * breath));
      var s = 0.0;
      for (var j = 0; j < freqs.length; j++) {
        phases[j] += freqs[j] / _sr;
        final p = phases[j] * 2 * math.pi;
        s += (math.sin(p) + 0.3 * math.sin(2 * p) + 0.12 * math.sin(3 * p)) / freqs.length;
      }
      out[i] += s * env;
    }
  }

  Uint8List toWav() {
    var peak = 1e-6;
    for (final v in out) {
      peak = math.max(peak, v.abs());
    }
    final gain = 0.85 / peak;
    final bytes = ByteData(44 + len * 2);
    void str(int o, String s) {
      for (var i = 0; i < s.length; i++) {
        bytes.setUint8(o + i, s.codeUnitAt(i));
      }
    }

    str(0, 'RIFF');
    bytes.setUint32(4, 36 + len * 2, Endian.little);
    str(8, 'WAVE');
    str(12, 'fmt ');
    bytes
      ..setUint32(16, 16, Endian.little)
      ..setUint16(20, 1, Endian.little)
      ..setUint16(22, 1, Endian.little)
      ..setUint32(24, _sr, Endian.little)
      ..setUint32(28, _sr * 2, Endian.little)
      ..setUint16(32, 2, Endian.little)
      ..setUint16(34, 16, Endian.little);
    str(36, 'data');
    bytes.setUint32(40, len * 2, Endian.little);
    for (var i = 0; i < len; i++) {
      bytes.setInt16(44 + i * 2, (out[i] * gain * 32767).round().clamp(-32768, 32767), Endian.little);
    }
    return bytes.buffer.asUint8List();
  }
}

// Rhythms for one 6/8 bar, in eighth notes
const _bars = [
  [3, 3],
  [2, 1, 3],
  [1, 1, 1, 3],
  [3, 1, 1, 1],
  [2, 2, 2],
  [1, 2, 3],
];

// A melody that wanders mostly by step and settles on the given notes at phrase ends
List<(int, int)> _melody(math.Random r, int bars, int scaleLen, List<int> cadences, {int start = 4}) {
  final notes = <(int, int)>[]; // (scale degree, length in eighths)
  var deg = start;
  for (var b = 0; b < bars; b++) {
    final rhythm = _bars[r.nextInt(_bars.length)];
    for (var i = 0; i < rhythm.length; i++) {
      final lastOfPhrase = b % 4 == 3 && i == rhythm.length - 1;
      if (lastOfPhrase) {
        deg = cadences[(b ~/ 4) % cadences.length];
      } else {
        final step = [-2, -1, -1, 0, 1, 1, 2][r.nextInt(7)];
        deg = (deg + step).clamp(0, scaleLen - 1);
      }
      notes.add((deg, rhythm[i]));
    }
  }
  return notes;
}

Uint8List _renderExplore() {
  const eighth = 0.25;
  const bars = 16;
  final m = _Mix(bars * 6 * eighth);
  final r = math.Random(7);
  // Shur on D: D, E (quarter flat), F, G, A, Bb, C, D, E(qf), F
  final scale = [_hz(0), _hz(2, -0.5), _hz(3), _hz(5), _hz(7), _hz(8), _hz(10), _hz(12), _hz(14, -0.5), _hz(15)];
  m.drone([_hz(-24), _hz(-17), _hz(-12)], 0.05, 2);

  var t = 0.0;
  for (final (deg, len) in _melody(r, bars, scale.length, [2, 0, 4, 0])) {
    final d = len * eighth;
    if (len >= 3 && r.nextDouble() < 0.55) {
      m.tremolo(t, scale[deg], 0.28, d, r);
    } else {
      m.pluck(t, scale[deg], 0.42, dur: math.max(0.9, d + 0.6), r: r);
      // Grace note from below now and then
      if (len >= 2 && deg > 0 && r.nextDouble() < 0.25) m.pluck(t - 0.06, scale[deg - 1], 0.18, dur: 0.3, r: r);
    }
    t += d;
  }
  // Bass strings on the downbeats
  const bass = [0, 0, -2, 0, 0, 3, -2, 0];
  for (var b = 0; b < bars; b++) {
    m.pluck(b * 6 * eighth, _hz(-12 + bass[b % bass.length]), 0.3, dur: 2.4, decay: 0.998, r: r);
  }
  // Soft daf: dum . tak ka . tak
  for (var b = 0; b < bars; b++) {
    final bt = b * 6 * eighth;
    m.dum(bt, 0.32);
    m.tak(bt + 2 * eighth, 0.12, r);
    m.tak(bt + 3 * eighth, 0.07, r);
    m.tak(bt + 5 * eighth, 0.11, r);
    if (b % 4 == 3) m.dum(bt + 4.5 * eighth, 0.2); // a roll into the next phrase
  }
  return m.toWav();
}

Uint8List _renderBoss() {
  const eighth = 0.16;
  const bars = 16;
  final m = _Mix(bars * 6 * eighth);
  final r = math.Random(13);
  // Chahargah-like on D: D, Eb, F#, G, A, Bb, C#, D, Eb, F#
  final scale = [_hz(0), _hz(1), _hz(4), _hz(5), _hz(7), _hz(8), _hz(11), _hz(12), _hz(13), _hz(16)];
  m.drone([_hz(-24), _hz(-23)], 0.04, 4); // a tense, beating low drone

  // Driving bass ostinato on every eighth
  const ost = [0, 0, 7, 0, 1, 0];
  for (var b = 0; b < bars; b++) {
    for (var i = 0; i < 6; i++) {
      final shift = b % 4 == 2 ? -2 : 0;
      m.pluck((b * 6 + i) * eighth, _hz(-12 + ost[i] + shift), i == 0 ? 0.42 : 0.26, dur: 0.5, decay: 0.993, r: r);
    }
  }
  var t = 0.0;
  for (final (deg, len) in _melody(r, bars, scale.length, [6, 7, 4, 7], start: 7)) {
    final d = len * eighth;
    if (len >= 3) {
      m.tremolo(t, scale[deg], 0.32, d, r);
    } else {
      m.pluck(t, scale[deg], 0.4, dur: 0.7, r: r);
    }
    t += d;
  }
  // Heavy daf: dum on 1 and 4, taks between, fills every fourth bar
  for (var b = 0; b < bars; b++) {
    final bt = b * 6 * eighth;
    m.dum(bt, 0.5);
    m.dum(bt + 3 * eighth, 0.38);
    for (final i in [1, 2, 4, 5]) {
      m.tak(bt + i * eighth, i == 2 || i == 5 ? 0.2 : 0.11, r);
    }
    if (b % 4 == 3) {
      for (var i = 0; i < 6; i++) {
        m.tak(bt + 3 * eighth + i * eighth / 2, 0.14, r, length: 0.05);
      }
    }
  }
  return m.toWav();
}

Uint8List renderTrack(Track t) => t == Track.explore ? _renderExplore() : _renderBoss();

// Top-level so the isolate closure captures nothing but the track
Future<Uint8List> _renderInBackground(Track t) => Isolate.run(() => renderTrack(t));

class Music {
  static const _prefKey = 'meetra.sound';
  static const _volume = {Track.explore: 0.5, Track.boss: 0.6};

  // One switch for music and sound effects, remembered between sessions
  final soundOn = ValueNotifier<bool>(true);
  final _players = <Track, AudioPlayer>{};
  Track? _current;
  Track? _wanted;
  Timer? _fade;
  bool _ready = false;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      soundOn.value = prefs.getBool(_prefKey) ?? true;
      sfx.enabled = soundOn.value;
      final dir = await getTemporaryDirectory();
      for (final t in Track.values) {
        final bytes = await _renderInBackground(t);
        final file = File('${dir.path}/meetra_music_${t.name}.wav');
        await file.writeAsBytes(bytes, flush: true);
        final p = AudioPlayer();
        await p.setReleaseMode(ReleaseMode.loop);
        await p.setSource(DeviceFileSource(file.path));
        await p.setVolume(0);
        _players[t] = p;
      }
      _ready = true;
      final w = _wanted;
      if (w != null) {
        _wanted = null;
        play(w);
      }
    } catch (e) {
      debugPrint('MeetRa: music unavailable: $e');
    }
  }

  // Cross-fades to [t]; does nothing if it is already playing
  void play(Track t) {
    if (!_ready) {
      _wanted = t;
      return;
    }
    if (_current == t) return;
    final from = _current;
    _current = t;
    if (!soundOn.value) return;
    _crossfade(from, t);
  }

  void _crossfade(Track? from, Track to) {
    _fade?.cancel();
    final inP = _players[to]!;
    final outP = from == null ? null : _players[from];
    inP
      ..setVolume(0)
      ..resume();
    var step = 0;
    const steps = 16;
    _fade = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      step++;
      final k = step / steps;
      inP.setVolume(_volume[to]! * k);
      outP?.setVolume(_volume[from]! * (1 - k));
      if (step >= steps) {
        timer.cancel();
        outP?.stop();
      }
    });
  }

  Future<void> toggleSound() async {
    soundOn.value = !soundOn.value;
    sfx.enabled = soundOn.value;
    if (_ready) {
      if (soundOn.value) {
        final t = _current;
        _current = null;
        if (t != null) play(t);
      } else {
        _fade?.cancel();
        for (final p in _players.values) {
          await p.stop();
        }
      }
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_prefKey, soundOn.value);
    } catch (_) {}
  }
}

final music = Music();
