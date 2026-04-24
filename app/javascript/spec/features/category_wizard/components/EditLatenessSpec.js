import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import CategoryValidator from 'features/category_wizard/models/category_validator';
import EditLateness from 'features/category_wizard/components/EditLateness';

/**
 * @typeDef CategoryObject
 * @property {boolean} acceptLateWork
 * @property {string} lateWorkPenalty
 * @property {number} penaltyPercent
 */

const category = reactive({
  acceptLateWork: true,
  lateWorkPenalty: 'percent_per_day',
  penaltyPercent: 5,
});
const categoryValidator = new CategoryValidator(category);

/**
 * This method gets wrapper for Category component
 * @param {CategoryObject} category - vue provide object required for Category component
 * @return {Wrapper}
 */
function getWrapper(category) {
  return mount(EditLateness, {
    global: { provide: { category, categoryValidator }},
  });
}

describe('EditLateness Component', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(category);
    });

    it('displays accept late work category.', () => {
      expect(
        wrapper.get('.test-accept-late-work-category').text()
      ).toBe('Choose whether to accept late work in this category:');
    });

    it('displays accept late work radio button as checked', () => {
      expect(
        wrapper.find('.test-accept-late-work').element.checked
      ).toBeTruthy();
    });

    it('displays do not accept late work radio button as unchecked', () => {
      expect(
        wrapper.find('.test-accept-no-late-work').element.checked
      ).toBeFalsy();
    });

    it('displays penalty percent category.', () => {
      expect(
        wrapper.get('.test-late-work-penalty-category').text()
      ).toContain('How should overdue submissions be penalized:');
    });

    it('displays late work penalty none radio button as unchecked', () => {
      expect(
        wrapper.find('.test-late-work-penalty-none').element.checked
      ).toBeFalsy();
    });

    it('displays late work penalty day radio button as unchecked', () => {
      expect(
        wrapper.find('.test-late-work-penalty-day').element.checked
      ).toBeTruthy();
    });

    it('displays late work penalty flat radio button as unchecked', () => {
      expect(
        wrapper.find('.test-late-work-penalty-flat').element.checked
      ).toBeFalsy();
    });
  });

  describe('latework is not accepted', () => {
    beforeEach(() => {
      category.acceptLateWork = false;
      wrapper = getWrapper(category);
    });

    it('does not display late work penalty section', () => {
      expect(wrapper.find('.test-late-work-penalty-category').exists()).toBeFalsy();
    });
  });

  describe('late work penalty is selected as none', () => {
    beforeEach(() => {
      category.lateWorkPenalty = 'none';
      wrapper = getWrapper(category);
    });

    it('does not display penalty percentage detail section', () => {
      expect(wrapper.find('.test-penalty-percent-detail').exists()).toBeFalsy();
    });
  });
});
