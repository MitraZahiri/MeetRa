// A merchant's counter on parchment: the wares, their prices and Ra's purse. The game waits meanwhile.

import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../config.dart';
import '../game/meetra_game.dart';
import '../world/shop.dart';
import 'common.dart';

const _brown = Color(0xff8a4a1a);
const _faded = Color(0xff9a8a6a);

class ShopView extends StatefulWidget {
  const ShopView(this.game, this.visit, {super.key, required this.w});
  final MeetRaGame game;
  final ShopVisit visit;
  final double w;

  @override
  State<ShopView> createState() => _ShopViewState();
}

class _ShopViewState extends State<ShopView> {
  String? _said; // the merchant's last words, after a sale

  @override
  Widget build(BuildContext context) {
    final g = widget.game;
    final v = widget.visit;
    final w = widget.w;
    final wares = waresFor(v.realm, travelling: v.travelling);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: Container(
        color: const Color(0xcc0a0e28),
        child: Stack(children: [
          At(
            w / 2,
            gameH / 2,
            child: Container(
              width: math.min(800, w - 60),
              height: 430,
              decoration: BoxDecoration(
                gradient: const LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color(0xfff8eed6), Color(0xffe3cd9f)]),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(Palette.gold), width: 3),
                boxShadow: const [BoxShadow(color: Color(0xaa000000), blurRadius: 24, offset: Offset(0, 8))],
              ),
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 14),
              child: ListenableBuilder(
                listenable: g.state,
                builder: (context, _) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: _text(v.merchant, 24, const Color(Palette.lapis))),
                    _text('${g.state.gold} gold', 20, _brown),
                  ]),
                  const SizedBox(height: 4),
                  _text(_said ?? v.greeting, 16, ink, italic: true),
                  const SizedBox(height: 10),
                  Container(height: 1.5, color: const Color(Palette.gold)),
                  const SizedBox(height: 6),
                  for (final ware in wares) _row(ware),
                  const Spacer(),
                  Row(children: [
                    _text('Draughts in the satchel: ${g.state.draughts} / $maxDraughts', 14, _faded),
                    const Spacer(),
                    _button('Leave', g.closeShop),
                  ]),
                ]),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _row(Ware ware) {
    final g = widget.game;
    final why = cannotBuy(ware, widget.visit.realm, g.state, g.progress);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _text(ware.name, 19, _brown),
            _text(ware.desc, 14, ink),
          ]),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 200,
          child: Align(
            alignment: Alignment.centerRight,
            child: why == null
                ? _button('Buy  ·  ${ware.price} gold', () => setState(() => _said = g.buyWare(ware, widget.visit)))
                : Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                    _text('${ware.price} gold', 15, _faded),
                    _text(why, 13, _faded, italic: true),
                  ]),
          ),
        ),
      ]),
    );
  }

  Widget _text(String t, double size, Color color, {bool italic = false}) => Text(t,
      style: TextStyle(
          fontFamily: fontFamily, fontSize: size, color: color, height: 1.2, fontStyle: italic ? FontStyle.italic : FontStyle.normal, decoration: TextDecoration.none));

  Widget _button(String text, VoidCallback onTap) => GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(Palette.lapis),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(Palette.gold), width: 2),
          ),
          child: OutlinedText(text, size: 15, color: gold),
        ),
      );
}
