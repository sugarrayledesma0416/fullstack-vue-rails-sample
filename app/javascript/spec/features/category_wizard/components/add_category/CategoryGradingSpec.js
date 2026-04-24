import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryGrading from 'features/category_wizard/components/add_category/CategoryGrading';

/**
 * This method gets wrapper for CategoryGrading component
 * @return {Wrapper}
 */
const getWrapper = () => {
  const category = reactive(new Category());
  return mount(CategoryGrading, {
    global: {
      provide: {
        category,
      },
    },
  });
};

describe('CategoryGrading', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "For a grade" radio button label', () => {
      expect(wrapper.get('.test-for-a-grade-label').text()).toBe('For a grade');
    });

    it('displays "For a grade" radio button selected', () => {
      expect(wrapper.get('.test-new-for-a-grade').element.checked).toBeTruthy();
    });

    it('displays "Credit/no credit" radio button label', () => {
      expect(wrapper.get('.test-credit-only-label').text()).toBe('Credit/no credit');
    });

    it('displays "Credit/no credit" radio button not selected', () => {
      expect(wrapper.get('.test-new-credit-only').element.checked).toBeFalsy();
    });

    it('displays "Number of lowest grades dropped:" label', () => {
      expect(
        wrapper.get('.test-drop-low-scores-label').text()
      ).toBe('Number of lowest grades dropped:');
    });

    it('displays "0" as category drop low score value', () => {
      expect(wrapper.get('.test-drop-low-scores').element.value).toBe('0');
    });
  });
});
