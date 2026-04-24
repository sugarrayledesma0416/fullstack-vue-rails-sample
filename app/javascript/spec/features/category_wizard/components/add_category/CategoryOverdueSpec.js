import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Category from 'features/category_wizard/models/category';
import CategoryOverdue from 'features/category_wizard/components/add_category/CategoryOverdue';
import CategoryValidator from 'features/category_wizard/models/category_validator';

/**
 * This method gets wrapper for CategoryOverdue component
 * @return {Wrapper}
 */
const getWrapper = () => {
  const category = reactive(new Category());
  const categoryValidator = new CategoryValidator(category);

  return mount(CategoryOverdue, {
    global: {
      provide: {
        category,
        categoryValidator,
      },
    },
  });
};

describe('CategoryOverdue', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "Students can submit overdue/late assignments for credit." as accept' +
       ' late work radio button label', () => {
      expect(wrapper.get('.test-accept-late-work-label').text()).toBe(
        'Students can submit overdue/late assignments for credit.'
      );
    });

    it('displays accept late work radio button as selected', () => {
      expect(wrapper.get('.test-accept-late-work-input').element.checked).toBeTruthy();
    });

    it('displays "Students cannot submit overdue/late assignments for credit." as do not' +
       ' accept late work radio button label', () => {
      expect(wrapper.get('.test-accept-no-late-work-label').text()).toBe(
        'Students cannot submit overdue/late assignments for credit.'
      );
    });

    it('displays do not accept late work radio button as not selected', () => {
      expect(wrapper.get('.test-accept-no-late-work-input').element.checked).toBeFalsy();
    });

    it('displays "No penalty" as do not accept late work radio button label', () => {
      expect(wrapper.get('.test-late-work-penalty-none-label').text()).toBe(
        'No penalty'
      );
    });

    it('displays no late work penalty radio button as not selected', () => {
      expect(wrapper.get('.test-late-work-penalty-none-input').element.checked).toBeFalsy();
    });

    it('displays "% per day" as percent per day penalty radio button label', () => {
      expect(wrapper.get('.test-percent-per-day-penalty-label').text()).toBe(
        '% per day'
      );
    });

    it('displays percent per day penalty radio button as selected', () => {
      expect(wrapper.get('.test-percent-per-day-penalty-input').element.checked).toBeTruthy();
    });

    it('displays "% (flat)" as flat percent penalty radio button label', () => {
      expect(wrapper.get('.test-flat-percent-penalty-label').text()).toBe(
        '% (flat)'
      );
    });

    it('displays flat percent penalty radio button as not selected', () => {
      expect(wrapper.get('.test-flat-percent-penalty-input').element.checked).toBeFalsy();
    });
  });

  describe('when do not accept late work radio button is selected', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-accept-no-late-work-input');
      await inputElm.setChecked();
    });

    it('does not display late-work-penalty section', () => {
      expect(wrapper.get('.test-late-work-penalty').isVisible()).toBeFalsy();
    });
  });

  describe('when "No penalty" radio button is selected', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-late-work-penalty-none-input');
      await inputElm.setChecked();
    });

    it('does not display penalty percent input', () => {
      expect(wrapper.get('.test-penalty-percent-input').isVisible()).toBeFalsy();
    });
  });

  describe('when penalty percent is not a number', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-penalty-percent-input');
      inputElm.setValue(' ');
    });

    it('displays error "A valid number is required."', () => {
      expect(wrapper.get('.test-penalty-percent-error').text()).toBe(
        'A valid number is required.'
      );
    });
  });
});
