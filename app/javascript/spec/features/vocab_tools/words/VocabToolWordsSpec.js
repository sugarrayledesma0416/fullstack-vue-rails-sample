import { mount } from '@vue/test-utils';
import VocabToolWords from 'features/vocab_tools/words/VocabToolWords';

jest.mock('features/vocab_tools/words/models/vocab_tools_data_store', () => {
  return jest.fn().mockImplementation(() => {
    return {
      enrolled: true,
      ssjrStudent: true,
      targetLanguage: 'French',
      targetLanguageCode: 'fr',
      units: [],
      viewAllLessons: true,
      vocabHasDefinition: true,
    };
  });
});

let wrapper;
const getWrapper = () => {
  return mount(VocabToolWords, {
    global: {
      stubs: {
        FlashcardLayout: {
          template: '<div class="test-stub-comp-flashcard-layout"/>',
        },
        WordFilter: true,
        WordTable: {
          template: '<div class="test-stub-comp-word-table"/>',
        },
      },
    },
  });
};

describe('VocabToolWords', () => {
  beforeEach(() => {
    wrapper = getWrapper();
  });

  describe('when VocabToolWords is mounted', () => {
    it('displays "WordFilter" component', () => {
      expect(wrapper.findAllComponents({ name: 'WordFilter' })).toHaveLength(1);
    });

    it('displays "VocabTabs" component', () => {
      expect(wrapper.findAllComponents({ name: 'VocabTabs' })).toHaveLength(1);
    });

    it('displays "WordTable" component', () => {
      expect(wrapper.find('.test-stub-comp-word-table').isVisible()).toBeTruthy();
    });

    it('does not display "FlashcardLayout" component', () => {
      expect(wrapper.find('.test-stub-comp-flashcard-layout').isVisible()).toBeFalsy();
    });
  });

  describe('when Flashcards tab is clicked', () => {
    beforeEach( async () => {
      const flashcardsLink = wrapper.find('.test-flashcards-link');
      await flashcardsLink.trigger('click');
    });

    it('displays "FlashcardLayout" component', () => {
      expect(wrapper.find('.test-stub-comp-flashcard-layout').isVisible()).toBeTruthy();
    });

    it('does not display "WordTable" component', () => {
      expect(wrapper.find('.test-stub-comp-word-table').isVisible()).toBeFalsy();
    });
  });

  describe('when Vocabulary tab is clicked', () => {
    beforeEach( async () => {
      const vocabularyLink = wrapper.find('.test-vocabulary-link');
      await vocabularyLink.trigger('click');
    });

    it('displays "WordTable" component', () => {
      expect(wrapper.find('.test-stub-comp-word-table').isVisible()).toBeTruthy();
    });

    it('does not display "FlashcardLayout" component', () => {
      expect(wrapper.find('.test-stub-comp-flashcard-layout').isVisible()).toBeFalsy();
    });
  });
});
