import { mount } from '@vue/test-utils';
import FlashcardNumber from 'features/dictionary_flashcards/FlashcardNumber';

const flashcards = [
  { word: { target: 'foo' }},
  { word: { target: 'bar' }},
];

const getWrapper = () => {
  return mount(FlashcardNumber, {
    global: {
      provide: {
        flashcardState: {
          index: 0,
          deck: { flashcards },
        },
      },
    },
  });
};

describe('FlashcardNumber', () => {
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
});
