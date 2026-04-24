import { mount } from '@vue/test-utils';
import CommonHeader from 'features/vocab_tools/words/table/CommonHeader';
const commmonProps = {
  isTranslationHidden: false,
  targetLanguage: 'French',
  totalColumns: 4,
  vocabHasDefinition: true,
};

let wrapper;
const getWrapper = (propsData) => mount(CommonHeader, { propsData });

describe('CommonHeader', () => {
  beforeEach(() => {
    wrapper = getWrapper(commmonProps);
  });

  describe('when CommonHeader is mounted', () => {
    it('displays 1 "ColumnsLayout" component', () => {
      expect(wrapper.findAllComponents({ name: 'ColumnsLayout' })).toHaveLength(1);
    });

    it('displays 1 "HeaderRow" component', () => {
      expect(wrapper.findAllComponents({ name: 'HeaderRow' })).toHaveLength(1);
    });
  });
});
