import Lesson from 'models/vocab_tools/lesson';
import Unit from 'models/vocab_tools/unit';

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

const lessonHash = {
  id: 327,
  name: 'Lesson 1',
  words,
};

const selectedLesson = new Lesson(lessonHash, true);
const notSelectedLesson = new Lesson(lessonHash, false);

describe('Vocab Tools Unit Model with selected "true"', () => {
  let unit;

  beforeEach(() => {
    unit = new Unit({
      id: 303,
      name: 'Lección 1',
      lessons: [selectedLesson],
    });
  });

  it('returns selected words', () => {
    expect(unit.selectedWords().length).toEqual(2);
  });

  it('returns word count', () => {
    expect(unit.wordCount()).toEqual(2);
  });
});

describe('Vocab Tools Unit Model with selected "false"', () => {
  let unit;

  beforeEach(() => {
    unit = new Unit({
      id: 303,
      name: 'Lección 1',
      lessons: [notSelectedLesson],
    });
  });

  it('returns an empty selected words', () => {
    expect(unit.selectedWords().length).toEqual(0);
  });

  it('returns the word count', () => {
    expect(unit.wordCount()).toEqual(2);
  });
});
