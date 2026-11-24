import 'dart:ui' as ui;

import 'package:flutter_test/flutter_test.dart';
import 'package:meetra/art/backdrops.dart';
import 'package:meetra/world/world.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('every realm and the underground paint all their backdrop layers', () {
    for (final theme in [...RealmTheme.values, null]) {
      final b = paintBackdrop(theme);
      expect(b.layers, hasLength(backdropParallax.length), reason: '$theme');
      for (final l in b.layers) {
        expect(l.width, (backdropW * backdropScale).toInt());
        expect(l.height, (backdropH * backdropScale).toInt());
      }
      b.dispose();
    }
  });

  test('the moving things of Hearthvale and the Serpent Sands draw on real layers', () {
    for (final theme in [RealmTheme.vale, RealmTheme.desert]) {
      final b = paintBackdrop(theme);
      expect(b.live, isNotEmpty, reason: '$theme');
      for (final MapEntry(key: i, value: live) in b.live.entries) {
        expect(i, inInclusiveRange(1, backdropParallax.length - 1));
        for (final t in [0.0, 0.7, 123.4]) {
          final rec = ui.PictureRecorder();
          live(ui.Canvas(rec), t);
          rec.endRecording().dispose();
        }
      }
      b.dispose();
    }
  });
}
