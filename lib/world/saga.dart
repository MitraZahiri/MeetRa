// The story of MeetRa, told on parchment scrolls: a prologue, then one chapter for every realm.
// A chapter opens when Ra first reaches the realm, its guardian speaks before the fight and the
// chapter closes when the guardian falls. People in towns and by hearths have their own words,
// and every realm hides a legend in seven verses, carved on Verse Stones along its trails.
//
// The epic poems of old Persia are only a breeze here: themes and motifs, never their plot,
// characters or names.

import 'world.dart';

class StoryPage {
  const StoryPage(this.speaker, this.text);
  final String speaker; // empty for the narrator
  final String text;
}

class Chapter {
  const Chapter({
    required this.title,
    required this.intro,
    required this.bossWords,
    required this.after,
    required this.townTalk,
    required this.hearthTalk,
    required this.rumours,
    required this.legend,
    required this.verses,
  });

  final String title;
  final List<StoryPage> intro; // when Ra first reaches the realm
  final String bossWords; // the guardian, just before the fight
  final List<StoryPage> after; // when the guardian falls
  final List<StoryPage> townTalk; // one page for each visit to the town, in turn
  final List<StoryPage> hearthTalk; // one page for each of the three hearths on the road
  final List<String> rumours; // what the signposts along the trails say
  final String legend; // the name of the legend told by the seven verses
  final List<String> verses; // seven, one on each Verse Stone
}

const narrator = '';

const prologue = [
  StoryPage(narrator,
      'Long ago, before kings had names, fire came down into the world as a gift. The people of Hearthvale kept the last of it on their hill: the Dawnfire, a flame that never went out.'),
  StoryPage(narrator,
      'For a thousand winters the flame held the dark beyond the hills. Then, on the longest night, the Pale Giant came down from the northern ice. He swallowed the Dawnfire whole, and breathed frost into the eyes of the king and all his guard.'),
  StoryPage('Old Mehr',
      'The king in Crownhold is blind, Ra, and the dark is creeping back. There are two roads to the Giant. The long road is safe and takes a lifetime. The other is the Road of Seven Trials. It is short. No one has come back from it.'),
  StoryPage('Old Mehr',
      'Your family kept the Dawnblade before you, and you are all that is left of them. I cannot stop you, so take my advice instead: rest at every hearth, read every stone the old poets carved, and never trust a shadow that wears your face.'),
  StoryPage(narrator, 'Ra did not wait for morning. Ra took the short road.'),
];

// The seven trail places of every realm that hold a Verse Stone, in the order of the verses
const verseStops = [2, 4, 5, 8, 9, 10, 12];

// Which verse waits in this place (0..6), or null
int? verseIndex(Location l) {
  if (l.kind != LocKind.trail) return null;
  final i = verseStops.indexOf(l.index);
  return i < 0 ? null : i;
}

const numerals = ['I', 'II', 'III', 'IV', 'V', 'VI', 'VII'];

Chapter chapterOf(Realm r) => chapters[r.id]!;

const chapters = <String, Chapter>{
  'hearthvale': Chapter(
    title: 'Chapter One: The Vale Gone Cold',
    intro: [
      StoryPage('Old Mehr',
          'Before you face any giant, face the vale. Since the fire went out the beasts have gone strange. Even the old white elephant who carried our harvests has gone mad with frost in its blood.'),
      StoryPage('Old Mehr',
          'Clear the roads, light the hearths and find your way to the Ivory Ruin. If the elephant can be stopped, the vale will believe in you. And a vale that believes is half a victory.'),
    ],
    bossWords: "The frost speaks through the great beast: 'Small one. Go home to your cold hearth. The Giant has your fire, and I have your road.'",
    after: [
      StoryPage(narrator,
          'The great beast fell to its knees, and the frost ran out of its eyes like tears. For a moment it knew Ra. It lowered its trunk, and then it slept.'),
      StoryPage('Old Mehr',
          'Hearthvale is free. Take the King\'s Road to Crownhold. If anyone there still remembers the old ways, it will be Bram the Smith.'),
    ],
    townTalk: [
      StoryPage('Old Mehr', 'The reeds remember every step. Walk softly in the marsh, and listen for the lion before it listens for you.'),
      StoryPage('A village child', 'Mehr says the poets carved their songs on stones along the trails. Will you read them to me when you come back?'),
      StoryPage('Old Mehr', 'A hearth is only a fire someone decided to keep. Every one you light is a promise that the dark ends somewhere.'),
    ],
    hearthTalk: [
      StoryPage('A ferryman', 'The river has been running cold since that night. Fish swim slow, and the willows whisper about horned things in the hills.'),
      StoryPage('A fruit picker', 'Take a pomegranate for the road. My grandmother said each seed is a little sun. Eat one when the night is long.'),
      StoryPage('A tower guard', 'From the top of the tower you can see the elephant\'s trail, trees snapped like reeds. Whatever it was, it is not the beast we loved.'),
    ],
    rumours: [
      'Travellers say the horned demons came out of the hills the very night the Dawnfire went dark.',
      'Old Mehr says a stone song lies on this trail. Look high and low, in the rooms off the road.',
      'Wild horses still run in the meadow. One of them, they say, is as red as an ember.',
      'Shepherds have heard trumpeting at night from the north. The white elephant is restless.',
    ],
    legend: 'The Song of the First Spark',
    verses: [
      'In the first days a hunter walked the hills, with only a stone in his hand and the night at his heels.',
      'A serpent of smoke rose up across his way. He threw the stone, and missed, and struck the grey.',
      'Stone met stone, and out of the meeting sprang a light. The serpent fled, and so did the night.',
      'He knelt and fed the little flame with reeds, and taught his people everything a fire needs.',
      "'Keep it,' he said, 'and keep it well and high. A flame that no one watches is a flame that will die.'",
      'So the first hearth was built upon the hill, and every hearth since is that same fire still.',
      'And if the fire is ever taken from the vale, strike stone on stone again, and do not fail.',
    ],
  ),
  'crownhold': Chapter(
    title: 'Chapter Two: The First Darkness',
    intro: [
      StoryPage('Bram the Smith',
          'You came the short road? Then you are either brave or foolish, and Crownhold needs both. King Aurel sits blind on his throne, and since the fire died something has woken in the vaults below the palace.'),
      StoryPage('Bram the Smith',
          'The old folk call it the Black Hollow: the first darkness, older than any king. It feeds on every lamp that goes out. Clear the city, and I will forge you a banner to march under.'),
    ],
    bossWords: "A voice like cold water: 'I was here before your fire, and I will be here after it. Every flame goes out, little hearth-keeper. Every one.'",
    after: [
      StoryPage(narrator,
          'Light poured into the Shadow Vault, and the Black Hollow folded into itself like smoke into a bottle. Above it, the lamps of Crownhold flickered back to life one by one.'),
      StoryPage('King Aurel',
          'I cannot see you, but I can hear my city breathing again. The Giant\'s road runs south through the Serpent Sands. Vexar rules there now, and he bows to the Giant. Go carefully. And thank you.'),
    ],
    townTalk: [
      StoryPage('Bram the Smith', 'My father raised a banner in this square once, against a crueller king than Aurel. It was only a leather apron on a spear.'),
      StoryPage('A palace maid', 'The king asks every morning whether the sun has risen. We tell him yes, even on the grey days.'),
      StoryPage('Bram the Smith', 'Iron remembers the fire that made it. So do people. That is why the Hollow fears this city.'),
    ],
    hearthTalk: [
      StoryPage('An apprentice', 'Bram keeps the forge lit day and night. He says if one fire in Crownhold stays awake, the city can\'t fall asleep forever.'),
      StoryPage('A royal guard', 'I was at the king\'s side when the frost came. I can see a little again now. Shapes. Light. It is enough to stand guard.'),
      StoryPage('A temple keeper', 'This fire has not gone out in three hundred years. Even on that night it only bowed low, like a reed in the wind.'),
    ],
    rumours: [
      'The Hollows came up through the old sewers. Nobody goes below the city any more.',
      'They say the leather banner still hangs in Banner Square, and that it moves when there is no wind.',
      'The Great Cypress was planted by a prophet who carried fire in his bare hands.',
      'A stone song is carved somewhere on this street. The poets loved Crownhold once.',
    ],
    legend: 'The Banner of the Smith',
    verses: [
      'When a cruel king took the children of the town, a smith set his heavy hammer down.',
      "He tied his leather apron to a spear and lifted it, and called: 'The tyrant's end is near!'",
      'A banner made of leather, scorched and plain, and yet the people followed it like rain.',
      'Street by street they came with tongs and pails and ploughs, and doors that had been bolted opened now.',
      'The cruel king fled his palace in the night. The leather banner hung there in the light.',
      'Later kings sewed jewels along its hem, but it was a smith\'s apron first, and it outlasted them.',
      'So when a crown forgets the hands that made it, remember the apron, and the town that raised it.',
    ],
  ),
  'sands': Chapter(
    title: 'Chapter Three: The Hungry King',
    intro: [
      StoryPage('Tamra the Well-Keeper',
          'Water, stranger? Drink. It is the last sweet water for a hundred dunes. The wells beyond have gone bitter since Vexar took the sands. Two serpents grow from his shoulders, and they are always hungry.'),
      StoryPage('Tamra the Well-Keeper',
          'He serves the Pale Giant, and the Giant\'s road passes his palace. The ghouls sleep under the sand by day, so never stand still too long. And keep your waterskin full.'),
    ],
    bossWords: "Vexar laughs, and both serpents laugh with him: 'The Giant promised me the whole world once the fire was gone. Do you know how hungry my friends are, little light?'",
    after: [
      StoryPage(narrator,
          'With their king fallen, the twin serpents turned on each other and vanished in a cloud of sand. That night it rained over the dunes for the first time in seven years.'),
      StoryPage('Tamra the Well-Keeper',
          'The wells are sweet again. North of the sands the Sky Spine climbs into the clouds. That is where the Giant sleeps on your fire. Saena\'s mountain is up there too. May the great bird watch over you.'),
    ],
    townTalk: [
      StoryPage('Tamra the Well-Keeper', 'A well is a door into the earth. Most of them lead to water. Some lead to older things.'),
      StoryPage('A caravan driver', 'My camels would not cross the ridge last night. Camels know where the ghouls sleep better than any map.'),
      StoryPage('Tamra the Well-Keeper', 'The desert tribes say their grandmothers were saved from the serpent king by two kind cooks. They still set a bowl aside for them at every feast.'),
    ],
    hearthTalk: [
      StoryPage('A salt trader', 'Burn dry thornwood, not palm. Palm smokes, and smoke tells the scorpions where you sleep.'),
      StoryPage('A desert rider', 'I followed a white ram for two days once. It led me to a spring that is on no map. I still don\'t know who sent it.'),
      StoryPage('A runaway servant', 'I worked in Vexar\'s kitchens. The serpents never sleep, but they never look down. Remember that.'),
    ],
    rumours: [
      'Three caravans went missing on this road. Only the camels came back.',
      'The dunes move at night. Yesterday\'s path is not today\'s.',
      'A poet once lived in these sands and carved a song about two cooks. The stone is still here, somewhere.',
      'The ghouls cannot abide the sound of running water. A pity there is so little of it.',
    ],
    legend: 'The Cooks Who Saved Half',
    verses: [
      'Two cooks were made to feed the serpent king, and what his serpents hungered for was a terrible thing.',
      'Each day two prisoners were led to the kitchen fire. The cooks wept, and the serpents\' hunger rose higher.',
      "Then one cook whispered: 'We cannot save them both. But one we can.' And they swore it as an oath.",
      'So every day they set one prisoner free, and fed the serpents mutton secretly.',
      'The freed ones fled into the open sand, and pitched their tents in a forgotten land.',
      'Years passed, and the freed became a people of their own, who knew the dunes the way the serpents knew stone.',
      'When the serpent king fell at last, they came riding with the dawn. The half that was saved had become a nation.',
    ],
  ),
  'skyspine': Chapter(
    title: 'Chapter Four: The Thief in the Ice',
    intro: [
      StoryPage('Hask the Woodcutter',
          'Up here the snow never melts any more. The Giant lies in the Frozen Cave with the Dawnfire in his belly, and he is warm and we are cold. That is the way of giants.'),
      StoryPage('Saena',
          "A great green shadow passes over the peaks, and a voice like wind in feathers says: 'Child of the hearth. I raised a lost child in my nest once, and I know the look of one. Climb. When you call, I will hear you.'"),
    ],
    bossWords: "The ice itself speaks: 'The fire was too bright for you small things. I keep it safe now, deep in the cold. Turn back, or I will keep you too.'",
    after: [
      StoryPage(narrator,
          'The Pale Giant broke like a frozen lake in spring, and out of the cracks the Dawnfire rose, burning gold. Ra carried it down the mountain, and the snow melted on the path behind.'),
      StoryPage('Saena',
          'The fire is home, and the guards\' eyes are clearing. But the king\'s frost went deepest of all. Only the Water of Life can wash it away, and it lies in the Lightless Land, past the edge of the world. Find the six Dawn Sigils, and the way will open.'),
      StoryPage(narrator, 'Far to the west, beyond the Ashen River, the Dusk Khan had watched the vale grow weak. Now he saw his chance.'),
    ],
    townTalk: [
      StoryPage('Hask the Woodcutter', 'You can tell the Giant\'s mood by the wind. A north wind means he is turning over in his sleep.'),
      StoryPage('A goat herder', 'The eagles have been circling Saena\'s peak for days. Something big is coming, or something big is leaving.'),
      StoryPage('Hask the Woodcutter', 'There is an old road song about the first hero to walk the Seven Trials. Nobody remembers his name. Only the stones do.'),
    ],
    hearthTalk: [
      StoryPage('A mountain guide', 'Up here a hearth is not comfort. It is the line between tomorrow and no tomorrow. Rest while you can.'),
      StoryPage('A frozen soldier', 'The king sent fifty of us after the Giant. The frost took us one by one. I am the only one who found this fire.'),
      StoryPage('Saena', 'The cave is close now. Whatever the Giant says to you, remember: cold things always say the fire is too bright.'),
    ],
    rumours: [
      'Avalanches on this pass come without warning. So do the man-eaters.',
      'The ice here is older than the kingdom. Some say the Giant was frozen into it once, and someone let him out.',
      'A song about the Seven Trials is carved on a stone up here. Snow hides it most of the year.',
      'If you hear wings above the clouds, do not be afraid. Saena hunts only what hunts you.',
    ],
    legend: 'The First Hero of the Short Road',
    verses: [
      'Long before Ra, a hero walked the short road, and his horse walked with him, red as an ember.',
      'At the first trial a lion came by night. The horse fought it alone while the hero slept, and won.',
      'At the second, the desert drank their water. A white ram led them to a spring no map had marked.',
      'At the third, a serpent hid in the dark. The horse woke him three times, until at last he believed it.',
      'At the fourth, a witch laid a feast and wore a lovely face. He spoke a true name, and the face fell away.',
      'At the fifth and the sixth he bound a warden and broke a warlord\'s horns, and the road ran on into the ice.',
      'At the seventh he met a giant in the cold, and won. No one remembers his name. Only the road remembers.',
    ],
  ),
  'duskland': Chapter(
    title: 'Chapter Five: The Khan Beyond the River',
    intro: [
      StoryPage('Orsa the Herder',
          'The Dusk Khan\'s riders crossed the Ashen River the night your fire went out. They burn the grass and drive off the herds. Varak wants the vale while it is weak.'),
      StoryPage('Orsa the Herder',
          'He is cunning. When he loses a fight he hides in his lake, under the water, and waits. But a khan who hides cannot hold the steppe forever. Break his forts, and he will have to come out.'),
    ],
    bossWords: "Varak draws a curved blade: 'Your fire, your king, your little vale. I will take them all, as my fathers tried before me. Come, hearth-child. The steppe is only wide enough for one of us.'",
    after: [
      StoryPage(narrator,
          'Varak fell back into the dark water of his lake and was not seen again. His riders scattered across the grass, and the herds came home on their own.'),
      StoryPage('Orsa the Herder',
          'West of here the land ends in white cliffs and the sea. They say the Cliff Dragon guards the road to the edge of the world. If you are going to the Lightless Land, that is your road.'),
    ],
    townTalk: [
      StoryPage('Orsa the Herder', 'On the steppe you can see a rider coming for half a day. That is why the khan\'s men ride at night.'),
      StoryPage('A young archer', 'They say twelve champions fought here once, one on one. My grandfather says only eleven fought. He won\'t say why.'),
      StoryPage('Orsa the Herder', 'Grass grows back. Herds come back. People come back too, if someone gives them a reason.'),
    ],
    hearthTalk: [
      StoryPage('A nomad woman', 'We move our tents with the seasons, but this fire we carry with us in a clay pot. It is older than my grandmother.'),
      StoryPage('A captured scout', 'I rode for the khan. I am tired of riding for the khan. Tell your king that, if he ever asks about us.'),
      StoryPage('A fisherman', 'Nobody fishes the Lake of Hiding. Something big lives down there, and it breathes.'),
    ],
    rumours: [
      'The khan\'s riders mark their trails with broken arrows. Follow them backwards and you find a camp.',
      'This road was lined with silver birches once. The riders burned them for their fires.',
      'A song of the twelve duels is carved on a stone nearby. The herders leave milk beside it.',
      'Under the Bright Fort there are cellars no one has opened since the old war.',
    ],
    legend: 'The Eleven Duels',
    verses: [
      'When two armies met beside the Ashen River, both were tired of war, and they agreed to a strange thing.',
      'Instead of thousands, only twelve would fight: twelve champions from each side, one against one, on the open field.',
      'The first pair fought from dawn until their shadows met. Then the second pair, and then the third.',
      'The steppe held its breath. Herders climbed the hills to watch. Even the hawks circled lower.',
      'By evening eleven duels were done, and the last two champions stepped out. They were brothers, parted as children.',
      'They saw each other\'s faces, threw their swords down in the grass, and embraced in the middle of the field.',
      'The armies went home. It is still called the Field of the Twelve Duels, though only eleven were ever fought.',
    ],
  ),
  'marble': Chapter(
    title: 'Chapter Six: The Edge of the Map',
    intro: [
      StoryPage('Captain Lysa',
          'Welcome to the Marble Harbor! Or what is left of it. No ship has sailed west in a year. The Cliff Dragon sits on the sea road and sinks anything with a sail.'),
      StoryPage('Captain Lysa',
          'The Dawn Sigils, you say? Old sailors put one in every land you have crossed. If you are after the edge of the world, beat the dragon first. Then I will sail you anywhere.'),
    ],
    bossWords: "The dragon uncoils from the cliff, and its voice is the crash of waves: 'The world ends past my rocks, little light. I am the last thing it ever shows anyone.'",
    after: [
      StoryPage(narrator, 'The Cliff Dragon tumbled into the sea, and the waves carried it far out until it was only another rock in the water.'),
      StoryPage('Captain Lysa',
          'The sea road is open! When you have gathered all six Dawn Sigils, the way to the Lightless Land will show itself. I will be waiting at the harbor.'),
    ],
    townTalk: [
      StoryPage('Captain Lysa', 'A sailor\'s rule: never trust a calm sea or a king who wants more than the whole earth.'),
      StoryPage('An old sculptor', 'Every statue in this harbor is of someone who tried to fly. We find it funny. They did not.'),
      StoryPage('Captain Lysa', 'The talking tree in the Lightless Land? My grandfather swore it told him the day he would die. He was wrong by a week.'),
    ],
    hearthTalk: [
      StoryPage('A lighthouse keeper', 'The lamp has burned every night since the dragon came. It doesn\'t keep the ships safe. It keeps us brave.'),
      StoryPage('A vineyard girl', 'Grapes grow sweetest close to the sea. Mother says it is because they are afraid of it.'),
      StoryPage('A bridge guard', 'Two rivers meet under this bridge and never mix. One is cold, one is warm. Like most marriages.'),
    ],
    rumours: [
      'The dragon\'s cliffs are full of wreckage. Some of it still has treasure aboard.',
      'Once a king tied eagles to his throne and flew over this coast. The sculptors still laugh about it.',
      'A stone song lies along this road. It is about the flying king, and it is not kind to him.',
      'The wolves of the great forest walk on two legs when the moon is thin. Or so the shepherds say.',
    ],
    legend: 'The King Who Tried to Fly',
    verses: [
      'There was once a king who owned the whole earth, and found that it was not enough.',
      'He wanted the sky as well. So he raised four young eagles on meat, and tied them to the legs of his throne.',
      'Above each eagle he hung meat on a spear, just out of reach. The eagles flew up to reach it, and the throne flew with them.',
      'Up he went, over the cities and over the clouds, and he laughed and called down that he was the king of the sky.',
      'But eagles tire, and meat on a spear never comes any closer. One by one the birds grew weak.',
      'The throne fell into a forest far from any road, and the king of the sky sat in the mud, alone and ashamed.',
      "His champions found him there and carried him home. 'Next time,' they told him, 'ask the birds first.'",
    ],
  ),
  'lightless': Chapter(
    title: 'Chapter Seven: The Water of Life',
    intro: [
      StoryPage('The Lantern Keeper',
          'No one has come this far in a hundred years. Here, take a light, though it will not go far. The Lightless Land swallows lamps the way the sea swallows stones.'),
      StoryPage('Saena',
          'The Water of Life lies at the heart of the night. But it is guarded by the one enemy you cannot outrun, Ra. It knows every move you know. It wears your face.'),
    ],
    bossWords: "Your own voice answers you from the dark: 'Why should you be the hero? I am faster than you, and I never get tired. Give me the fire, and go home.'",
    after: [
      StoryPage(narrator,
          'Ra did not strike the last blow. Ra lowered the sword, and the shadow, finding nothing left to fight, stepped back into Ra like a shadow at noon.'),
      StoryPage(narrator,
          'Ra carried the Water of Life home in cupped hands. When it touched King Aurel\'s eyes the frost melted, and for the first time he saw the face of the child who had walked the short road.'),
      StoryPage('Old Mehr',
          'So. The fire is back on the hill, the king can see, and the road has a new story. Sit down by the hearth, Ra, and tell me everything. Start at the beginning.'),
    ],
    townTalk: [
      StoryPage('The Lantern Keeper', 'Out there, sound is the only light. Listen for water, and you will know the way.'),
      StoryPage('The Lantern Keeper', 'Some travellers come here looking for the Water of Life. Most of them only find stones.'),
      StoryPage('Saena', 'I cannot fly where there is no sky. From here on, you walk alone. But you were never really alone. The fire went with you.'),
    ],
    hearthTalk: [
      StoryPage('A glowstone miner', 'The stones here glow because they remember the sun. Hold one, and you can almost feel it.'),
      StoryPage('A lost traveller', 'I came looking for the spring forty years ago. I found this fire instead. It turned out to be enough.'),
      StoryPage('A voice in the dark', 'Who is there? No, don\'t tell me. Names are heavy here. Just sit, and get warm, and go on.'),
    ],
    rumours: [
      'The stones in this land whisper. Whoever takes them will regret it, they say, and whoever leaves them will regret it too.',
      'A man dressed all in green is said to walk this land and guide the lost. No one has seen his face.',
      'The last of the stone songs is carved here, in the dark. It tells of a king, a guide and a spring.',
      'Do not follow the lights that move. The lights that stay still are hearths.',
    ],
    legend: 'The Spring at the End of the World',
    verses: [
      'A king once heard of a spring at the end of the world whose water gave endless life.',
      'He took a guide, a quiet man who knew the dark, and they rode into the land where the sun never comes.',
      'In the dark the road split in two. The guide went left. The king went right.',
      'The guide found the spring. He drank and bathed, and his clothes turned as green as new leaves.',
      "The king wandered forty days and found only stones that whispered: 'Whoever takes us will regret it, and whoever leaves us will regret it too.'",
      'He took a few. In the daylight they turned to jewels, and he regretted that he had not taken more.',
      'The guide still walks the world in green, they say, and helps lost travellers. If you meet him, ask him the way.',
    ],
  ),
};
