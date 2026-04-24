import { mount } from '@vue/test-utils';
import PathSelectorStep from 'features/course_wizard/components/PathSelectorStep';

jest.mock('vue-router', () => ({
  useRouter: () => ({
    push: jest.fn(),
  }),
}));

window.scrollTo = jest.fn();

const courseDataStore = {
  returnToDashboard: jest.fn(),
  setPathAndGo: jest.fn(),
};

const getWrapper = () => {
  return mount(PathSelectorStep, {
    global: {
      provide: {
        courseDataStore,
      },
    },
  });
};

describe('PathSelectorStep', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "Course Setup" heading', () => {
      expect(wrapper.get('.test-path-step__heading').text()).toBe('Course Setup');
    });

    it('displays "Express" heading for Express Course', () => {
      const elm = wrapper.findAll('.test-path-step__path-heading')[0];
      expect(elm.text()).toBe('Express');
    });

    it('displays Express Course setup description', () => {
      const elm = wrapper.findAll('.test-path-step__course-desc')[0];
      expect(elm.exists()).toBe(true);
    });

    it('calls "setPathAndGo" with "express" on Express Course button click', async () => {
      await wrapper.get('.test-path-step__express-setup-button').trigger('click');
      expect(courseDataStore.setPathAndGo).toHaveBeenCalledWith('express');
    });

    it('displays "Custom" heading for Express Course', () => {
      const elm = wrapper.findAll('.test-path-step__path-heading')[1];
      expect(elm.text()).toBe('Custom');
    });

    it('displays Advanced Course setup description', () => {
      const elm = wrapper.findAll('.test-path-step__course-desc')[1];
      expect(elm.exists()).toBe(true);
    });

    it('calls "setPathAndGo" with "custom" on Advance Course button click', async () => {
      await wrapper.get('.test-path-step__advance-setup-button').trigger('click');
      expect(courseDataStore.setPathAndGo).toHaveBeenCalledWith('custom');
    });

    it('calls "returnToDashboard" on cancel button click', async () => {
      await wrapper.get('.test-path-step__cancel').trigger('click');
      expect(courseDataStore.returnToDashboard).toHaveBeenCalled();
    });

    it('scrolls to the top of the page', () => {
      const scrollSpy = jest.spyOn(window, 'scrollTo');
      expect(scrollSpy).toHaveBeenCalledWith(0, 0);
    });
  });
});
