import { mount } from '@vue/test-utils';
import ColumnsLayout from 'features/vocab_tools/words/table/ColumnsLayout';

let wrapper;
const getWrapper = (propsData) => mount(ColumnsLayout, { propsData });

describe('ColumnsLayout', () => {
  describe('when totalColumns is 3', () => {
    beforeEach(() => {
      const props = { totalColumns: 3 };
      wrapper = getWrapper(props);
    });

    describe('when ColumnsLayout is mounted', () => {
      it('has 3 "col" elements with class "c-vocab-tools-3-cols"', () => {
        expect(wrapper.findAll('col.c-vocab-tools-3-cols')).toHaveLength(3);
      });
    });
  });

  describe('when totalColumns is 4', () => {
    beforeEach(() => {
      const props = { totalColumns: 4 };
      wrapper = getWrapper(props);
    });

    describe('when ColumnsLayout is mounted', () => {
      it('has 4 "col" elements with class "c-vocab-tools-4-cols"', () => {
        expect(wrapper.findAll('col.c-vocab-tools-4-cols')).toHaveLength(4);
      });
    });
  });
});
