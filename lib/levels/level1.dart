// THE FIRST TRIAL: The Reed Lion
// A lion stalks the reed marshes at the edge of the vale. Ra must face it before the road east opens.
// See build.dart for the map legend.

import 'build.dart';

const level1 = LevelDef(
  id: 'level1',
  title: 'The First Trial',
  subtitle: 'The Reed Marsh',
  rows: 17,
  chunks: [
    // Start: hearth and tutorial signs
    [
      '........................',
      '..A.P..S...S.*....v.....',
      '########################',
      '########################',
      '########################',
    ],
    // First pit and first demon
    [
      '.............====...........',
      '............................',
      '......====..................',
      '.................D.*..v.....',
      '####.......#################',
      '####.......#################',
      '####.......#################',
    ],
    // Steps, a carrion fly and a high chest
    [
      '....................C.........',
      '..................=====.......',
      '.............V................',
      '..........####................',
      '.....=====####................',
      '......*...####....D......v....',
      '##############################',
      '##############################',
      '##############################',
    ],
    // Saena's feather on the hill
    [
      '.............F............',
      '..........#######.........',
      '.........#########........',
      '..A...S.###########...*...',
      '##########################',
      '##########################',
      '##########################',
    ],
    // Thorn field
    [
      '......................V.............',
      '...........V........................',
      '......===...===...===...===.........',
      '....................................',
      'S..D....^^^^^^^^^^^^^^^^^^^....D..v.',
      '####################################',
      '####################################',
      '####################################',
    ],
    // Rest before the boss
    [
      '....A....S....',
      '##############',
      '##############',
      '##############',
    ],
    // Boss arena
    [
      '.....====..............====.....',
      '................................',
      '[......................L.......]',
      '################################',
      '################################',
      '################################',
    ],
    // Exit: the gate to the Second Trial
    [
      '..........G.....',
      '################',
      '################',
      '################',
    ],
  ],
  // Signposts are matched to 'S' tiles in map order
  signs: [
    '◁ ▷ to walk, △ to jump.\nTap △ again in the air to double jump!',
    'Swing your sword: three swings make a combo!\nIn the air, hold ▽ and swing to strike down.',
    'Old Mehr: "A feather of Saena waits on the hill.\nWhoever carries it is never alone in the dark."',
    'Thorns! Cross on the platforms.\nIf you fall, you return to the last safe ground.',
    'A roar rises from the reeds...\nRest at the hearth, then go on.',
  ],
  boss: BossDef('The Reed Lion', 'Terror of the Marsh'),
);
