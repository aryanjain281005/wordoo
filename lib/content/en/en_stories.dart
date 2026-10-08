import '../content_pack.dart';

StoryQuestion _q(String q, List<String> o, String type) => StoryQuestion(q, [for (final x in o) (x, null)], type);

/// Authored English stories for comprehension steps 3–10 (steps 1–3 also use generated stories).
const _hat = 'Milo lost his red hat in the park. Then it began to rain, so Milo felt cold. A kind duck found the hat and gave it back.';
final enStories = <StoryEntry>[
  StoryEntry('s-hat', 'Milo’s Hat', '🎩', _hat, 3, [
    _q('What did Milo lose?', ['His red hat', 'His ball', 'His kite'], 'detail'),
    _q('Why did Milo feel cold?', ['It began to rain', 'He lost his shoes', 'He was sleepy'], 'cause'),
    _q('Who found the hat?', ['A kind duck', 'A big dog', 'His friend'], 'detail'),
  ]),
  StoryEntry('s-seeds', 'Tia’s Seeds', '🌱', 'Tia planted seeds in a pot. She gave them water every day. After many days, a green plant came up.', 4, [
    _q('What did Tia plant?', ['Seeds', 'Shoes', 'Stones'], 'detail'),
    _q('Why did the plant grow?', ['Tia gave it water', 'It was night', 'A bird sat there'], 'cause'),
    _q('What came up after many days?', ['A green plant', 'A red flower', 'A big tree'], 'sequence'),
  ]),
  StoryEntry('s-berries', 'Fox and the Berries', '🦊', 'Milo was hungry. The berries were too high to reach. He stacked three logs and climbed up to eat.', 4, [
    _q('Why did Milo stack the logs?', ['To reach the berries', 'To build a house', 'To sit down'], 'cause'),
    _q('What did Milo do first?', ['He stacked the logs', 'He ate the berries', 'He went to sleep'], 'sequence'),
    _q('What kind of fox is Milo?', ['Clever', 'Lazy', 'Rude'], 'inference'),
  ]),
  StoryEntry('s-kite', 'The Red Kite', '💨', 'Leo had a red kite. The wind was strong, so the kite flew high. Then the string broke, and the kite floated away.', 5, [
    _q('Why did the kite fly high?', ['The wind was strong', 'It was heavy', 'It was raining'], 'cause'),
    _q('What happened last?', ['The kite floated away', 'Leo got a new kite', 'The wind stopped'], 'sequence'),
    _q('How did Leo feel at the end?', ['Sad', 'Excited', 'Sleepy'], 'inference'),
  ]),
  StoryEntry('s-puppy', 'Lost Puppy', '🐶', 'A little puppy got lost in the rain. A girl named Anu found him shivering under a bench. She wrapped him in her scarf and took him home.', 5, [
    _q('Where did Anu find the puppy?', ['Under a bench', 'In a tree', 'At school'], 'detail'),
    _q('Why was the puppy shivering?', ['He was wet and cold', 'He was angry', 'He was playing'], 'cause'),
    _q('What kind of girl is Anu?', ['Kind', 'Mean', 'Bored'], 'inference'),
  ]),
  StoryEntry('s-rocket', 'The Cardboard Rocket', '🚀', 'Kabir built a rocket from an old box. He painted it silver and drew stars on the side. When his little sister saw it, she clapped and asked for a ride. Kabir smiled and made room for two.', 6, [
    _q('What did Kabir use to build the rocket?', ['An old box', 'Some wood', 'A bucket'], 'detail'),
    _q('What did he do after painting it?', ['He drew stars on it', 'He threw it away', 'He went to sleep'], 'sequence'),
    _q('Why did Kabir make room for two?', ['His sister wanted a ride', 'The box was broken', 'He was tired'], 'cause'),
    _q('What will they probably do next?', ['Pretend to fly to space', 'Go to the shop', 'Cook dinner'], 'prediction'),
  ]),
  StoryEntry('s-market', 'Market Day', '🛒', 'Every Sunday, Meera goes to the market with her grandfather. Today he forgot his bag, so Meera carried the mangoes in her skirt. Grandfather laughed and called her his clever helper.', 6, [
    _q('When does Meera go to the market?', ['Every Sunday', 'Every night', 'On her birthday'], 'detail'),
    _q('Why did Meera carry mangoes in her skirt?', ['Grandfather forgot his bag', 'She liked mangoes', 'It was raining'], 'cause'),
    _q('How did Grandfather feel about Meera?', ['Proud and happy', 'Angry', 'Worried'], 'inference'),
  ]),
  StoryEntry('s-turtle', 'The Slow Turtle', '🐢', 'Tortu the turtle wanted to see the sunrise from the top of the hill. He started walking at midnight because he knew he was slow. When the sun came up, Tortu was sitting at the top, smiling.', 7, [
    _q('Why did Tortu start walking at midnight?', ['He knew he was slow', 'He was scared of the sun', 'His friends told him to'], 'cause'),
    _q('Where was Tortu when the sun came up?', ['At the top of the hill', 'At home', 'In the river'], 'detail'),
    _q('What does this story teach?', ['Planning ahead helps', 'Turtles are fast', 'Hills are dangerous'], 'inference'),
  ]),
  StoryEntry('s-library', 'The Quiet Library', '📚', 'Zoya loved the library because it was calm. One day a bird flew in through the window and began to sing. Everyone looked up from their books. The librarian opened the window wide, and the bird flew back to its tree.', 7, [
    _q('Why did Zoya love the library?', ['It was calm', 'It had a bird', 'It had games'], 'cause'),
    _q('What happened after the bird began to sing?', ['Everyone looked up', 'Zoya went home', 'The books fell'], 'sequence'),
    _q('Why did the librarian open the window wide?', ['To help the bird get out', 'Because it was hot', 'To let more birds in'], 'inference'),
  ]),
  StoryEntry('s-rain', 'The Rain Dance', '🌧️', 'The farmers in the village waited for rain for many weeks. The fields were dry and the cows were thirsty. One evening dark clouds rolled in, and big drops began to fall. The children ran outside and danced in the puddles.', 8, [
    _q('Why were the farmers waiting?', ['Their fields needed rain', 'They wanted snow', 'They were on holiday'], 'cause'),
    _q('What happened just before the drops began to fall?', ['Dark clouds rolled in', 'The children danced', 'The cows slept'], 'sequence'),
    _q('How did the children feel when it rained?', ['Joyful', 'Frightened', 'Bored'], 'inference'),
    _q('What will the fields look like in a few weeks?', ['Green and growing', 'Dry and cracked', 'Covered in snow'], 'prediction'),
  ]),
  StoryEntry('s-robot', 'Bolt’s First Friend', '🤖', 'Bolt the robot could carry heavy boxes and fix broken clocks, but he had never had a friend. One day a little girl dropped her ice cream and started to cry. Bolt could not fix ice cream, so he simply sat beside her and offered his hand. She stopped crying and smiled.', 8, [
    _q('What could Bolt do well?', ['Carry boxes and fix clocks', 'Sing and dance', 'Make ice cream'], 'detail'),
    _q('Why did the girl start to cry?', ['She dropped her ice cream', 'Bolt scared her', 'She was lost'], 'cause'),
    _q('What did Bolt learn?', ['Being kind matters more than fixing', 'Ice cream is easy to fix', 'Robots cannot have friends'], 'inference'),
  ]),
  StoryEntry('s-island', 'The Message in a Bottle', '🍾', 'While walking on the beach, Arjun found a glass bottle with a rolled-up note inside. The note said, “Whoever finds this, please write back. I live on the island across the sea.” Arjun ran home, found his best pencil, and began writing a long letter about his town.', 9, [
    _q('Where did Arjun find the bottle?', ['On the beach', 'In his garden', 'At school'], 'detail'),
    _q('Why did Arjun run home?', ['To write a reply', 'Because it was raining', 'To show his dog'], 'cause'),
    _q('What is the person who wrote the note probably feeling?', ['Curious and hopeful', 'Angry', 'Sleepy'], 'inference'),
    _q('What will Arjun most likely do with his letter?', ['Put it in the bottle and send it back', 'Throw it away', 'Eat it'], 'prediction'),
  ]),
  StoryEntry('s-festival', 'Lanterns for Everyone', '🏮', 'The night before the lantern festival, a storm tore Arya’s lantern into pieces. Instead of crying, she collected the torn paper and made five tiny lanterns. At the festival, she gave them to children who had none. The sky that night had more lights than ever before.', 9, [
    _q('What happened to Arya’s lantern?', ['A storm tore it', 'She lost it', 'Her brother took it'], 'detail'),
    _q('What did Arya do with the torn paper?', ['Made five tiny lanterns', 'Threw it away', 'Painted a picture'], 'sequence'),
    _q('Why were there more lights than ever before?', ['More children had lanterns', 'The moon was bigger', 'It was very cloudy'], 'cause'),
    _q('Which word describes Arya best?', ['Generous', 'Greedy', 'Careless'], 'inference'),
  ]),
  StoryEntry('s-cloud', 'The Cloud Who Wanted a Story', '☁️', 'Far above the islands lived a small grey cloud named Gumsum. Every evening he watched families reading together, but no one ever looked up at him. One night a girl noticed him, smiled, and read her favourite book out loud to the sky. Gumsum listened so carefully that he forgot to rain.', 10, [
    _q('What did Gumsum watch every evening?', ['Families reading together', 'Birds flying home', 'Boats on the sea'], 'detail'),
    _q('Why did Gumsum forget to rain?', ['He was listening to the story', 'He was too tired', 'The wind blew him away'], 'cause'),
    _q('How had Gumsum felt before that night?', ['Lonely and left out', 'Proud and happy', 'Angry and loud'], 'inference'),
    _q('What might Gumsum do the next evening?', ['Float back to hear another story', 'Move to another sky', 'Start a storm'], 'prediction'),
  ]),
];
