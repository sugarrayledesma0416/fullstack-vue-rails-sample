import { mount } from '@vue/test-utils';
import FlashcardReview from 'features/dictionary_flashcards/FlashcardReview';
import Deck from 'models/vocab_tools/deck';

VHL = { Audio: {}};

VHL.Audio.CollectionScheduler = class CollectionScheduler {
  constructor() {
    this.files = [];
  }
};

describe('FlashcardReview', () => {
  let wrapper;

  const words = [
    { target: 'foo' },
    { target: 'bar' },
    { target: 'baz' },
  ];

  const units = [{
    name: 'Unit 1',
    lessons: [
      {
        displayName: 'Leçon 1A',
        topics: [
          {
            selected: true,
            words,
          },
        ],
      },
    ],
    selectedWords: () => {
      return words;
    },
  }];

  const flashcard = {
    review: jest.fn(),
  };

  const deck = new Deck(units, 'units');

  function getWrapper() {
    return mount(FlashcardReview, {
      global: {
        provide: {
          flashcard,
          flashcardState: { deck },
        },
      },
    });
  }

  describe('when user knows all answers', () => {
    beforeEach(() => {
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = true;
      });
      wrapper = getWrapper();
    });

    it('displays success message', () => {
      expect(
        wrapper.get('.test-knew-it-message').text()
      ).toBe('You knew all 3 words!');
    });

    it('displays "Review all words" link', () => {
      expect(wrapper.find('.test-review-all-words').exists()).toBeTruthy();
    });

    it('does not display "Review words you dont know yet" link', () => {
      expect(wrapper.find('.test-review-dont-know-words').exists()).toBeFalsy();
    });
  });

  describe('when user knows some answers', () => {
    beforeEach(() => {
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
      wrapper = getWrapper();
    });

    it('displays success message', () => {
      expect(wrapper.get('.test-knew-it-message').text()).toBe('You got 2 out of 3.');
    });

    it('displays "Review all words" link', () => {
      expect(wrapper.find('.test-review-all-words').exists()).toBeTruthy();
    });

    it('displays "Review words you dont know yet" link', () => {
      expect(wrapper.find('.test-review-dont-know-words').exists()).toBeTruthy();
    });
  });

  describe('when "Review all words" link is clicked', () => {
    beforeEach( async () => {
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
      spyOn(flashcard, 'review');
      wrapper = getWrapper();
      await wrapper.get('.test-review-all-words').trigger('click');
    });

    it('makes call to "review" method with with value "true"', () => {
      expect(flashcard.review).toHaveBeenCalledWith(true);
    });
  });

  describe('when "Review words you dont know yet" link is clicked', () => {
    beforeEach( async () => {
      deck.flashcards.forEach((flashcard) => {
        flashcard.knewIt = flashcard.word.target !== 'baz';
      });
      spyOn(flashcard, 'review');
      wrapper = getWrapper();
      await wrapper.get('.test-review-dont-know-words').trigger('click');
    });

    it('makes call to "review" method with with value "false"', () => {
      expect(flashcard.review).toHaveBeenCalledWith(false);
    });
  });
});
