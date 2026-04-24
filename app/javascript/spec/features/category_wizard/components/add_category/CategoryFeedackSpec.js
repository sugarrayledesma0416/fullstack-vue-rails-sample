import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryFeedback from 'features/category_wizard/components/add_category/CategoryFeedback';

/**
 * This method gets wrapper for CategoryFeedback component
 * @return {Wrapper}
 */
const getWrapper = () => {
  const category = reactive(new Category());
  return mount(CategoryFeedback, {
    global: {
      provide: {
        category,
      },
    },
  });
};

describe('CategoryFeedback', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays a link with text "(see details)"', () => {
      expect(wrapper.get('.test-show-feedback-details').text()).toBe('(see details)');
    });

    it('does not displays category feedback detail', () => {
      expect(wrapper.get('.test-feedback-details').isVisible()).toBeFalsy();
    });

    it('displays "Provide students with enhanced feedback" as enhanced feedback' +
       ' enabled radio button label', () => {
      expect(wrapper.get('.test-enhanced-feedback-enabled-label').text()).toBe(
        'Provide students with enhanced feedback'
      );
    });

    it('displays enhanced feedback enable radio button as selected', () => {
      expect(wrapper.get('.test-enhanced-feedback-enabled').element.checked).toBeTruthy();
    });

    it('displays "Dont provide students with enhanced feedback" as enhanced feedback' +
       ' disabled radio button label', () => {
      expect(wrapper.get('.test-enhanced-feedback-disabled-label').text()).toBe(
        "Don't provide students with enhanced feedback"
      );
    });

    it('displays enhanced feedback disabled radio button as not selected', () => {
      expect(wrapper.get('.test-enhanced-feedback-disabled').element.checked).toBeFalsy();
    });
  });

  describe('when "see details" link is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-show-feedback-details');
      await inputElm.trigger('click');
    });

    it('displays category feedback detail', () => {
      expect(wrapper.get('.test-feedback-details').isVisible()).toBeTruthy();
    });
  });
});
