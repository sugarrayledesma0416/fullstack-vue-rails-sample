import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryWeight from 'features/category_wizard/components/add_category/CategoryWeight';
import CategoryValidator from 'features/category_wizard/models/category_validator';

/**
 * This method gets wrapper for CategoryWeight component
 * @return {Wrapper}
 */
const getWrapper = () => {
  const category = reactive(new Category());
  const categoryValidator = new CategoryValidator(category);

  return mount(CategoryWeight, {
    global: {
      provide: {
        category,
        categoryValidator,
      },
    },
  });
};

describe('CategoryWeight', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays category weight label', () => {
      expect(wrapper.get('.test-category-weight-label').text()).toBe('Weight');
    });
  });

  describe('when category weight is less than 0', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-category-weight-input');
      await inputElm.setValue(-1);
    });

    it('displays error message "Category weight must be between 0 and 100"', () => {
      expect(wrapper.get('.test-category-weight-error').text()).toBe(
        'Category weight must be between 0 and 100'
      );
    });
  });

  describe('when category weight is greater than 100', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-category-weight-input');
      await inputElm.setValue(101);
    });

    it('displays error message "Category weight must be between 0 and 100"', () => {
      expect(wrapper.get('.test-category-weight-error').text()).toBe(
        'Category weight must be between 0 and 100'
      );
    });
  });
});
