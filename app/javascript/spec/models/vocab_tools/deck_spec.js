import Deck from 'models/vocab_tools/deck';

VHL = { Audio: {}};

VHL.Audio.CollectionScheduler = class CollectionScheduler {
  constructor() {
    this.files = [];
  }
};

const words = [
  { lesson: '1', topic: '1', target: 'foo' },
  { lesson: '1', topic: '1', target: 'bar' },
  { lesson: '1', topic: '1', target: 'baz' },
];

const units = [{
  name: 'Unit 1',
  lessons: [
    {
      displayName: 'Leçon 1A',
      topics: [
        {
          selected: true,
          words,
        },
      ],
    },
  ],
  selectedWords: () => {
    return words;
  },
}];

const compareWords = (a, b) =>{
  if (a.target < b.target) {
    return -1;
  }
  if (a.target > b.target) {
    return 1;
  }
  return 0;
};

const compareCards = (a, b) => {
  return compareWords(a.word, b.word);
};

/**
 * A Deck is initialized with an array of units or words object.
 * A Deck extracts words from selected topics in the units.
 * A Deck shuffles the array of words it is given.
 * For each word in the array, it creates a Flashcard and stores it in an array of flashcards.
 * A Deck can report how many cards out of the total number of cards the student knew.
 * A Deck can provide an array of all its words.
 * A Deck can provide an array of only the words for the cards the student did not know.
 */

describe('Deck', () => {
  let deck;

  describe('when units passed to constructor', () => {
    beforeEach(() => {
      deck = new Deck(units, 'units');
    });

    it('creates and stores an array of Flashcards based on a given array of words', () => {
      const flashcards = deck.flashcards.sort(compareCards);
      expect(flashcards.map((card) => {
        return card.word.target;
      })).toEqual(['bar', 'baz', 'foo']);
    });

    it('shuffles the flashcards indexes', () => {
      const flashcards = deck.flashcards;
      const shuffledIndexes = flashcards.map((flashcard) => flashcard.shuffledIndex);
      expect(shuffledIndexes).not.toEqual([0, 1, 2]);
    });
  });

  describe('when words passed to constructor', () => {
    beforeEach(() => {
      deck = new Deck(words, 'words');
    });

    it('creates and stores an array of Flashcards based on a given array of words', () => {
      const flashcards = deck.flashcards.sort(compareCards);
      expect(flashcards.map((card) => {
        return card.word.target;
      })).toEqual(['bar', 'baz', 'foo']);
    });

    it('shuffles the flashcards indexes', () => {
      const flashcards = deck.flashcards;
      const shuffledIndexes = flashcards.map((flashcard) => flashcard.shuffledIndex);
      expect(shuffledIndexes).not.toEqual([0, 1, 2]);
    });
  });

  describe('#setCards', () => {
    const newWords = [
      { topic: '1', target: 'able' },
      { topic: '1', target: 'baker' },
      { topic: '1', target: 'charlie' },
    ];

    beforeEach(() => {
      deck = new Deck(words, 'words');
      deck.setCards(newWords);
    });

    it('creates a set of flashcards based on given words and assigns it to the deck', () => {
      const flashcards = deck.flashcards.sort(compareCards);
      expect(flashcards.map((card) => {
        return card.word.target;
      })).toEqual(['able', 'baker', 'charlie']);
    });

    it('shuffles the flashcards indexes', () => {
      const flashcards = deck.flashcards;
      const shuffledIndexes = flashcards.map((flashcard) => flashcard.shuffledIndex);
      expect(shuffledIndexes).not.toEqual([0, 1, 2]);
    });
  });

  describe('#didNotKnowItWords', () => {
    beforeEach(() => {
      deck = new Deck(words, 'words');
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
    });

    it('returns an array of the words the student did not know', () => {
      const didNotKnowItWords = deck.didNotKnowItWords;
      expect(didNotKnowItWords.map((word) => {
        return word.target;
      })).toEqual(['baz']);
    });
  });

  describe('#knewItCount', () => {
    beforeEach(() => {
      deck = new Deck(words, 'words');
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
    });

    it('returns an count of the words the student know', () => {
      expect(deck.knewItCount).toEqual(2);
    });
  });

  describe('#knewItPercentage', () => {
    beforeEach(() => {
      deck = new Deck(words, 'words');
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
    });

    it('returns an percent count of the words the student know', () => {
      expect(deck.knewItPercentage.toFixed(2)).toEqual('66.67');
    });
  });

  describe('#donutText', () => {
    beforeEach(() => {
      deck = new Deck(words, 'words');
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
    });

    it('contains percent count of the words the student know', () => {
      expect(deck.donutText).toContain('66.66');
    });
  });
});
