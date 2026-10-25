// Which locations are cleared, plus Ra's stats, saved on the device between sessions.

import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config.dart';
import 'world.dart';

class Progress extends ChangeNotifier {
  static const _key = 'meetra.save.v1';

  final _cleared = <String>{};
  int realm = 0; // the realm last opened on the world map
  String? lastLocation; // where Ra's marker stands on the realm map

  bool isCleared(Location l) => _cleared.contains(l.id);

  // Returns true the first time a location is cleared
  bool clear(Location l) {
    final first = _cleared.add(l.id);
    lastLocation = l.id;
    notifyListeners();
    return first;
  }

  void moveTo(Location l) {
    lastLocation = l.id;
    realm = l.realm.index;
    notifyListeners();
  }

  Future<void> save(GameState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode({'cleared': _cleared.toList(), 'realm': realm, 'last': lastLocation, 'state': s.toJson()}));
    } catch (e) {
      debugPrint('MeetRa: could not save progress: $e');
    }
  }

  Future<void> load(GameState s) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_key);
      if (raw == null) return;
      final j = jsonDecode(raw) as Map<String, dynamic>;
      _cleared
        ..clear()
        ..addAll((j['cleared'] as List).cast<String>());
      realm = j['realm'] as int? ?? 0;
      lastLocation = j['last'] as String?;
      s.fromJson((j['state'] as Map).cast<String, dynamic>());
      notifyListeners();
    } catch (e) {
      debugPrint('MeetRa: could not load progress: $e');
    }
  }

  Future<void> wipe(GameState s) async {
    _cleared.clear();
    realm = 0;
    lastLocation = null;
    s.reset();
    notifyListeners();
    await save(s);
  }
}
