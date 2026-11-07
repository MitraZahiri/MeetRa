import 'dart:async';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art/sprites.dart';
import 'config.dart';
import 'game/meetra_game.dart';
import 'input.dart';
import 'music.dart';
import 'sfx.dart';
import 'ui/common.dart';
import 'ui/hud.dart';
import 'ui/maps.dart';
import 'ui/menus.dart';
import 'ui/touch_controls.dart';
import 'world/world.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Landscape only, fullscreen
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final art = await Art.generate();
  sfx.init();
  music.init();
  final game = MeetRaGame(art);
  await game.progress.load(game.state);
  game.ui.realm.value = game.progress.realm;
  _devShot(game);
  runApp(MeetRaApp(game: game));
}

// Dev aid for screenshots: `flutter run --dart-define=SHOT=2:5` skips the title and
// drops Ra into realm 2, place 5, where he walks right, jumping and swinging on his own.
// `SHOT=world` and `SHOT=realm:3` open the maps. Several scenes separated by commas
// play one after another, 15 seconds each. The touch buttons are hidden meanwhile.
const _shot = String.fromEnvironment('SHOT');

void _devShot(MeetRaGame game) {
  if (_shot.isEmpty) return;
  game.begin();
  game.ui.title.value = false;
  // A saga half travelled, so the maps have roads to show
  for (final r in realms.take(3)) {
    r.locations.take(r.index == 2 ? 9 : 20).forEach(game.progress.clear);
  }
  final scenes = _shot.split(',');
  for (var i = 0; i < scenes.length; i++) {
    Future.delayed(Duration(seconds: 15 * i), () => _showScene(game, scenes[i]));
  }
  var tick = 0;
  Timer.periodic(const Duration(milliseconds: 150), (_) {
    if (game.ui.screen.value != AppScreen.playing) return;
    tick++;
    touch
      ..right = true
      ..jump = tick % 9 < 3
      ..attack = tick % 4 == 0;
  });
}

void _showScene(MeetRaGame game, String scene) {
  final parts = scene.split(':');
  if (parts[0] == 'world') {
    game.openWorld();
    return;
  }
  if (parts[0] == 'realm') {
    game.openRealm(realms[int.parse(parts[1])]);
    return;
  }
  final realm = realms[int.parse(parts[0])];
  game.state.hasFeather = true;
  game.enterLocation(realm.locations[int.parse(parts[1])]);
}

class MeetRaApp extends StatelessWidget {
  const MeetRaApp({super.key, required this.game});
  final MeetRaGame game;

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'MeetRa',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(scaffoldBackgroundColor: const Color(0xff0d1233)),
        home: Scaffold(body: GameScreen(game: game)),
      );
}

// The game canvas with the UI on top. The UI is laid out on a virtual screen that is
// always 540 high (width follows the aspect ratio) and scaled to fit, like Phaser's EXPAND mode.
class GameScreen extends StatelessWidget {
  const GameScreen({super.key, required this.game});
  final MeetRaGame game;

  @override
  Widget build(BuildContext context) => Stack(children: [
        Positioned.fill(child: GameWidget(game: game, autofocus: true)),
        // The world fills the whole screen, under the camera cutout too; the UI stays clear of it
        Positioned.fill(
          child: SafeArea(top: false, bottom: false, child: LayoutBuilder(builder: (context, box) {
            final w = box.maxWidth * gameH / box.maxHeight;
            return FittedBox(
              fit: BoxFit.fill,
              alignment: Alignment.topLeft,
              child: SizedBox(
                width: w,
                height: gameH,
                child: ValueListenableBuilder(
                  valueListenable: game.ui.session,
                  builder: (context, session, _) => Stack(key: ValueKey(session), children: [
                    _when(game.ui.screen, (s) => s == AppScreen.playing, (_) => IgnorePointer(child: Hud(game, w: w))),
                    Positioned.fill(child: IgnorePointer(child: SignBox(game, w: w))),
                    Positioned.fill(child: IgnorePointer(child: BannerView(game, w: w))),
                    Positioned.fill(child: IgnorePointer(child: BossBar(game, w: w))),
                    if (_shot.isEmpty) Positioned.fill(child: TouchControls(game, w: w, h: gameH)),
                    _when(game.ui.screen, (s) => s == AppScreen.playing, (_) => MapButton(game, w: w)),
                    _when(game.ui.screen, (s) => s == AppScreen.playing,
                        (_) => Stack(children: [At(w / 2 + 72, 30, child: const SoundButton(size: 34))])),
                    _when(game.ui.levelUps, (n) => n > 0, (n) => LevelUpPanel(game, w: w)),
                    _when(game.ui.victory, (v) => v, (_) => VictoryScreen(game, w: w)),
                    _when(game.ui.screen, (s) => s == AppScreen.world, (_) => WorldMapScreen(game, w: w)),
                    _when(game.ui.screen, (s) => s == AppScreen.realm, (_) => ValueListenableBuilder(
                          valueListenable: game.ui.realm,
                          builder: (context, r, _) => RealmMapScreen(game, key: ValueKey(r), w: w),
                        )),
                    _when(game.ui.title, (v) => v, (_) => TitleScreen(game, w: w)),
                  ]),
                ),
              ),
            );
          })),
        ),
      ]);

  Widget _when<T>(ValueNotifier<T> n, bool Function(T) show, Widget Function(T) build) => Positioned.fill(
        child: ValueListenableBuilder<T>(
          valueListenable: n,
          builder: (context, v, _) => show(v) ? build(v) : const SizedBox.shrink(),
        ),
      );
}
