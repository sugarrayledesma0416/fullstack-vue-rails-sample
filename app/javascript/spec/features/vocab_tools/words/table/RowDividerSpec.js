import { mount } from '@vue/test-utils';
import RowDivider from 'features/vocab_tools/words/table/RowDivider';

let wrapper;
const getWrapper = (propsData) => mount(RowDivider, { propsData });

describe('RowDivider', () => {
  beforeEach(() => {
    const props = { colspan: 4 };
    wrapper = getWrapper(props);
  });

  describe('when RowDivider is mounted', () => {
    it('has row with colspan 4', () => {
      expect(wrapper.get('.test-td-divider').attributes('colspan')).toBe('4');
    });
  });
});
