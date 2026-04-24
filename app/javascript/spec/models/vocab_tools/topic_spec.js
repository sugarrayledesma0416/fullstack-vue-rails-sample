import Word from 'models/vocab_tools/word';
import Topic from 'models/vocab_tools/topic';

VHL = { Audio: {}};
VHL.Audio.CollectionScheduler = class CollectionScheduler {
  constructor(paths) {
    this.files = [];
    paths.forEach((path) => {
      this.files.push({ src: path });
    });
  }

  stop_and_reset() {
    jest.fn();
  }
};

const words = [
  {
    id: 174342,
    lesson_id: 327,
    target: 'testTarget',
    topic: 'My Words',
  },
  {
    id: 174574,
    lesson_id: 327,
    target: 'mine',
    topic: 'My Words',
  },
];

const topicName = 'My Words';
let topic;

describe('Vocab Tools Topic Model', () => {
  describe('creating a Topic instance if selected is true', () => {
    beforeEach(() => {
      topic = new Topic(
        {
          name: topicName,
          words,
        },
        true
      );
    });

    it('sets the topic name correctly', () => {
      expect(topic.name).toEqual('My Words');
    });

    it('adds a "selected" attribute set to true', () => {
      expect(topic.selected).toBeTruthy();
    });

    it('returns the total number of words in the topic', () => {
      expect(topic.wordCount).toEqual(2);
    });

    it('returns array of all its words if topic is selected as true', () => {
      expect(topic.selectedWords).toEqual([
        new Word(words[0]),
        new Word(words[1]),
      ]);
    });

    it('returns an empty array if topic is selected as false', () => {
      topic.selected = false;
      expect(topic.selectedWords).toEqual([]);
    });
  });

  describe('add word to topic', () => {
    let wordToAdd;
    beforeEach(() => {
      topic = new Topic(
        {
          name: topicName,
          words,
        },
        true
      );
    });

    it('adds a new word', () => {
      wordToAdd = {
        id: 174575,
        lesson_id: 327,
        target: 'targetTesting',
        topic: 'My Words',
      };
      topic.addWord(wordToAdd);
      expect(topic.words[topic.words.length - 1]).toEqual(new Word(wordToAdd));
    });

    it('does not add a word if it is already in the topic', () => {
      wordToAdd = { target: 'testTarget' };
      topic.addWord(wordToAdd);
      expect(
        topic.words[topic.words.length - 1]
      ).not.toEqual(new Word(wordToAdd));
    });
  });

  describe('remove word from the topic', () => {
    let wordToRemove;

    beforeEach(() => {
      wordToRemove = new Word(words[0]);
      topic = new Topic(
        {
          name: topicName,
          words,
        },
        true
      );
    });

    it('word is removed if topic name is "My Words"', () => {
      topic.removeWord(wordToRemove);
      expect(topic.words).not.toContainEqual(wordToRemove);
    });

    it('word is not removed if topic name is not "My Words"', () => {
      topic.name = 'Pasatiempos';
      topic.removeWord(wordToRemove);
      expect(topic.words).toContainEqual(wordToRemove);
    });
  });
});
