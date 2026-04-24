import { mount } from '@vue/test-utils';
import FlashcardBack from 'features/dictionary_flashcards/FlashcardBack';

const word = {
  target: 'foo',
  definition: 'foo definition',
  translation: 'foo translation',
  audio_paths: [],
};

const flashcard = {
  isSourceLangTarget: true,
  isModeEnglishToTarget: false,
  isModeDefinitionToTarget: false,
};

const flashcardState = {
  index: 0,
  deck: { flashcards: [{ word }] },
  card: {
    languageCode: 'es',
    word,
  },
};

let hasAudio = true;

const getWrapper = () => {
  return mount(FlashcardBack, {
    global: {
      provide: {
        flashcard,
        flashcardState,
        hasAudio,
      },
      stubs: {
        FlashcardAudio: {
          template: '<div></div>',
        },
      },
    },
  });
};

const setMode = (mode) => {
  flashcard.isSourceLangTarget = ['TARGET_TO_TRANSLATION', 'TARGET_TO_DEFINITION'].includes(mode);
  flashcard.isModeTargetToTranslation = mode === 'TARGET_TO_TRANSLATION';
  flashcard.isModeTranslationToTarget = mode === 'TRANSLATION_TO_TARGET';
  flashcard.isModeDefinitionToTarget = mode === 'DEFINITION_TO_TARGET';
  flashcard.isModeTargetToDefinition = mode === 'TARGET_TO_DEFINITION';
};

describe('FlashcardBack', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
    });

    it('displays "I KNOW IT" button', () => {
      expect(wrapper.find('.test-flashcard-knew-it').exists()).toBeTruthy();
    });

    it('displays "NOT YET" button', () => {
      expect(wrapper.find('.test-flashcard-not-yet').exists()).toBeTruthy();
    });
  });

  describe('when mode is "TARGET_TO_TRANSLATION"', () => {
    beforeEach(() => {
      setMode('TARGET_TO_TRANSLATION');
      wrapper = getWrapper();
    });

    it("displays flashcard's word target in the 'flashcard-front'", () => {
      expect(
        wrapper.get('.test-flashcard-front .test-flashcard-word').text()
      ).toContain('foo');
    });

    it("displays flashcard's word translation in the 'flashcard-back'", () => {
      expect(
        wrapper.get('.test-flashcard-back .test-flashcard-word').text()
      ).toContain('foo translation');
    });
  });

  describe('when mode is "TRANSLATION_TO_TARGET"', () => {
    beforeEach(() => {
      setMode('TRANSLATION_TO_TARGET');
      wrapper = getWrapper();
    });

    it("displays flashcard's word translation in the 'flashcard-front'", () => {
      expect(
        wrapper.get('.test-flashcard-front .test-flashcard-word').text()
      ).toContain('foo translation');
    });

    it("displays flashcard's word target in the 'flashcard-back'", () => {
      expect(
        wrapper.get('.test-flashcard-back .test-flashcard-word').text()
      ).toContain('foo');
    });
  });

  describe('when mode is "DEFINITION_TO_TARGET', () => {
    beforeEach(() => {
      setMode('DEFINITION_TO_TARGET');
      wrapper = getWrapper();
    });

    it("displays flashcard's word translation in the 'flashcard-front'", () => {
      expect(
        wrapper.get('.test-flashcard-front .test-flashcard-word').text()
      ).toContain('foo definition');
    });

    it("displays flashcard's word target in the 'flashcard-back'", () => {
      expect(
        wrapper.get('.test-flashcard-back .test-flashcard-word').text()
      ).toContain('foo');
    });
  });

  describe('when mode is "TARGET_TO_DEFINITION"', () => {
    beforeEach(() => {
      setMode('TARGET_TO_DEFINITION');
      wrapper = getWrapper();
    });

    it("displays flashcard's word target in the 'flashcard-front'", () => {
      expect(
        wrapper.get('.test-flashcard-front .test-flashcard-word').text()
      ).toContain('foo');
    });

    it("displays flashcard's word definition in the 'flashcard-back'", () => {
      expect(
        wrapper.get('.test-flashcard-back .test-flashcard-word').text()
      ).toContain('foo definition');
    });
  });

  describe('when audio paths are present', () => {
    beforeEach(() => {
      hasAudio = true;
    });

    it('displays audio component if the mode is "TARGET_TO_TRANSLATION"', () => {
      setMode('TARGET_TO_TRANSLATION');
      wrapper = getWrapper();
      expect(wrapper.find('.test-flashcard-audio').exists()).toBeTruthy();
    });

    it('displays audio component if the mode "TRANSLATION_TO_TARGET"', () => {
      setMode('TRANSLATION_TO_TARGET');
      wrapper = getWrapper();
      expect(wrapper.find('.test-flashcard-audio').exists()).toBeTruthy();
    });

    it('does not display component if the mode "DEFINITION_TO_TARGET"', () => {
      setMode('DEFINITION_TO_TARGET');
      wrapper = getWrapper();
      expect(wrapper.find('.test-flashcard-audio').exists()).toBeTruthy();
    });

    it('displays audio component if the mode is "TARGET_TO_DEFINITION"', () => {
      setMode('TARGET_TO_DEFINITION');
      wrapper = getWrapper();
      expect(wrapper.find('.test-flashcard-audio').exists()).toBeTruthy();
    });
  });
});
