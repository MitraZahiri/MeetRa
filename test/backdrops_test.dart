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
}
