import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'art/sprites.dart';
import 'config.dart';
import 'game/meetra_game.dart';
import 'sfx.dart';
import 'ui/hud.dart';
import 'ui/maps.dart';
import 'ui/menus.dart';
import 'ui/touch_controls.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Landscape only, fullscreen
  await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  final art = await Art.generate();
  sfx.init();
  final game = MeetRaGame(art);
  await game.progress.load(game.state);
  game.ui.realm.value = game.progress.realm;
  runApp(MeetRaApp(game: game));
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
        Positioned.fill(
          child: LayoutBuilder(builder: (context, box) {
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
                    Positioned.fill(child: IgnorePointer(child: Hud(game, w: w))),
                    Positioned.fill(child: IgnorePointer(child: SignBox(game, w: w))),
                    Positioned.fill(child: IgnorePointer(child: BannerView(game, w: w))),
                    Positioned.fill(child: IgnorePointer(child: BossBar(game, w: w))),
                    Positioned.fill(child: TouchControls(game, w: w, h: gameH)),
                    _when(game.ui.screen, (s) => s == AppScreen.playing, (_) => MapButton(game, w: w)),
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
          }),
        ),
      ]);

  Widget _when<T>(ValueNotifier<T> n, bool Function(T) show, Widget Function(T) build) => Positioned.fill(
        child: ValueListenableBuilder<T>(
          valueListenable: n,
          builder: (context, v, _) => show(v) ? build(v) : const SizedBox.shrink(),
        ),
      );
}
