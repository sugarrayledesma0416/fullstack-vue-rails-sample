import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryName from 'features/category_wizard/components/add_category/CategoryName';
import CategoryValidator from 'features/category_wizard/models/category_validator';

/**
 * This method gets wrapper for CategoryName component
 * @return {Wrapper}
 */
const getWrapper = () => {
  const category = reactive(new Category());
  const categoryValidator = new CategoryValidator(category);

  return mount(CategoryName, {
    props: {
      course: {
        categories: [{ name: 'homework' }],
      },
    },
    global: {
      provide: {
        category,
        categoryValidator,
      },
    },
  });
};

describe('CategoryName', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays category name label', () => {
      expect(wrapper.get('.test-category-name-label').text()).toBe('Name');
    });
  });

  describe('when category name is empty', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-category-name-input');
      await inputElm.setValue('some value');
      await inputElm.setValue('');
    });

    it('displays error message "This is a required field"', () => {
      expect(wrapper.get('.test-category-name-error').text()).toBe('This is a required field');
    });
  });

  describe('when category name is already used', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-category-name-input');
      await inputElm.setValue('homework');
    });

    it('displays error message "This category name is already in use"', () => {
      expect(wrapper.get('.test-category-name-error').text()).toBe(
        'This category name is already in use'
      );
    });
  });
});
