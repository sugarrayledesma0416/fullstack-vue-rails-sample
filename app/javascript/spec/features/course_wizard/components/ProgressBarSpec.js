import { mount } from '@vue/test-utils';
import ProgressBar from 'features/course_wizard/components/ProgressBar';

/**
 * @typeDef ProgressBarPropsObjectType
 * @property {string} currentStepId - Current active step id
 * @property {boolean} isVol - Whether vista online learning is true
 * @property {string} mode - Progress bar mode
 * @property {string} pathType - Path type
 */

const propsData = {
  currentStepId: '',
  isVol: false,
  pathType: 'express',
};

let wrapper;

/**
 * This method gets wrapper for ProgressBar component
 * @param {ProgressBarPropsObjectType} propsData
 * @return {Wrapper}
 */
const getWrapper = (propsData) => {
  return mount(ProgressBar, {
    propsData,
  });
};

describe('ProgressBar', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsData);
    });

    it('displays title text', () => {
      expect(wrapper.get('.test-progress-bar-title').text()).toBe('addcourse');
    });

    it('displays the progress bar steps', () => {
      expect(wrapper.find('.test-progress-bar-steps').exists()).toBeTruthy();
    });

    it('displays 3 steps in the progress bar', () => {
      expect(wrapper.findAll('.test-progress-step-name').length).toBe(3);
    });

    it('displays first step with title "Setup"', () => {
      const stepElms = wrapper.findAll('.test-progress-step-name');
      expect(stepElms[0].text()).toBe('Setup');
    });

    it('displays second step with title "Details"', () => {
      const stepElms = wrapper.findAll('.test-progress-step-name');
      expect(stepElms[1].text()).toBe('Details');
    });

    it('displays third step with title "Assignments"', () => {
      const stepElms = wrapper.findAll('.test-progress-step-name');
      expect(stepElms[2].text()).toBe('Assignments');
    });
  });

  describe('when "isVol" prop value is true', () => {
    beforeEach(() => {
      const props = { ...propsData, ...{ isVol: true }};
      wrapper = getWrapper(props);
    });

    it('adds variant css class "progress-bar--vol"', () => {
      expect(wrapper.classes('progress-bar--vol')).toBeTruthy();
    });
  });

  describe('when "pathType" prop value is "custom"', () => {
    beforeEach(() => {
      const props = { ...propsData, ...{ pathType: 'custom' }};
      wrapper = getWrapper(props);
    });

    it('adds variant css class "progress-bar--custom-setup"', () => {
      expect(wrapper.classes('progress-bar--custom-setup')).toBeTruthy();
    });
  });

  describe('when "currentStepId" prop value is "express-course-step"', () => {
    beforeEach(() => {
      const props = { ...propsData, ...{ currentStepId: 'express-course-step' }};
      wrapper = getWrapper(props);
    });

    it('does not add css class "is-current" on non active step', () => {
      const stepElms = wrapper.findAll('.test-progress-step-list-item');
      expect(stepElms[2].classes('is-current')).toBeFalsy();
    });

    it('adds css class "is-active" on active step', () => {
      const stepElms = wrapper.findAll('.test-progress-step-list-item');
      expect(stepElms[1].classes('is-current')).toBeTruthy();
    });
  });

  describe('when "currentStepId" prop value is "path-selector-step"', () => {
    beforeEach(() => {
      const props = { ...propsData, ...{ currentStepId: 'path-selector-step' }};
      wrapper = getWrapper(props);
    });

    it('hides the progress bar steps', () => {
      expect(wrapper.find('.test-progress-bar-steps').exists()).toBeFalsy();
    });
  });
});
