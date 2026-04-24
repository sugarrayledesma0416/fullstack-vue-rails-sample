import { shallowMount } from '@vue/test-utils';
import FlashcardAudio from 'features/dictionary_flashcards/FlashcardAudio';

const flashcard = {
  play: jest.fn(),
};

const getWrapper = () => {
  return shallowMount(FlashcardAudio, {
    global: {
      provide: {
        audioIconPath: '',
        flashcard,
        flashcardState: {
          ssjrStudent: false,
        },
        audioIconElm: {},
      },
    },
  });
};

describe('FlashcardAudio', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
    });

    it('displays audio play button', () => {
      expect(wrapper.find('.test-flashcard-audio-play-button').exists()).toBeTruthy();
    });
  });

  describe('when play button is clicked', () => {
    beforeEach(async () => {
      spyOn(flashcard, 'play');
      wrapper = getWrapper();
      await wrapper.get('.test-flashcard-audio-play-button').trigger('click');
    });

    it('plays the card audio', () => {
      expect(flashcard.play).toHaveBeenCalled();
    });
  });
});
