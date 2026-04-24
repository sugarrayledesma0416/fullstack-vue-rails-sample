import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryAttempts from 'features/category_wizard/components/add_category/CategoryAttempts';

/**
 * This method gets wrapper for CategoryAttempts component
 * @return {Wrapper}
 */
const getWrapper = () => {
  const category = reactive(new Category());
  return mount(CategoryAttempts, {
    global: {
      provide: {
        category,
      },
    },
  });
};

describe('CategoryAttempts', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays a link with text "(see details)"', () => {
      expect(wrapper.get('.test-show-attempts-details').text()).toBe('(see details)');
    });

    it('does not displays category attempts detail', () => {
      expect(wrapper.get('.test-attempts-details').isVisible()).toBeFalsy();
    });

    it('displays "2" as category max attempts value', () => {
      expect(wrapper.get('.test-max-attempts').element.value).toBe('2');
    });
  });

  describe('when "see details" link is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-show-attempts-details');
      await inputElm.trigger('click');
    });

    it('displays category attempts detail', () => {
      expect(wrapper.get('.test-attempts-details').isVisible()).toBeTruthy();
    });
  });
});
