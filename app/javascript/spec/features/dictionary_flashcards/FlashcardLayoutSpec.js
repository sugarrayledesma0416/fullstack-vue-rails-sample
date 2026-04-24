import { mount } from '@vue/test-utils';
import FlashcardLayout from 'features/dictionary_flashcards/FlashcardLayout';

const props = {
  vocabHasDefinition: false,
  targetLanguage: 'Spanish',
  isTranslationHidden: false,
  ssjrStudent: false,
};

describe('FlashcardLayout', () => {
  let wrapper;

  const deck = { flashcards: [] };

  function getWrapper() {
    return mount(FlashcardLayout, {
      global: {
        provide: {
          deck,
          magnifyingGlassIconPath: '',
          startIconPath: '',
        },
        stubs: {
          FlashcardComponent: {
            template: '<div></div>',
          },
          NoWordSelected: {
            template: '<div></div>',
          },
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

  describe('when isTranslationHidden is false', () => {
    it('displays expected two study mode options if program does not include definition field', () => {
      props.vocabHasDefinition = false;
      wrapper = getWrapper();
      const options = wrapper.findAll('option');
      expect(options.length).toEqual(2);

      const studyModeOption1 = options[0];
      expect(studyModeOption1.attributes('value')).toEqual('0');
      expect(studyModeOption1.text()).toEqual('Spanish to English');

      const studyModeOption2 = options[1];
      expect(studyModeOption2.attributes('value')).toEqual('1');
      expect(studyModeOption2.text()).toEqual('English to Spanish');
    });

    it('displays expected three study mode options if program includes definition field', () => {
      props.vocabHasDefinition = true;
      wrapper = getWrapper();
      const options = wrapper.findAll('option');
      expect(options.length).toEqual(3);

      const studyModeOption1 = options[0];
      expect(studyModeOption1.attributes('value')).toEqual('0');
      expect(studyModeOption1.text()).toEqual('Spanish to English');

      const studyModeOption2 = options[1];
      expect(studyModeOption2.attributes('value')).toEqual('1');
      expect(studyModeOption2.text()).toEqual('English to Spanish');

      const studyModeOption3 = options[2];
      expect(studyModeOption3.attributes('value')).toEqual('2');
      expect(studyModeOption3.text()).toEqual('Definition to Spanish');
    });
  });

  describe('when isTranslationHidden is true', () => {
    it('displays expected English and Notes study mode options', () => {
      props.isTranslationHidden = true;
      props.targetLanguage = 'English';
      wrapper = getWrapper();
      const options = wrapper.findAll('option');
      expect(options.length).toEqual(2);

      const studyModeOption1 = options[0];
      expect(studyModeOption1.attributes('value')).toEqual('0');
      expect(studyModeOption1.text()).toEqual('English to Notes');

      const studyModeOption2 = options[1];
      expect(studyModeOption2.attributes('value')).toEqual('1');
      expect(studyModeOption2.text()).toEqual('Notes to English');
    });
  });


  describe('on Start Activity click', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-start-activity').trigger('click');
    });

    it('does not display start activity button', () => {
      expect(wrapper.find('.test-start-activity').exists()).toBeFalsy();
    });

    it('does not display study mode select button', () => {
      expect(wrapper.find('.test-study-mode-select').exists()).toBeFalsy();
    });

    it('displays message "Select a lesson or topic to see flashcards.", if no flashcard present', () => {
      expect(
        wrapper.get('.test-no-flashcard').text()
      ).toBe('Select a lesson or topic to see flashcards.');
    });
  });

  describe('when flashcard is present', () => {
    beforeEach(() => {
      deck.flashcards = [{ word: { target: 'foo' }}];
      wrapper = getWrapper();
    });

    it('displays flashcard on start activity button click', async () => {
      await wrapper.get('.test-start-activity').trigger('click');
      expect(wrapper.find('.test-flashcard-component').exists()).toBeTruthy();
    });
  });


  describe('when flashcard is not present', () => {
    describe('when ssjrStudent is false', () => {
      beforeEach(() => {
        deck.flashcards = [];
        wrapper = getWrapper();
      });

      it('displays text "Select a lesson or topic to see flashcards."', async () => {
        await wrapper.get('.test-start-activity').trigger('click');
        expect(wrapper.get('.test-no-flashcard').text()).toBe(
          'Select a lesson or topic to see flashcards.'
        );
      });
    });

    describe('when ssjrStudent is true', () => {
      beforeEach(() => {
        props.ssjrStudent = true;
        deck.flashcards = [];
        wrapper = getWrapper();
      });

      it('displays "NoWordSelected" component', async () => {
        await wrapper.get('.test-start-activity').trigger('click');
        expect(
          wrapper.find('.test-no-word-selected').exists()
        ).toBeTruthy();
      });
    });
  });
});
