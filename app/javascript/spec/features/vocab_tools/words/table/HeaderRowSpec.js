import { mount } from '@vue/test-utils';
import HeaderRow from 'features/vocab_tools/words/table/HeaderRow';

let wrapper;
const getWrapper = (propsData) => mount(HeaderRow, { propsData });

describe('HeaderRow', () => {
  describe('when isTranslationHidden is true', () => {
    beforeEach(() => {
      const props = {
        isTranslationHidden: true,
        targetLanguage: 'English',
        vocabHasDefinition: true,
      };
      wrapper = getWrapper(props);
    });

    describe('when HeaderRow is mounted', () => {
      it('displays column "English" for target language', () => {
        expect(wrapper.get('.test-vocab-target-language').text()).toBe('English');
      });

      it('does not display translation column', () => {
        expect(wrapper.find('.test-vocab-translation-language').exists()).toBeFalsy();
      });

      it('displays definition column Labeled "Notes"', () => {
        expect(wrapper.get('.test-vocab-th-definition').text()).toBe('Notes');
      });
    });
  });

  describe('when isTranslationHidden is false', () => {
    describe('when vocabHasDefinition is true', () => {
      beforeEach(() => {
        const props = {
          isTranslationHidden: false,
          targetLanguage: 'French',
          vocabHasDefinition: true,
        };
        wrapper = getWrapper(props);
      });

      describe('when HeaderRow is mounted', () => {
        it('displays column "French" for target language', () => {
          expect(wrapper.get('.test-vocab-target-language').text()).toBe('French');
        });

        it('displays translation column Labeled "English"', () => {
          expect(wrapper.get('.test-vocab-translation-language').text()).toBe('English');
        });

        it('displays column "Definition"', () => {
          expect(wrapper.get('.test-vocab-th-definition').text()).toBe('Definition');
        });
      });
    });

    describe('when vocabHasDefinition is false', () => {
      beforeEach(() => {
        const props = {
          isTranslationHidden: false,
          targetLanguage: 'French',
          vocabHasDefinition: false,
        };
        wrapper = getWrapper(props);
      });

      describe('when HeaderRow is mounted', () => {
        it('displays column "French" for target language', () => {
          expect(wrapper.get('.test-vocab-target-language').text()).toBe('French');
        });

        it('displays translation column Labeled "English"', () => {
          expect(wrapper.get('.test-vocab-translation-language').text()).toBe('English');
        });

        it('does not display column "Definition"', () => {
          expect(wrapper.find('.test-vocab-th-definition').exists()).toBeFalsy();
        });
      });
    });
  });
});
