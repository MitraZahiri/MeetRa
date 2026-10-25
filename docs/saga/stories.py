"""Scenario data for the MeetRa Saga Bible.

Each entry pairs a Shahnameh story (the source, summarised for reference) with the MeetRa chapter
it inspires. In-game names are always original: the source names appear only in the "source" fields.
"""

AGES = [
    {
        "id": "I",
        "title": "Book I: The Age of First Kings",
        "intro": "Myth time. The first rulers learn fire, iron and writing, and the first darkness takes the throne. "
        "These chapters work as a playable prologue: short, bright, mythic, with a new tool earned in every one.",
    },
    {
        "id": "II",
        "title": "Book II: The Age of Heroes",
        "intro": "The heart of the saga and of MeetRa. Ra, Ember the horse and Saena carry most of these chapters. "
        "The Seven Trials (chapter 15) is the game being built now; everything around it becomes the full campaign.",
    },
    {
        "id": "III",
        "title": "Book III: The Age of Crowns",
        "intro": "Legend turns into history. Ra's era is over; new heroes inherit his gear and his map. "
        "These chapters suit episodic releases and side games, each with its own twist on the core platforming.",
    },
]

# Fields: n, age, source (Shahnameh title), summary (source story), chapter (MeetRa title), where (map region),
# play (gameplay type), scenario, boss (boss or set piece), reward (mechanic or reward), pin (map x, y)
STORIES = [
    # ---------------- Book I ----------------
    dict(n=1, age="I", source="Kayumars and the Black Div",
         summary="The first king rules from the mountains, dressed in leopard skin. His son Siamak is killed by the son of Ahriman, "
         "and the grieving king raises an army of people and beasts to take revenge.",
         chapter="The Mountain King", where="Sky Spine", play="Prologue · tutorial",
         scenario="Play as Prince Tamsin, son of Orem the Mountain King, in a sunlit highland full of friendly animals. "
         "The Black Hollow ambushes him at a cliff shrine and the prince falls. Control switches to Orem, who rallies "
         "lions, leopards and eagles. Each animal ally teaches one move.",
         boss="The Black Hollow: a shadow that can only be hit when an eagle ally lights it from above.",
         reward="Animal calls: summon a beast ally for a few seconds.", pin=(700, 455)),
    dict(n=2, age="I", source="Hushang and the Discovery of Fire",
         summary="King Hushang throws a stone at a serpent. It misses, strikes a rock and makes a spark, and fire is born. "
         "He also teaches people to mine iron and dig channels.",
         chapter="The First Spark", where="Sky Spine foothills", play="Puzzle platformer",
         scenario="Kael the Flint-Striker hunts a giant cave serpent through dark tunnels. A missed throw hits flint and "
         "lights the first fire. The second half of the level is lit by the player's own torches: light braziers, smelt ore "
         "and open water channels to reach the exit.",
         boss="Cave Serpent: lure it into light so it recoils.",
         reward="The first Hearth (checkpoint fire). This chapter explains why hearths exist in MeetRa.", pin=(610, 500)),
    dict(n=3, age="I", source="Tahmuras the Div-Binder",
         summary="Tahmuras tames animals and binds the divs with spells and a heavy mace. In exchange for their lives, the "
         "defeated divs teach humans thirty kinds of writing.",
         chapter="The Binder", where="Crownhold plains", play="Capture and ride",
         scenario="Taro the Binder rides out on Ahrim, a captured shadow-beast, to stop a horde of Hollows. Weakened "
         "enemies can be bound instead of destroyed. Each bound Hollow becomes a glyph that unlocks a script stone.",
         boss="The Hollow Horde: wave survival on a moving mount.",
         reward="Script Stones: collectible lore. A codex page opens for each one.", pin=(800, 560)),
    dict(n=4, age="I", source="Jamshid: The Golden Age and the Fall",
         summary="Jamshid rules for centuries, building, healing and making the divs carry him through the sky on a jewelled "
         "throne. His pride grows until he claims to be divine, and the royal glory, the farr, leaves him.",
         chapter="The Radiant Throne", where="Crownhold", play="Builder sequence + escape",
         scenario="A golden-age city builder in miniature: Jarem the Radiant places forges, baths and workshops. Then the "
         "pride scene. Jarem's aura, shown as a halo, drains away and the city turns on him. The level ends in a desperate "
         "chase through his own collapsing palace.",
         boss="Set piece: the flying throne crashes. Steer it through towers.",
         reward="Teaches the Aura resource and how it can be lost.", pin=(760, 600)),
    dict(n=5, age="I", source="Zahhak the Serpent King",
         summary="Iblis tempts Prince Zahhak to kill his father. Disguised as a cook, he kisses Zahhak's shoulders and two "
         "serpents grow there, which must be fed human brains each day. Zahhak seizes the throne after Jamshid falls.",
         chapter="The Whispering Cook", where="Serpent Sands", play="Stealth · horror",
         scenario="Play the palace kitchen servants who secretly save one of the two daily victims and smuggle them into the "
         "desert. Vexar's serpents sense movement; hide in steam, shadows and crowds. Every rescued person later founds "
         "a desert tribe that helps in later chapters.",
         boss="No fight. A tense escape from the twin serpents at the palace gate.",
         reward="Stealth crouch and hiding spots.", pin=(450, 800)),
    dict(n=6, age="I", source="Kaveh the Blacksmith and Fereydun",
         summary="Kaveh, whose sons were taken for the serpents, raises his leather apron on a spear as a banner and starts "
         "a revolt. Young Fereydun, raised in secret, forges an ox-headed mace and overthrows Zahhak, who is chained "
         "inside Mount Damavand.",
         chapter="The Leather Banner", where="Crownhold → Chain Mountain", play="Rebellion campaign",
         scenario="Bram the Smith raises the Leather Banner in the market; the crowd grows as the player frees districts. "
         "Faren, raised in secret by a forest cow-herd, joins with the Ox-Head Mace. The final ascent climbs the Chain "
         "Mountain to bind Vexar inside it.",
         boss="Vexar, the Twin-Serpent King: three phases. Each serpent head must be stunned before the king can be struck.",
         reward="Ox-Head Mace: heavy weapon that breaks shields. The Leather Banner rallies allies.", pin=(820, 455)),
    dict(n=7, age="I", source="Fereydun Divides the World",
         summary="Fereydun splits the world among his three sons: Salm takes the West, Tur the East and Iraj the heartland. "
         "Jealous, the two elder brothers murder Iraj.",
         chapter="Three Crowns", where="Marble West · Duskland · Crownhold", play="Branching chapter",
         scenario="One prologue, three short levels. Play each prince's journey to his land: the marble cities of the West, "
         "the open steppe of the East, and the green heart. The final scene is the betrayal at a peace tent, told from "
         "Ilan's view.",
         boss="None. The loss is the point; it sets up the feud for the whole saga.",
         reward="Unlocks the world map and the three main regions.", pin=(760, 640)),
    dict(n=8, age="I", source="Manuchehr's Revenge",
         summary="Iraj's grandson Manuchehr grows up, leads the army against his great-uncles Salm and Tur and kills them both.",
         chapter="The Grandson's Oath", where="Ashen River", play="Battlefield chapter",
         scenario="Mael leads a small war band across the Ashen River. Large battle levels with formations of soldiers "
         "in the background; the player cuts through to the two kings.",
         boss="Torvak and Sael: a double boss that shares one health bar and switches between ranged and melee.",
         reward="War Horn: a short-range shockwave.", pin=(1060, 420)),

    # ---------------- Book II ----------------
    dict(n=9, age="II", source="Zal and the Simurgh",
         summary="Sam's son Zal is born with white hair. His father abandons him on a mountain, where the Simurgh raises him "
         "in her nest. Sam later repents and brings him home; the Simurgh gives Zal a feather to burn if he ever needs her.",
         chapter="The White-Haired Child", where="Saena's Peak", play="Vertical climb · flight",
         scenario="Climb Saena's Peak as young Zev, raised by the great bird. Levels are vertical: wind currents, "
         "nest platforms, eggs to protect from mountain lynxes. The chapter ends with the father, Sarn the Lionheart, "
         "climbing up to ask forgiveness.",
         boss="Storm Wyvern that hunts Saena's chicks.",
         reward="Saena's first feather. This becomes the core spell later.", pin=(905, 420)),
    dict(n=10, age="II", source="Zal and Rudabeh",
         summary="Zal falls in love with Rudabeh, daughter of the king of Kabul, who comes from Zahhak's line. She lets down "
         "her long hair from a tower for him to climb. The match causes a crisis between the two families.",
         chapter="The Tower of Kabulmere", where="Kabulmere", play="Romance · diplomacy",
         scenario="A lighter chapter. Zev sneaks into Kabulmere by night; Rue lowers her braid from the tower and the "
         "player climbs it (a rope mechanic). Daytime is dialogue choices with suspicious lords that change how many "
         "guards patrol the night levels.",
         boss="None. A chase across rooftops if the plan is discovered.",
         reward="Rope climbing, later reused for the Hunter's Lasso.", pin=(1260, 640)),
    dict(n=11, age="II", source="The Birth of Rostam",
         summary="Rudabeh's labour is dangerous. Zal burns the Simurgh's feather, and the bird tells him how to deliver the "
         "child safely. The baby, Rostam, is enormous and soon has the strength of a grown man.",
         chapter="Saena's Answer", where="Hearthvale", play="Short story chapter",
         scenario="A quiet chapter. Zev must reach the mountain before dawn to burn the feather and bring back Saena's "
         "advice and healing herbs. Ra's childhood follows as a short montage of training mini-games.",
         boss="None.",
         reward="Introduces Ra, the main hero, and the Hearthvale hub.", pin=(1085, 795)),
    dict(n=12, age="II", source="The White Elephant and Mount Sepand",
         summary="As a child, Rostam kills a raging white elephant with his grandfather's mace. His first mission is to take "
         "the fortress on Mount Sepand by disguising himself as a salt merchant.",
         chapter="The Salt Merchant", where="Hearthvale outskirts", play="Boss rush + infiltration",
         scenario="Part one: young Ra wakes to screams. A maddened white elephant is loose in the village; protect "
         "villagers and land the final blow. Part two: Ra hides in a salt caravan to enter the fortress of Sepand "
         "and opens the gates from inside.",
         boss="The White Elephant: charge and stun pattern (the Reed Lion's big brother).",
         reward="Grandfather's mace. Disguise mechanic.", pin=(1180, 720)),
    dict(n=13, age="II", source="Rostam Chooses Rakhsh",
         summary="Rostam searches for a horse strong enough to carry him and chooses a wild, rose-coloured colt, Rakhsh, after "
         "wrestling its mother. Horse and rider become inseparable.",
         chapter="Ember", where="Hearthvale plains", play="Taming mini-game",
         scenario="Ra tests horse after horse; each one buckles under his hand. A wild red colt runs with a fierce mare. "
         "Taming is a rhythm-and-balance mini-game. From now on, Ember can be called for fast travel and chase scenes.",
         boss="The mare, defending her colt (non-lethal).",
         reward="Ember, the horse: riding levels and fast travel between hearths.", pin=(1060, 800)),
    dict(n=14, age="II", source="Kay Qobad from Mount Alborz",
         summary="With the throne empty and Afrasiab invading, Zal sends Rostam to fetch Kay Qobad, a royal heir living "
         "quietly on Mount Alborz. On the way back Rostam lifts Afrasiab out of his saddle by the belt.",
         chapter="The Heir on the Mountain", where="Sky Spine", play="Escort",
         scenario="Ride Ember up the Sky Spine to find Kaedan, a royal heir living as a hermit, and escort him down through "
         "Dusk Khan scouts. Climax: a cavalry duel where Ra grabs Varak, the Dusk Khan, by the belt before his guards "
         "drag him away.",
         boss="Varak, first duel: he cannot be beaten yet; survive and grab the belt.",
         reward="Ra's rival is introduced. Grab-and-throw move.", pin=(1010, 455)),
    dict(n=15, age="II", source="Kay Kavus in Mazandaran and Rostam's Seven Labours",
         summary="King Kay Kavus marches on Mazandaran, land of the divs, and is blinded and captured by the White Div. "
         "Rostam takes the short, deadly road: a lion, a waterless desert, a dragon, a witch, Olad, Arzhang Div and finally "
         "the White Div, whose blood cures the king's eyes.",
         chapter="THE SEVEN TRIALS (the current game)", where="Hearthvale → Frostwood", play="Main campaign · 7 regions",
         scenario="This is MeetRa episode one, already in development. King Aurel the Vain marches north, and the Pale "
         "Giant swallows the Dawnfire and blinds his guard. Ra takes the Road of Seven Trials: the Reed Lion, the "
         "Thirsting Sands, the Night Serpent, the Veiled Witch, the Mountain Warden, the Horned Warlord and the Pale Giant.",
         boss="Seven bosses, one per trial. See the game design document.",
         reward="Saena's Feather, Ember Burst, Hunter's Lasso, Truthlight, the four Dawnblade shards.", pin=(1180, 690)),
    dict(n=16, age="II", source="Kay Kavus in Hamavaran and the Flying Throne",
         summary="Kay Kavus marries Sudabeh, princess of Hamavaran, and is imprisoned by her father; Rostam frees him. Later "
         "the king ties eagles to his throne to fly to heaven and crashes in a forest.",
         chapter="The Copper Coast", where="Copper Coast", play="Prison break + comedy set piece",
         scenario="Ra frees King Aurel and his new queen, Sedra, from the Copper King's sea fortress, with tides that flood "
         "and drain the dungeon. Epilogue: Aurel straps eagles to his throne. The player steers the flight until it crashes "
         "into a forest and Ra has to carry the king home.",
         boss="The Copper King's war galley.",
         reward="Swimming and tide levels.", pin=(320, 960)),
    dict(n=17, age="II", source="The Hunt of the Seven Heroes",
         summary="Rostam and the great champions hold a hunting feast on Turanian land. Afrasiab attacks, and the heroes win "
         "the fight.",
         chapter="The Seven Hunters", where="Duskland border", play="Co-op · party chapter",
         scenario="An optional chapter in which Ra and six companions hunt on the Duskland border. Swap between heroes, each "
         "with one signature move (archer, spear, lasso...). Midway the Dusk Khan's army ambushes the feast.",
         boss="Dusk Khan's war elephants.",
         reward="Hero swap system, later used in the Twelve Duels.", pin=(1180, 380)),
    dict(n=18, age="II", source="Rostam and Sohrab",
         summary="On a hunt in Samangan, Rostam spends a night with Princess Tahmineh. Their son Sohrab grows up in Turan, "
         "leads an army into Iran and fights his father without either knowing the truth. Rostam kills him and learns too "
         "late who he is.",
         chapter="Father and Son", where="Silverhill → White Fortress", play="Duel chapter · tragedy",
         scenario="Ember is stolen in Silverhill, and Ra meets Lady Iris. Years later the player controls Sorin, a young "
         "champion of the Dusk Khan, taking the White Fortress (a duel with Gerda the Shieldmaiden). The finale is a "
         "three-round duel played from both sides; the player cannot avoid the ending.",
         boss="Ra vs Sorin: three duels on three days.",
         reward="The armband token (story item). Unlocks the hard-mode 'Sorin's Path'.", pin=(1330, 520)),
    dict(n=19, age="II", source="Siavash and the Trial by Fire",
         summary="Prince Siavash rejects the advances of his stepmother Sudabeh, who accuses him. He proves his innocence by "
         "riding through a mountain of fire, then leaves for Turan to avoid a dishonourable war.",
         chapter="Through the Fire", where="Crownhold", play="Auto-runner set piece",
         scenario="Queen Sedra accuses Prince Aven. The trial is a pure auto-runner: two walls of fire, Aven on a black "
         "horse, the player only jumps and dodges. No damage allowed. Clearing it unlocks the Fireproof Cloak.",
         boss="The fire corridor itself.",
         reward="Fireproof Cloak (fire resistance charm).", pin=(735, 625)),
    dict(n=20, age="II", source="Siavash in Turan",
         summary="Siavash is welcomed by Afrasiab, marries his daughter Farangis and builds the beautiful city of Siavashgerd. "
         "The jealous Garsivaz poisons Afrasiab's mind, and Siavash is killed. A plant grows from his blood.",
         chapter="The Garden City", where="Aven's City", play="City builder + doomed defence",
         scenario="Aven builds a garden city in the Duskland with Princess Faye. Pleasant building and festival levels slowly "
         "fill with dread as Garsk spreads lies. The player sees the trap coming and cannot stop it.",
         boss="None. A last stand on the road, which cannot be won.",
         reward="The Blood-Flower: a healing plant that appears in every later Duskland level.", pin=(1420, 380)),
    dict(n=21, age="II", source="Giv Brings Kay Khosrow Home",
         summary="Siavash's son Kay Khosrow grows up hidden among shepherds in Turan. The hero Giv searches for him for seven "
         "years, finds him, and escorts him and Farangis back across the Oxus.",
         chapter="Seven Years Searching", where="Duskland → Ashen River", play="Open exploration",
         scenario="Gale the Seeker wanders the Duskland for years (shown by changing seasons) looking for Corin, Aven's son. "
         "An open, non-linear region with clues hidden in villages. Then an escort run to the Ashen River with the Dusk "
         "Khan's riders closing in. Corin crosses the river on horseback without a boat.",
         boss="River crossing chase.",
         reward="Seasons system for open regions.", pin=(1260, 300)),
    dict(n=22, age="II", source="The Tragedy of Forud",
         summary="Forud, another son of Siavash, lives in a fortress on the army's route. Through misunderstanding and the "
         "commander Tus's pride, the Iranian army attacks him and he is killed.",
         chapter="The Brother on the Hill", where="Bright Fort", play="Tower defence (reversed)",
         scenario="Play Prince Fen defending his hill fort with a bow against an army that is actually on his side. Every "
         "arrow choice matters: you can wound, warn or spare. The ending changes only in its final scene.",
         boss="General Tusk, the proud commander.",
         reward="Bow aiming (touch drag-to-aim).", pin=(1150, 480)),
    dict(n=23, age="II", source="The War with Kamus of Kashan",
         summary="A huge Turanian alliance including the giant champion Kamus traps the Iranian army on Mount Hamavan. "
         "Rostam arrives and catches Kamus with his lasso.",
         chapter="The Mountain Siege", where="Hamavan Heights", play="Siege defence",
         scenario="The army is trapped on a mountaintop. Defend the camp at night; scout by day. When Ra and Ember finally "
         "arrive, the Hunter's Lasso returns in a giant-catching boss fight.",
         boss="Kamen of the Hills, a giant who throws boulders.",
         reward="Lasso upgrade: drag giants to the ground.", pin=(1300, 450)),
    dict(n=24, age="II", source="Rostam and Akvan Div",
         summary="Akvan, a div in the form of a wild ass, steals sleeping Rostam, lifting the ground beneath him, and asks "
         "whether he wants to be thrown into the sea or onto the mountains. Rostam answers cleverly and survives.",
         chapter="The Whirlwind Ogre", where="Inner Sea", play="Trickster boss",
         scenario="A golden wild horse leads Ra on a chase until he sleeps. He wakes in the sky, carried by the Whirlwind "
         "Ogre, who asks 'the sea or the mountains?' The answer the player picks decides the next level: a swimming escape "
         "or a mountain fall. Both end in a rematch.",
         boss="The Whirlwind Ogre: vanishes and reappears; read the wind to find it.",
         reward="Choice-driven level branching.", pin=(830, 250)),
    dict(n=25, age="II", source="Bijan and Manijeh",
         summary="The young hero Bijan falls in love with Afrasiab's daughter Manijeh. He is caught and thrown into a pit "
         "under a great stone. Rostam disguises himself as a merchant, finds him through Manijeh and lifts the stone.",
         chapter="The Stone Pit", where="Stone Pit", play="Two-character puzzle",
         scenario="Bran is trapped in a pit under a giant stone. Mira lowers food each night. The player switches between "
         "Mira above, hiding from guards, and Bran below, keeping hope (a stamina meter). Ra arrives as a merchant; "
         "a ring baked in bread is the signal. Ra's final lift is a button-mash heroic moment.",
         boss="Guard captain at the pit's edge.",
         reward="Merchant disguise returns; caravan trading screen.", pin=(1200, 250)),
    dict(n=26, age="II", source="The Twelve Combats",
         summary="Instead of a full battle, the two armies agree to let their champions fight in pairs. The Iranian heroes win "
         "almost every duel.",
         chapter="The Twelve Duels", where="Duskland plain", play="Boss gauntlet",
         scenario="A gauntlet of twelve one-on-one duels, each with a different hero from the swap roster and a different "
         "opponent style. Perfect for short mobile sessions; each duel is a two-minute fight with a star rating.",
         boss="Twelve champions, one per duel.",
         reward="Arena mode for replay.", pin=(1360, 330)),
    dict(n=27, age="II", source="The Great War and the End of Afrasiab",
         summary="Kay Khosrow leads the final war against Afrasiab, who flees and hides in a lake. The hermit Hum catches him, "
         "and Afrasiab is executed for the murder of Siavash.",
         chapter="The Dusk Khan's End", where="Lake of Hiding", play="Epic finale + chase",
         scenario="The full army marches on the Dusk Khan's capital. Varak escapes and hides beneath a mountain lake. Hume the "
         "Hermit, a quiet side character met earlier, tricks him to the surface. Final duel on a stormy shore.",
         boss="Varak, the Dusk Khan: the long-awaited final duel with Ra's rival.",
         reward="End of the Hero Age arc. Unlocks the epilogue.", pin=(1500, 300)),
    dict(n=28, age="II", source="Kay Khosrow Leaves the World",
         summary="At the height of his power, Kay Khosrow fears becoming proud like Jamshid. He gives up the throne, walks "
         "into the mountains and disappears in a snowstorm. Several heroes who follow him die in the snow.",
         chapter="Into the Snow", where="Sky Spine heights", play="Quiet ending level",
         scenario="A meditative final level of Book II. King Corin walks into the mountains; the player follows with the "
         "companions in a slowly rising snowstorm. No enemies. Each companion stops at a different point to say goodbye.",
         boss="None.",
         reward="Credits for Book II. Corin's crown becomes a collectible.", pin=(700, 400)),
    dict(n=29, age="II", source="Goshtasp in Rum",
         summary="Prince Goshtasp, angry at his father, goes to Rum. Princess Katayun chooses him as husband; to win the "
         "emperor's favour he kills a monstrous wolf and a dragon.",
         chapter="The Exile in the West", where="Marble West", play="Monster hunt",
         scenario="Prince Gast arrives in the Marble West as a nameless stranger. Katya picks him at a choosing ceremony. Two "
         "monster hunts follow: a wolf the size of a house in the forest, and a sea dragon on the cliffs.",
         boss="The Great Wolf; the Cliff Dragon.",
         reward="Hunting traps and bait.", pin=(220, 330)),
    dict(n=30, age="II", source="The Prophet and the War with Arjasp",
         summary="Zoroaster brings a new faith to Goshtasp's court and the king accepts it. Arjasp of Turan demands they give "
         "it up; war follows and the young hero Esfandiyar rises.",
         chapter="The Fire Prophet", where="Crownhold", play="Defence of the sacred fire",
         scenario="A wandering prophet plants a cypress at the palace and lights a new sacred fire. Ardak of the Duskland "
         "attacks to put it out. Defend the temple in waves while Prince Aspen, freed from prison, rides to help.",
         boss="Ardak's siege engine.",
         reward="The Great Cypress: a giant hub tree that grows as the story continues.", pin=(780, 590)),
    dict(n=31, age="II", source="The Seven Labours of Esfandiyar",
         summary="To rescue his sisters, Esfandiyar takes his own road of seven trials: wolves, lions, a dragon, a witch, the "
         "Simurgh's mate, snow and a river, before taking the Brazen Fortress.",
         chapter="The Bronze Trials", where="Duskland → Brazen Fortress", play="Remix campaign",
         scenario="A 'mirror' of the Seven Trials. Prince Aspen, the bronze-skinned prince who cannot be wounded, walks a "
         "second road of seven trials. Same structure, darker remixed levels, a war chariot with blades. His fourth trial "
         "makes him fight Saena's mate, which turns Saena against him.",
         boss="Seven remix bosses, ending in the Brazen Fortress.",
         reward="New Game+ mode built from the Seven Trials.", pin=(1450, 460)),
    dict(n=32, age="II", source="Rostam and Esfandiyar",
         summary="King Goshtasp orders Esfandiyar to bring Rostam in chains. Neither hero wants to fight. Rostam is badly "
         "wounded by the invulnerable prince; the Simurgh shows him a tamarisk branch to make an arrow aimed at the eyes.",
         chapter="The Tamarisk Arrow", where="Hearthvale", play="Unwinnable duel → solution",
         scenario="Old Ra against Prince Aspen. Day one cannot be won: Aspen takes no damage. Night: Ra burns Saena's last "
         "feather and she leads him to a tamarisk by the sea. Day two: a bow duel where only a perfect shot to the eyes "
         "counts. The game asks twice if you are sure.",
         boss="Prince Aspen the Bronze.",
         reward="Saena leaves the story. The emotional peak of the saga.", pin=(1150, 805)),
    dict(n=33, age="II", source="The Death of Rostam",
         summary="Rostam's jealous half-brother Shaghad lures him on a hunt to a field of pits lined with spears. Rakhsh and "
         "Rostam fall in. With his last strength Rostam shoots Shaghad through the tree he hides behind.",
         chapter="The Hunting Ground", where="Shadewell", play="Final level of Ra's life",
         scenario="Shade, Ra's half-brother, invites him to hunt. Ember refuses to step forward and Ra, for the first time, "
         "forces him. The ground gives way. The last playable moment: one arrow, one shot, through a plane tree. Then "
         "Faro, Ra's son, carries the story forward.",
         boss="Shade: one arrow, no second chance.",
         reward="The Book of Ra: an unlockable gallery of everything he did.", pin=(1320, 650)),

    # ---------------- Book III ----------------
    dict(n=34, age="III", source="Homay and Darab",
         summary="Queen Homay, fearing for her throne, puts her newborn son Darab in a chest on the Euphrates. A washerman "
         "finds and raises him; he grows into a warrior and is recognised as heir.",
         chapter="The River Child", where="Two Rivers", play="Rafting · growing-up chapter",
         scenario="The first level is the chest on the river: steer through rapids as a baby (gently comic). Then Dar grows "
         "up with a washerman's family, learning to fight by the river. Queen Hela recognises him by the jewel left in "
         "the chest.",
         boss="River Crocodile Lord.",
         reward="Rafting levels.", pin=(560, 640)),
    dict(n=35, age="III", source="Dara and Iskandar",
         summary="Iskandar of Rum (Alexander) invades Iran and defeats King Dara, who is stabbed by his own ministers. Dara "
         "dies in Iskandar's arms, asking him to marry his daughter Roshanak.",
         chapter="The Last Embrace", where="Marble West → Crownhold", play="Army march + tragedy",
         scenario="Play Alexion of the Marble West marching east. Big battles, then a twist: King Dorian is betrayed by his "
         "own ministers. Alexion finds him dying and the player chooses whether to punish the traitors.",
         boss="The traitor ministers.",
         reward="Formation commands for battle levels.", pin=(470, 545)),
    dict(n=36, age="III", source="The Journeys of Iskandar",
         summary="Iskandar travels to the edges of the world: he searches for the Water of Life in the Land of Darkness, "
         "builds a wall against Gog and Magog, and meets a talking tree that foretells his death.",
         chapter="The Edge of the World", where="Lightless Land · Wall of Yag", play="Exploration anthology",
         scenario="An anthology of short worlds: the Lightless Land (play in total darkness by sound and glowing stones), "
         "building the great wall against the Yag swarm (a defence builder) and the Talking Tree, which tells Alexion "
         "how many days he has left.",
         boss="The Yag Swarm.",
         reward="Darkness and sound-based navigation.", pin=(320, 110)),
    dict(n=37, age="III", source="Ardashir and the Worm of Haftvad",
         summary="Ardashir escapes King Ardavan's court with the maid Golnar. He founds the Sasanian line and defeats "
         "Haftvad, whose power comes from a giant worm kept in a fortress and fed on rice and milk.",
         chapter="The Silkworm Fortress", where="Wormhold", play="Infiltration · boss",
         scenario="Ardan and Gala escape the king's stables at night on two horses. Later, Ardan learns that a warlord's "
         "power comes from a giant worm fed in a fortress. Disguised as merchants again, he feeds it molten metal.",
         boss="The Silkworm: a huge worm boss that fills the screen.",
         reward="Molten metal tool (a callback to Hushang's forge).", pin=(660, 820)),
    dict(n=38, age="III", source="Shapur",
         summary="Young Shapur, Ardashir's hidden son, is recognised at a polo game. As king he wars with Rome and is once "
         "captured, sewn into a donkey skin, and escapes.",
         chapter="The Polo Field", where="Crownhold", play="Sport mini-game + escape",
         scenario="A polo match on horseback reveals young Prince Shay's identity. Years later he is captured in the West and "
         "sewn into a hide; a sympathetic maid helps him escape. A stealth-and-ride chapter.",
         boss="The Western emperor's guard.",
         reward="Polo mini-game (multiplayer on one phone).", pin=(820, 640)),
    dict(n=39, age="III", source="Bahram Gur",
         summary="Bahram Gur, a famous hunter, claims the throne by taking the crown from between two lions. He hunts with "
         "the harpist Azadeh, who mocks a cruel shot and pays for it, and he travels in disguise among his people.",
         chapter="The Crown Between Lions", where="Crownhold · Spice Shore", play="Hunting + incognito",
         scenario="Behr the Hunter wins the crown by taking it from between two chained lions (a call back to the Reed "
         "Lion). Hunting levels with Aza the harpist. Later he travels in disguise to the Spice Shore and fights a "
         "rhinoceros-like beast and a dragon for its king.",
         boss="Two crown lions; the Spice Shore dragon.",
         reward="Lute rhythm mini-game; incognito villages.", pin=(1450, 820)),
    dict(n=40, age="III", source="Mazdak",
         summary="Mazdak preaches that wealth should be shared and gains many followers during a famine. The king's son "
         "Anushirvan turns against him, and Mazdak and his followers are killed.",
         chapter="The Famine Granaries", where="Crownhold", play="Moral choice chapter",
         scenario="During a famine the preacher Mazen opens the royal granaries. The player chooses sides through a series "
         "of small acts, and the city changes accordingly. Neither side is presented as simply right.",
         boss="None. The result depends on choices.",
         reward="Reputation system.", pin=(745, 575)),
    dict(n=41, age="III", source="Anushirvan, Bozorgmehr and Chess",
         summary="The just king Anushirvan rules with his wise vizier Bozorgmehr. An Indian king sends a chess set as a "
         "challenge; Bozorgmehr solves it and invents backgammon in return.",
         chapter="The Sage's Game", where="Crownhold · Spice Shore", play="Puzzle chapter",
         scenario="Sage Mehrun answers riddles from foreign envoys. The Spice Shore sends a strange board game; the player "
         "works out the rules by watching. Then Mehrun invents his own dice game and sends it back.",
         boss="None. A riddle duel with the Spice Shore sages.",
         reward="Chess and backgammon-style mini-games in the hub.", pin=(1385, 735)),
    dict(n=42, age="III", source="Bahram Chubin",
         summary="The general Bahram Chubin wins a great victory against the Turks but is insulted by King Hormozd. He rebels, "
         "drives Khosrow Parviz from the throne, and is later murdered in exile.",
         chapter="The Insulted General", where="Duskland → Crownhold", play="Anti-hero campaign",
         scenario="General Chobe wins an impossible battle against an army of beasts and is sent a spindle and women's clothes "
         "as a reward. The player leads his rebellion, a tragic arc that mirrors Sorin and Aven.",
         boss="The young King Parris (cannot be killed; he escapes).",
         reward="Commander mode with troop orders.", pin=(1200, 560)),
    dict(n=43, age="III", source="Khosrow Parviz and Shirin",
         summary="Khosrow Parviz regains his throne and marries Shirin. Late in life he is imprisoned by his son; after his "
         "death Shirin takes her own life at his tomb.",
         chapter="The Golden Court", where="Crownhold", play="Story chapter",
         scenario="King Parris rebuilds his court and its famous treasures (a moving throne, a musician who plays a song for "
         "every day of the year). Shira is a playable character in palace intrigue levels. The ending is handled quietly, "
         "off-screen.",
         boss="Palace coup.",
         reward="Music collectibles: 30 songs, one per hidden room.", pin=(790, 620)),
    dict(n=44, age="III", source="Yazdegerd and the End of the Kings",
         summary="The last king, Yazdegerd III, loses the empire to the Arab armies. He flees east and is killed in a mill "
         "by a miller who wants his clothes.",
         chapter="The Last Hearth", where="Shadewell → Hearthvale", play="Epilogue",
         scenario="The last King Yazen flees east with the last flame from the royal hearth. The player carries the flame "
         "through every region of the map in reverse. The final scene is in Hearthvale, where the flame is passed to a "
         "child, and a feather falls from the sky.",
         boss="None.",
         reward="True ending of the saga. Links back to Ra and Saena.", pin=(1160, 700)),
]

# Cast: Shahnameh source → MeetRa original name
CAST = [
    ("Kayumars", "Orem, the Mountain King"), ("Siamak", "Prince Tamsin"), ("The Black Div", "The Black Hollow"),
    ("Hushang", "Kael the Flint-Striker"), ("Tahmuras", "Taro the Binder"), ("Jamshid", "Jarem the Radiant"),
    ("Iblis", "The Whispering Cook"), ("Zahhak", "Vexar, the Twin-Serpent King"), ("Kaveh", "Bram the Smith"),
    ("Fereydun", "Faren"), ("Salm / Tur / Iraj", "Sael / Torvak / Ilan"), ("Manuchehr", "Mael"),
    ("Sam", "Sarn the Lionheart"), ("Zal", "Zev the White-Haired"), ("Rudabeh", "Rue of Kabulmere"),
    ("Simurgh", "Saena"), ("Rostam", "Ra"), ("Rakhsh", "Ember"), ("Kay Qobad", "Kaedan"),
    ("Kay Kavus", "King Aurel the Vain"), ("White Div", "The Pale Giant"), ("Sudabeh", "Queen Sedra"),
    ("Afrasiab", "Varak, the Dusk Khan"), ("Tahmineh", "Lady Iris"), ("Sohrab", "Sorin"),
    ("Gordafarid", "Gerda the Shieldmaiden"), ("Siavash", "Prince Aven"), ("Farangis", "Princess Faye"),
    ("Garsivaz", "Garsk"), ("Kay Khosrow", "King Corin"), ("Giv", "Gale the Seeker"), ("Forud", "Prince Fen"),
    ("Tus", "General Tusk"), ("Kamus", "Kamen of the Hills"), ("Akvan Div", "The Whirlwind Ogre"),
    ("Bijan / Manijeh", "Bran / Mira"), ("Hum", "Hume the Hermit"), ("Goshtasp", "Prince Gast"),
    ("Katayun", "Katya"), ("Zoroaster", "The Fire Prophet"), ("Arjasp", "Ardak"), ("Esfandiyar", "Prince Aspen the Bronze"),
    ("Shaghad", "Shade"), ("Faramarz", "Faro"), ("Homay / Darab", "Queen Hela / Dar"), ("Dara", "King Dorian"),
    ("Iskandar", "Alexion of the Marble West"), ("Ardashir / Golnar", "Ardan / Gala"), ("Shapur", "Prince Shay"),
    ("Bahram Gur / Azadeh", "Behr the Hunter / Aza"), ("Mazdak", "Mazen"), ("Bozorgmehr", "Sage Mehrun"),
    ("Bahram Chubin", "General Chobe"), ("Khosrow Parviz / Shirin", "King Parris / Shira"), ("Yazdegerd III", "King Yazen"),
]

# Places: Shahnameh source → MeetRa map region
PLACES = [
    ("Zabulistan", "Hearthvale"), ("Mount Alborz", "Sky Spine · Saena's Peak"), ("Mount Damavand", "Chain Mountain"),
    ("Iran (heartland)", "Crownhold"), ("Mazandaran", "Frostwood"), ("Caspian Sea", "The Inner Sea"),
    ("Turan", "The Duskland"), ("Oxus (Jayhun)", "The Ashen River"), ("Siavashgerd", "Aven's City"),
    ("Rum", "The Marble West"), ("Arabia (Zahhak's land)", "The Serpent Sands"), ("Hamavaran", "The Copper Coast"),
    ("India", "The Spice Shore"), ("Chin", "The Silk East"), ("Kabul", "Kabulmere · Shadewell"),
    ("Samangan", "Silverhill"), ("Land of Darkness", "The Lightless Land"), ("Gog and Magog", "The Yag Swarm"),
]
