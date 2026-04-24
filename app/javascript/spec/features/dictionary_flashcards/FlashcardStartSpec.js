import { mount } from '@vue/test-utils';
import FlashcardStart from 'features/dictionary_flashcards/FlashcardStart';

const props = {
  ssjrStudent: false,
  studyOptions: {
    modes: {
      TARGET_TO_TRANSLATION: 0,
      TRANSLATION_TO_TARGET: 1,
    },
    mode: 0,
  },
};

describe('FlashcardStart', () => {
  let wrapper;

  const deck = { flashcards: [] };

  const getWrapper = () => {
    return mount(FlashcardStart, {
      global: {
        provide: {
          startIconPath: '',
        },
      },
      props,
    });
  }

  describe('on mounted', () => {
    it('displays start activity button', () => {
      wrapper = getWrapper();
      expect(wrapper.find('.test-start-activity').exists()).toBeTruthy();
    });

    it('displays study mode select button', () => {
      wrapper = getWrapper();
      expect(wrapper.find('.test-study-mode-select').exists()).toBeTruthy();
    });
  });

  describe('on Start Activity click', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-start-activity').trigger('click');
    });

    it('emits "startActivity" event', async () => {
      await wrapper.find('.test-start-activity').trigger('click');
      expect(wrapper.emitted().startActivity).toBeTruthy();
    });
  });
});
