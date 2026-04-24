import Topic from 'models/vocab_tools/topic';
import Lesson from 'models/vocab_tools/lesson';

VHL = { Audio: {}};
VHL.Audio.CollectionScheduler = class CollectionScheduler {
  constructor() {
    this.files = [];
  }

  stop_and_reset() {
    jest.fn();
  }
};

const words = [
  {
    ascii: 'tese',
    target: 'testTarget',
    topic: 'My Words',
  },
  {
    audio_paths: ['https://media.maestro.vhlcentral.com/audio/0014/00144497.mp3'],
    target: 'andar en patineta',
    topic: 'Pasatiempos',
  },
];
let lesson;

describe('Vocab Tools Lesson Model', () => {
  describe('creating a Lesson instance', () => {
    beforeEach(() => {
      lesson = new Lesson({
        id: 327,
        name: 'Lesson 1',
        words,
      });
    });

    it('sets the lesson name correctly', () => {
      expect(lesson.name).toEqual('Lesson 1');
    });

    it('adds a "selected" attribute to be false', () => {
      expect(lesson.selected).toBeFalsy();
    });

    it('populates an array of Topic objects', () => {
      lesson.topics.forEach((topic) => {
        expect(topic instanceof Topic).toBeTruthy();
      });
    });

    it('associates topics to the lesson', () => {
      expect(lesson.topics.length).toEqual(3);
    });

    it('sets the topic name correctly', () => {
      expect(lesson.topics[1].name).toEqual('My Words');
    });

    it('returns the total number of words associated with the lesson', () => {
      expect(lesson.wordCount).toEqual(2);
    });

    it('returns words from selected topics only', () => {
      lesson.topics[1].selected = false;
      lesson.topics[2].selected = true;
      expect(
        lesson.selectedWords().map((word) => {
          return word.target;
        })
      ).toEqual(['andar en patineta']);
    });

    it('returns the total number of words in the lesson', () => {
      expect(lesson.wordCount).toEqual(2);
    });
  });

  describe('#deselectAll', () => {
    beforeEach(() => {
      lesson = new Lesson({
        id: 327,
        name: 'Lesson 1',
        words,
      }, true);
      lesson.deselectAll();
    });

    it('sets all topics in lesson to be unselected', () => {
      lesson.topics.forEach((topic) => {
        expect(topic.selected).toBeFalsy();
      });
    });
  });

  describe('#hasSelectedTopics', () => {
    beforeEach(() => {
      lesson = new Lesson({
        id: 327,
        name: 'Lesson 1',
        words,
      });
    });

    it("returns true if any of the lesson's topics is selected", () => {
      lesson.topics[0].selected = true;
      expect(lesson.hasSelectedTopics()).toBeTruthy();
    });

    it("returns false if none of the lesson's topics is selected", () => {
      lesson.deselectAll();
      expect(lesson.hasSelectedTopics()).toBeFalsy();
    });
  });
});
