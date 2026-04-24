import { shallowMount } from '@vue/test-utils';
import FlashcardFront from 'features/dictionary_flashcards/FlashcardFront';
import FlashcardAudio from 'features/dictionary_flashcards/FlashcardAudio';

const word = {
  target: 'foo',
  definition: 'foo definition',
  translation: 'foo translation',
  audio_paths: [],
};

const flashcard = {
  isSourceLangTarget: true,
  isModeTranslationToTarget: false,
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
  return shallowMount(FlashcardFront, {
    global: {
      provide: {
        flashcard,
        flashcardState,
        flipIconPath: '',
        hasAudio,
      },
    },
  });
};

const setMode = (mode) => {
  flashcard.isSourceLangTarget = ['TARGET_TO_TRANSLATION', 'TARGET_TO_DEFINITION'].includes(mode);
  flashcard.isModeTranslationToTarget = mode === 'TRANSLATION_TO_TARGET';
  flashcard.isModeDefinitionToTarget = mode === 'DEFINITION_TO_TARGET';
};

describe('FlashcardFront', () => {
  let wrapper;

  describe('when mode is "TARGET_TO_TRANSLATION"', () => {
    beforeEach(() => {
      setMode('TARGET_TO_TRANSLATION');
      wrapper = getWrapper();
    });

    it("displays flashcard's word target", () => {
      expect(wrapper.get('.test-flashcard__word').text()).toContain('foo');
    });
  });

  describe('when mode is "TRANSLATION_TO_TARGET"', () => {
    beforeEach(() => {
      setMode('TRANSLATION_TO_TARGET');
      wrapper = getWrapper();
    });

    it("displays flashcard's word translation", () => {
      expect(
        wrapper.get('.test-flashcard__word').text()
      ).toContain('foo translation');
    });
  });

  describe('when mode is "DEFINITION_TO_TARGET', () => {
    beforeEach(() => {
      setMode('DEFINITION_TO_TARGET');
      wrapper = getWrapper();
    });

    it("displays flashcard's word translation", () => {
      expect(wrapper.get('.test-flashcard__word').text()).toContain('foo definition');
    });
  });

  describe('when mode is "TARGET_TO_DEFINITION"', () => {
    beforeEach(() => {
      setMode('TARGET_TO_DEFINITION');
      wrapper = getWrapper();
    });

    it("displays flashcard's word target", () => {
      expect(wrapper.get('.test-flashcard__word').text()).toContain('foo');
    });
  });

  describe('when audio paths are present', () => {
    beforeEach(() => {
      hasAudio = true;
    });

    it('displays audio component if the mode is "TARGET_TO_TRANSLATION"', () => {
      setMode('TARGET_TO_TRANSLATION');
      wrapper = getWrapper();
      expect(wrapper.findComponent(FlashcardAudio).exists()).toBeTruthy();
    });

    it('does not display component if the mode "TRANSLATION_TO_TARGET"', () => {
      setMode('TRANSLATION_TO_TARGET');
      wrapper = getWrapper();
      expect(wrapper.findComponent(FlashcardAudio).exists()).toBeFalsy();
    });

    it('does not display component if the mode "DEFINITION_TO_TARGET"', () => {
      setMode('DEFINITION_TO_TARGET');
      wrapper = getWrapper();
      expect(wrapper.findComponent(FlashcardAudio).exists()).toBeFalsy();
    });

    it('displays audio component if the mode is "TARGET_TO_DEFINITION"', () => {
      setMode('TARGET_TO_DEFINITION');
      wrapper = getWrapper();
      expect(wrapper.findComponent(FlashcardAudio).exists()).toBeTruthy();
    });
  });
});
