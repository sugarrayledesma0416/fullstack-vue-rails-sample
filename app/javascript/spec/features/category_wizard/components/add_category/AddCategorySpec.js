import { mount } from '@vue/test-utils';
import AddCategory from 'features/category_wizard/components/add_category/AddCategory';

const course = {
  categories: [{ name: 'homework' }],
  updateRank: jest.fn(),
};

const config = { languageCode: 'en' };

/**
 * This method gets wrapper for AddCategory component
 * @return {VueWrapper}
 */
const getWrapper = () => {
  return mount(AddCategory, {
    global: {
      provide: {
        courseDataStore: {
          store: {
            course,
          },
        },
        config,
      },
      stubs: {
        CategoryName: true,
      },
    },
  });
};

function onlyStepDisplayed(wrapper, components, name) {
  const existingComponents = components.filter((component) => {
    return wrapper.findComponent({ name: component }).exists();
  });

  return existingComponents.length === 1 && existingComponents[0] === name;
}

const categoryStepComponents = [
  'CategoryAttempts',
  'CategoryGrading',
  'CategoryFeedback',
  'CategoryName',
  'CategoryOverdue',
  'CategoryStrictness',
  'CategoryWeight',
];

describe('AddCategory', () => {
  let wrapper;

  describe('when currentStep is 0', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('does not displays category steps components except "CategoryName"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryName')
      ).toBeTruthy();
    });

    it('does not display "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeFalsy();
    });

    it('displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeTruthy();
    });
  });

  describe('when currentStep is 1', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 1;
      await wrapper.vm.$nextTick();
    });

    it('does not displays category steps components except "CategoryWeight"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryWeight')
      ).toBeTruthy();
    });

    it('displays "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeTruthy();
    });

    it('displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeTruthy();
    });
  });

  describe('when currentStep is 2', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 2;
      await wrapper.vm.$nextTick();
    });

    it('does not displays category steps components except "CategoryGrading"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryGrading')
      ).toBeTruthy();
    });

    it('displays "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeTruthy();
    });

    it('displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeTruthy();
    });
  });

  describe('when currentStep is 3', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 3;
      await wrapper.vm.$nextTick();
    });

    it('does not displays category steps components except "CategoryAttempts"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryAttempts')
      ).toBeTruthy();
    });

    it('displays "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeTruthy();
    });

    it('displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeTruthy();
    });
  });

  describe('when currentStep is 4', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 4;
      await wrapper.vm.$nextTick();
    });

    it('does not displays category steps components except "CategoryStrictness"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryStrictness')
      ).toBeTruthy();
    });

    it('displays "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeTruthy();
    });

    it('displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeTruthy();
    });
  });

  describe('when currentStep is 5', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 5;
      await wrapper.vm.$nextTick();
    });

    it('does not displays category steps components except "CategoryFeedback"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryFeedback')
      ).toBeTruthy();
    });

    it('displays "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeTruthy();
    });

    it('displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeTruthy();
    });
  });

  describe('when currentStep is 6', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 6;
      await wrapper.vm.$nextTick();
    });

    it('does not displays category steps components except "CategoryOverdue"', () => {
      expect(
        onlyStepDisplayed(wrapper, categoryStepComponents, 'CategoryOverdue')
      ).toBeTruthy();
    });

    it('displays "Back" button', () => {
      expect(wrapper.find('.test-category-back-button').exists()).toBeTruthy();
    });

    it('does not displays "Next" button', () => {
      expect(wrapper.find('.test-category-next-button').exists()).toBeFalsy();
    });

    it('displays "Save" button', () => {
      expect(wrapper.find('.test-category-save-button').exists()).toBeTruthy();
    });
  });

  describe('when back is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 3;
      await wrapper.vm.$nextTick();
      const inputElm = wrapper.get('.test-category-back-button');
      await inputElm.trigger('click');
    });

    it('moves to previous step', () => {
      expect(wrapper.vm.currentStep).toBe(2);
    });
  });

  describe('when next is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 3;
      await wrapper.vm.$nextTick();
      const inputElm = wrapper.get('.test-category-next-button');
      await inputElm.trigger('click');
    });

    it('moves to next step', () => {
      expect(wrapper.vm.currentStep).toBe(4);
    });
  });

  describe('when cancel is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-category-cancel-link');
      await inputElm.trigger('click');
    });

    it('emits "closeAdd" event', () => {
      expect(wrapper.emitted().closeAdd).toBeTruthy();
    });
  });

  describe('when save is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.currentStep = 6;
      await wrapper.vm.$nextTick();
      const inputElm = wrapper.get('.test-category-save-button');
      await inputElm.trigger('click');
    });

    it('calls "updateRank" function', () => {
      expect(course.updateRank).toHaveBeenCalled();
    });
  });
});
