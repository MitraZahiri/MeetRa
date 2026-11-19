// What the merchants sell. Every town has a shop with the full stock; a travelling merchant who
// waits by a hearth on some trails carries only draughts and tonics. Prices rise realm by realm.
// The lasting goods (heart vessel, aura tonic, whetstone) can be bought once in each realm.

import '../config.dart';
import 'progress.dart';
import 'world.dart';

enum Good { draught, vessel, tonic, whetstone }

const maxDraughts = 3; // how many healing draughts Ra's satchel holds
const draughtHeal = 6; // half hearts: three whole hearts

class Ware {
  const Ware(this.good, this.name, this.desc, this.price);
  final Good good;
  final String name;
  final String desc;
  final int price;

  bool get lasting => good != Good.draught;
}

List<Ware> waresFor(Realm r, {bool travelling = false}) {
  final t = r.index;
  return [
    Ware(Good.draught, 'Healing Draught', 'Drink it in a fight to mend three hearts. The satchel holds $maxDraughts.', 12 + t * 4),
    if (!travelling) Ware(Good.vessel, 'Heart Vessel', 'A clay vessel blessed at the hearth: one more heart, for good.', 100 + t * 50),
    Ware(Good.tonic, 'Aura Tonic', 'Bitter and gold: the aura bar grows by twenty.', 60 + t * 30),
    if (!travelling) Ware(Good.whetstone, 'Whetstone', 'A stone from the first smiths: the sword strikes one point harder.', 140 + t * 60),
  ];
}

// Why Ra cannot buy a ware right now, or null if Ra can
String? cannotBuy(Ware w, Realm r, GameState s, Progress p) {
  if (w.lasting && p.hasBought(r, w.good)) return 'Sold out in ${r.name}';
  if (w.good == Good.draught && s.draughts >= maxDraughts) return 'The satchel is full';
  if (s.gold < w.price) return 'Not enough gold';
  return null;
}

// Pays for a ware and hands it over; returns false if it could not be bought
bool buy(Ware w, Realm r, GameState s, Progress p) {
  if (cannotBuy(w, r, s, p) != null) return false;
  s.gold -= w.price;
  switch (w.good) {
    case Good.draught:
      s.draughts++;
    case Good.vessel:
      s
        ..maxHp += 2
        ..hp = s.maxHp;
    case Good.tonic:
      s
        ..auraMax += 20
        ..aura = s.auraMax.toDouble();
    case Good.whetstone:
      s.attack += 1;
  }
  if (w.lasting) p.markBought(r, w.good);
  s.flush();
  return true;
}

// Who keeps the stall in each realm's town, and how they greet Ra
const townMerchants = <String, (String, String)>{
  'hearthvale': ('Nessa the Trader', 'Fresh from the market at Willow Ford! Well, fresh-ish. What will it be?'),
  'crownhold': ('Corvin of the Market', 'The finest goods in the capital, and the only stall still open. Take your time.'),
  'sands': ('Sela the Spice Seller', 'Draughts, tonics, and a whetstone that has seen three wars. All cheaper than thirst.'),
  'skyspine': ('Brannoc the Peddler', 'I carried all of this up the mountain on my back. Please buy something heavy.'),
  'duskland': ('Ulla the Felt Trader', 'The khan takes a tax on everything I sell. Buy from me and spite him.'),
  'marble': ('Pio of the Harbor', 'Salvaged, bartered and only slightly damp. Best prices on the coast.'),
  'lightless': ('The Lantern Merchant', 'You found my stall in the dark. That alone deserves a discount. Not much of one.'),
};

const travellingMerchant = ('A travelling merchant', 'Draughts! Tonics! Cheaper than a funeral, and I take any coin.');
