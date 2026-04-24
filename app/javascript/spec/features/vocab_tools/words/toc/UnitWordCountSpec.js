import { mount } from '@vue/test-utils';
import UnitWordCount from 'features/vocab_tools/words/toc/UnitWordCount';

jest.mock('features/vocab_tools/words/toc/use_word_counting', () => {
  return jest.fn().mockImplementation(() => {
    return {
      unitSelectedWordsCount: jest.fn((unit) => 8),
      unitWordCount: jest.fn((unit) => 10),
    };
  });
});

const commonProps = { unit: {}};

describe('UnitWordCount', () => {
  let wrapper;
  const getWrapper = (propsData) => mount(UnitWordCount, { propsData });

  describe('when UnitWordCount is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(commonProps);
    });

    it('displays selected word count info "8 out of 10" for unit', () => {
      expect(wrapper.get('.test-unit-word-count-info').text()).toBe('8/10');
    });
  });
});
