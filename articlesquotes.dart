// articlesquotes.dart
// Contains saints, quotes, and articles data for the app.

class Article {
  final String heading;
  final String body;
  Article({required this.heading, required this.body});
}

class Saint {
  final String id;
  final String name;
  final String image;
  final List<String> quotes;
  final List<Article> articles;
  Saint(this.id, this.name, this.image, this.quotes, this.articles);
}

final saints = [
  Saint(
    'vivekananda',
    'Swami Vivekananda',
    'https://images.unsplash.com/photo-1506744038136-46273834b3fb',
    [
      'Arise, awake, and stop not till the goal is reached.',
      'Take up one idea. Make that one idea your life — think of it, dream of it, live on that idea.',
      'Be a hero. Always say, \'I have no fear.\' Fear is death, fear is sin, fear is hell.',
      'The world is a grand moral gymnasium wherein we have all to take exercise so as to become stronger and stronger spiritually.',
      'You will be nearer to Heaven through football than through the study of the Gita.',
      'Everything can be sacrificed for truth, but truth cannot be sacrificed for anything.',
      'One who serves jiva, is indeed worshipping Shiva.',
      'O India! Forget not that the lower classes, the ignorant, the poor, the illiterate, the cobbler, the sweeper, are thy flesh and blood, thy brothers.',
      'We are what our thoughts have made us; so take care about what you think. Words are secondary. Thoughts live; they travel far.',
      'Sisters and brothers of America, it fills my heart with joy unspeakable to rise in response to the warm and cordial welcome which you have given us.'
    ],
    [
      Article(
        heading: 'Karma Yoga',
        body: 'Paramatman is a profound and multifaceted concept in Hindu philosophy...'
      ),
      Article(
        heading: 'Article 2 about Saint Vivekananda',
        body: 'Body of article 2...'
      )
    ],
  ),
  Saint(
    'sivananda',
    'Swami Sivananda',
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
    [
      'An ounce of practice is worth a ton of theory!',
      'Put your heart, mind, and soul into even your smallest acts. This is the secret of success.',
      'If you do not find peace within, you will not find it anywhere else.',
      'Don\'t fear the darkness if you carry the light within.',
      'The mind is responsible for the feelings of pleasure and pain. Control of the mind is the highest Yoga.',
      'Cultivate peace first in the garden of your heart by removing the weeds of lust, hatred, greed, selfishness, and jealousy.',
      'Look within. Within you is the hidden God. Within you is the immortal soul.',
      'Love expects no reward. Love knows no fear. Love Divine gives - does not demand.',
      'Patient and regular practice is the whole secret of spiritual realization. Do not be in a hurry in spiritual life.',
      'Make others truly happy as you strive to make yourself happy. Speak a helpful word. Give a cheering smile. Do a kind act.'
    ],
    [
      Article(
        heading: 'Karma Yoga',
        body: 'Paramatman is a profound and multifaceted concept in Hindu philosophy...'
      ),
      Article(
        heading: 'Article 2 about Saint Vivekananda',
        body: 'Body of article 2...'
      )
    ],
  ),
  Saint(
    'yogananda',
    'Paramhansa Yogananda',
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
    [
      'You must not let your life run in the ordinary way; do something that nobody else has done, something that will dazzle the world.',
      'The season of failure is the best time for sowing the seeds of success.',
      'Be as simple as you can be; you will be astonished to see how uncomplicated and happy your life can become.',
      'Live quietly in the moment and see the beauty of all before you. The future will take care of itself.',
      'The happiness of one\'s own heart alone cannot satisfy the soul; one must try to include, as necessary to one\'s own happiness, the happiness of others.',
      'Change yourself and you have done your part in changing the world.',
      'Persistence guarantees that results are inevitable.',
      'Remain calm, serene, always in command of yourself. You will then find out how easy it is to get along.',
      'Let my soul smile through my heart and my heart smile through my eyes, that I may scatter rich smiles in sad hearts.',
      'The power of unfulfilled desires is the root of all man\'s slavery.'
    ],
    [
      Article(
        heading: 'Karma Yoga',
        body: 'Paramatman is a profound and multifaceted concept in Hindu philosophy...'
      ),
      Article(
        heading: 'Article 2 about Saint Vivekananda',
        body: 'Body of article 2...'
      )
    ],
  ),
  Saint(
    'raman',
    'Maharishi Raman',
    'https://images.unsplash.com/photo-1465101046530-73398c7f28ca',
    [
      'Your own Self-Realization is the greatest service you can render the world.',
      'There is neither creation nor destruction, neither destiny nor free will, neither path nor achievement. This is the final truth.',
      'Happiness is your nature. It is not wrong to desire it. What is wrong is seeking it outside when it is inside.',
      'The question “Who am I?” will destroy all other questions.',
      'Wanting to reform the world without discovering one’s true self is like trying to cover the world with leather to avoid the pain of walking on stones and thorns.',
      'Silence is also conversation.',
      'The mind is nothing but thoughts. Stop thinking and show me the mind.',
      'The only useful purpose of the present birth is to turn within and realize the Self.',
      'No one succeeds without effort. Those who succeed owe their success to perseverance.',
      'Let what comes come. Let what goes go. Find out what remains.'
    ],
    [
      Article(
        heading: 'Karma Yoga',
        body: 'Paramatman is a profound and multifaceted concept in Hindu philosophy...'
      ),
      Article(
        heading: 'Article 2 about Saint Vivekananda',
        body: 'Body of article 2...'
      )
    ],
  ),
];
