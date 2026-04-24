import VocabToolsDataStore from 'features/vocab_tools/words/models/vocab_tools_data_store';
import WordList from 'models/vocab_tools/word_list';
import Topic from 'models/vocab_tools/topic';
import Word from 'models/vocab_tools/word';

const mockDataFromServer = {
  course_data: {
    enrolled: false,
    language_name: 'Spanish',
    units: [
      {
        id: 303,
        in_course: true,
        lessons: [
          {
            created_at: '2014-07-22T16:40:41-04:00',
            id: 324,
            label: 'Lección 1',
            name: 'Lección 1 | Hola, ¿qué tal?',
            rank: 0,
            updated_at: '2014-07-22T16:40:41-04:00',
          },
        ],
        media_item_filename: 'https://media.maestro.vhlcentral.com/images/0014/00145527.jpg',
        name: 'Lección 1',
        two_tier: false,
      },
    ],
  },
  words_data: {
    program_metadata: {
      vocab_has_definition: false,
    },
    words: [
      {
        ascii: 'Nos vemos',
        definition: null,
        id: 1,
        lesson_id: 324,
        target: 'Nos vemos',
        topic: 'My Words',
        translation: 'See you',
      },
      {
        ascii: 'Hasta luego',
        definition: null,
        id: 2,
        lesson_id: 324,
        target: 'Hasta luego',
        topic: 'My Words',
        translation: 'See you later',
      },
    ],
  },
};

VHL.Storage = VHL.Storage || {};
VHL.Storage.get = jest.fn(() => null);
WordList.forLesson = jest.fn(async () => mockDataFromServer);

VHL.Audio = VHL.Audio || {};
VHL.Audio.CollectionScheduler = class CollectionScheduler {
  constructor() {
    this.files = [];
  }
  stop_and_reset() {}
};

describe('VocabToolsDataStore', () => {
  describe('initialization', () => {
    let vocabToolsDataStore;
    beforeEach(async () => {
      vocabToolsDataStore = new VocabToolsDataStore();
    });

    describe('when constructor and init method is called', () => {
      it('calls the WordList.forLesson function', () => {
        expect(WordList.forLesson).toHaveBeenCalled();
      });

      it('sets enrolled false in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.enrolled).toEqual(false);
      });

      it('sets targetLanguage "Spanish" in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.targetLanguage).toEqual('Spanish');
      });

      it('sets twoTier false in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.twoTier).toEqual(false);
      });

      it('sets viewAllLessons false in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.viewAllLessons).toEqual(false);
      });

      it('sets vocabHasDefinition false in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.vocabHasDefinition).toEqual(false);
      });

      it('sets 1 unit in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.units.length).toEqual(1);
      });

      it('sets 1 lesson in unit in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.units[0].lessons.length).toEqual(1);
      });

      it('sets 2 topics in lesson in unit in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.units[0].lessons[0].topics.length).toEqual(2);
      });

      it('sets first topic empty in lesson in unit in vocabToolsDataStore', () => {
        expect(vocabToolsDataStore.units[0].lessons[0].topics[0].words.length).toEqual(0);
      });

      it('sets second topic with 2 words in lesson in unit in vocabToolsDataStore', () => {
        const topicSelected = true;
        const topicInstance = new Topic({
          name: 'My Words',
          words: [
            new Word({
              ascii: 'Nos vemos',
              definition: null,
              id: 1,
              lesson_id: 324,
              target: 'Nos vemos',
              topic: 'My Words',
              translation: 'See you',
            }),
            new Word({
              ascii: 'Hasta luego',
              definition: null,
              id: 2,
              lesson_id: 324,
              target: 'Hasta luego',
              topic: 'My Words',
              translation: 'See you later',
            }),
          ],
        }, topicSelected);
        expect(vocabToolsDataStore.units[0].lessons[0].topics[1]).toEqual(topicInstance);
      });
    });
  });
});
