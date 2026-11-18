import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meetra/art/sprites.dart';
import 'package:meetra/game/meetra_game.dart';
import 'package:meetra/ui/book.dart';
import 'package:meetra/ui/story.dart';
import 'package:meetra/world/saga.dart';
import 'package:meetra/world/world.dart';
import 'package:shared_preferences/shared_preferences.dart';

// The saga's screens lay out on a phone-sized virtual screen without overflowing
void main() {
  late MeetRaGame game;
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
  });

  Future<void> show(WidgetTester tester, Widget child) async {
    tester.view.physicalSize = const Size(960, 540);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SizedBox(width: 960, height: 540, child: Stack(children: [Positioned.fill(child: child)])))));
    await tester.pump(const Duration(seconds: 1));
  }

  testWidgets('the longest story pages fit on the scroll', (tester) async {
    await tester.runAsync(() async => game = MeetRaGame(await Art.generate()));
    final pages = [
      ...prologue,
      for (final c in chapters.values) ...[
        ...c.intro, ...c.after, ...c.townTalk, ...c.hearthTalk, StoryPage('A guardian', c.bossWords),
        for (final v in c.verses) StoryPage('Carved on the stone', v),
        ...c.captives, ...c.shrines, c.sigil,
      ],
      const StoryPage(narrator,
          "The seven verses of Sky Spine & Frostwood are whole again: The First Hero of the Short Road. The old poets' strength flows into Ra. Blessing: +1 might. The whole legend is kept in the Book of Verses."),
    ];
    for (final p in pages) {
      await show(tester, StoryView(game, StoryScroll('Chapter Six: The Edge of the Map', [p]), key: UniqueKey(), w: 960));
      expect(tester.takeException(), isNull, reason: p.text);
    }
  });

  testWidgets('the Book of Verses fits every realm, all verses found', (tester) async {
    await tester.runAsync(() async => game = MeetRaGame(await Art.generate()));
    for (final r in realms) {
      for (final l in r.locations) {
        game.progress.findVerse(l);
        game.progress.clear(l);
      }
    }
    for (final r in realms) {
      await show(tester, BookScreen(game, key: UniqueKey(), w: 960, realm: r.index));
      expect(tester.takeException(), isNull, reason: r.id);
    }
  });
}
