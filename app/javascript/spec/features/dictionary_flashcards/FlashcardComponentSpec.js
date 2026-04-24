import { mount } from '@vue/test-utils';
import FlashcardComponent from 'features/dictionary_flashcards/FlashcardComponent';

const modes = {
  TARGET_TO_TRANSLATION: 0,
  TRANSLATION_TO_TARGET: 1,
  DEFINITION_TO_TARGET: 2,
  TARGET_TO_DEFINITION: 3,
};

const mode = 0;

const flashcards = [{
  word: {
    target: 'foo',
    definition: 'foo definition',
    translation: 'foo translation',
    audio_paths: [],
    stopPlayback: jest.fn(),
    play: jest.fn(),
    audioFiles: {
      files: [],
    },
  },
  shuffledIndex: 0,
}];

const props = { modes, mode };

const getWrapper = () => {
  return mount(FlashcardComponent, {
    global: {
      provide: {
        audioIconPath: '',
        deck: { flashcards },
        flipIconPath: '',
      },
    },
    props,
  });
};

describe('FlashcardComponent', () => {
  let wrapper;

  describe('on mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays current flashcard Number and total flashcard count', () => {
      expect(
        wrapper.get('.test-flashcard__number').text()
      ).toBe(`1 / ${flashcards.length}`);
    });
  });

  describe('when mode is "TARGET_TO_TRANSLATION"', () => {
    beforeEach(() => {
      props.mode = modes.TARGET_TO_TRANSLATION;
      wrapper = getWrapper();
    });

    it("displays flashcard's word target", () => {
      expect(wrapper.get('.test-flashcard__word').text()).toContain('foo');
    });
  });

  describe('when mode is "TRANSLATION_TO_TARGET"', () => {
    beforeEach(() => {
      props.mode = modes.TRANSLATION_TO_TARGET;
      wrapper = getWrapper();
    });

    it("displays flashcard's word translation", () => {
      expect(
        wrapper.get('.test-flashcard__word').text()
      ).toContain('foo translation');
    });
  });

  describe('when mode is "TARGET_TO_DEFINITION"', () => {
    beforeEach(() => {
      props.mode = modes.TARGET_TO_DEFINITION;
      wrapper = getWrapper();
    });

    it("displays flashcard's word target", () => {
      expect(wrapper.get('.test-flashcard__word').text()).toContain('foo');
    });
  });

  describe('when mode is "DEFINITION_TO_TARGET"', () => {
    beforeEach(() => {
      props.mode = modes.DEFINITION_TO_TARGET;
      wrapper = getWrapper();
    });

    it("displays flashcard's word translation", () => {
      expect(wrapper.get('.test-flashcard__word').text()).toContain('foo definition');
    });
  });

  describe('when audio paths are present', () => {
    beforeEach(() => {
      flashcards[0].word.audio_paths = ['1.mp3', '2.mp3'];
    });

    it('displays audio controls if the mode is "TARGET_TO_TRANSLATION",' +
       'and the front of the card is showing', () => {
      props.mode = modes.TARGET_TO_TRANSLATION;
      wrapper = getWrapper();
      expect(wrapper.find('.test-flashcard-audio-play-button').exists()).toBeTruthy();
    });

    it('displays audio controls if the mode is "TARGET_TO_TRANSLATION",' +
       'and the back of the card is showing', async () => {
      props.mode = modes.TARGET_TO_TRANSLATION;
      wrapper = getWrapper();
      await wrapper.get('.test-flashcard').trigger('click');
      expect(wrapper.find('.test-flashcard-audio-play-button').exists()).toBeTruthy();
    });

    it('does not display audio controls if the mode is 0. i.e "TRANSLATION_TO_TARGET",' +
       'and the front of the card is showing', () => {
      props.mode = modes.TRANSLATION_TO_TARGET;
      wrapper = getWrapper();
      expect(wrapper.find('.test-flashcard-audio-play-button').exists()).toBeFalsy();
    });

    it('displays audio controls if the mode is 1 i.e  "TRANSLATION_TO_TARGET",' +
       'and the back of the card is showing', async () => {
      props.mode = modes.TRANSLATION_TO_TARGET;
      wrapper = getWrapper();
      await wrapper.get('.test-flashcard').trigger('click');
      expect(wrapper.find('.test-flashcard-audio-play-button').exists()).toBeTruthy();
    });
  });

  describe('when card is flipped', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-flashcard').trigger('click');
    });

    it('displays "I KNOW IT" button', () => {
      expect(wrapper.find('.test-flashcard-knew-it').exists()).toBeTruthy();
    });

    it('displays "NOT YET" button', () => {
      expect(wrapper.find('.test-flashcard-not-yet').exists()).toBeTruthy();
    });
  });
});
