import { mount } from '@vue/test-utils';
import WordTableCaption from 'features/vocab_tools/words/table/WordTableCaption';
const commmonProps = {
  elmId: 'givenId',
  isTranslationHidden: false,
  lessonName: 'lesson 1',
  tableNumber: 2,
  tableCount: 5,
  targetLanguage: 'French',
  vocabHasDefinition: true,
};

let wrapper;
const getWrapper = (propsData) => mount(WordTableCaption, { propsData });

function normalizeText(text) {
  return text.replace(/\s+/g, ' ').trim();
}

describe('WordTableCaption', () => {
  describe('when tableNumber is 2 and tableCount is 5', () => {
    describe('when isTranslationHidden is false', () => {
      beforeEach(() => {
        const props = {
          ...commmonProps,
          ...{ isTranslationHidden: false, tableNumber: 2, tableCount: 5 },
        };
        wrapper = getWrapper(props);
      });

      describe('when WordTableCaption is mounted', () => {
        it('has appropriate caption', () => {
          const captionText = 'Table 2 of total 5 word tables.' +
            ' This is a table of vocabulary words for the lesson lesson 1. ' +
            ' Each row has a column with the word in French, and a column with' +
            ' the English translation. ' +
            ' A third column contains the definition. ' +
            ' You can add your own custom words and edit any words you have created.';
          expect(normalizeText(wrapper.get('caption').text())).toEqual(normalizeText(captionText));
        });
      });
    });

    describe('when isTranslationHidden is true', () => {
      beforeEach(() => {
        const props = {
          ...commmonProps,
          ...{ isTranslationHidden: true, ssjrStudent: true, tableNumber: 2, tableCount: 5 },
        };
        wrapper = getWrapper(props);
      });

      describe('when WordTableCaption is mounted', () => {
        it('has appropriate caption', () => {
          const captionText = 'Table 2 of total 5 word tables.' +
            ' This is a table of vocabulary words for the lesson lesson 1. ' +
            ' Each row has a column with the word in French, and a column with' +
            ' the word definition. ' +
            ' You can add your own custom words and edit any words you have created.';
          expect(normalizeText(wrapper.get('caption').text())).toEqual(normalizeText(captionText));
        });
      });
    });
  });
});
