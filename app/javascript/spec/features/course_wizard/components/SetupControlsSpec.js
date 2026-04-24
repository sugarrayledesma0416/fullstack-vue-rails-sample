import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import SetupControls from 'features/course_wizard/components/SetupControls';

let wrapper;
let config;
let course;
let courseDataStore;
const props = {
  nextStep: 'step-3',
  previousStep: 'step-1',
  isNextDisabled: false,
  showNextBtn: true,
  showSaveBtn: false,
};

/**
 * This method gets wrapper for SetupControls component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(SetupControls, {
    props,
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}


describe('SetupControls', () => {
  describe('mounted', () => {
    beforeEach(() => {
      config = {
        instAdmin: false,
        programId: 79,
        schoolId: 100,
      };
      course = new Course();
      courseDataStore = {
        newCourseMode: true,
        store: {
          course,
        },
      };
    });
    describe('when newCourseMode is true', () => {
      beforeEach(() => {
        courseDataStore.newCourseMode = true;
        wrapper = getWrapper();
      });

      it('displays "Next" button', () => {
        expect(wrapper.get('.test-next-btn').exists()).toBeTruthy();
      });

      it('displays "Back" button', () => {
        expect(wrapper.get('.test-back-btn').exists()).toBeTruthy();
      });

      it('does not display "Save changes" button', () => {
        expect(wrapper.find('.test-save-changes').exists()).toBeFalsy();
      });

      it('displays "Cancel" button', () => {
        expect(wrapper.get('.test-cancel-btn').exists()).toBeTruthy();
      });
    });

    describe('when newCourseMode is false', () => {
      beforeEach(() => {
        courseDataStore.newCourseMode = false;
        wrapper = getWrapper();
      });

      it('does not display "Next" button', () => {
        expect(wrapper.find('.test-next-btn').exists()).toBeFalsy();
      });

      it('does not display "Back" button', () => {
        expect(wrapper.find('.test-back-btn').exists()).toBeFalsy();
      });

      it('displays "Save changes" button', () => {
        expect(wrapper.get('.test-save-changes').exists()).toBeTruthy();
      });

      it('displays "Cancel" button', () => {
        expect(wrapper.get('.test-cancel-btn').exists()).toBeTruthy();
      });
    });

    describe('when isNextDisabled is false', () => {
      beforeEach(() => {
        props.isNextDisabled = false;
        wrapper = getWrapper();
      });

      it('displays the enabled "Next" button', () => {
        expect(wrapper.get('.test-next-btn').element).not.toBeDisabled();
      });
    });

    describe('when isNextDisabled is true', () => {
      beforeEach(() => {
        props.isNextDisabled = true;
        wrapper = getWrapper();
      });

      it('displays the disabled "Next" button', () => {
        expect(wrapper.get('.test-next-btn').element).toBeDisabled();
      });
    });

    describe('when "nextStep" is empty', () => {
      beforeEach(() => {
        props.nextStep = '';
        wrapper = getWrapper();
      });

      it('does not display "Next" button', () => {
        expect(wrapper.find('.test-next-btn').exists()).toBeFalsy();
      });
    });

    describe('when nextStep is not empty', () => {
      beforeEach(() => {
        props.nextStep = 'content-step';
        wrapper = getWrapper();
      });

      it('displays the "Next" button', () => {
        expect(wrapper.find('.test-next-btn').exists()).toBeTruthy();
      });
    });

    describe('when "previousStep" is empty', () => {
      beforeEach(() => {
        props.previousStep = '';
        wrapper = getWrapper();
      });

      it('does not display "Back" button', () => {
        expect(wrapper.find('.test-back-btn').exists()).toBeFalsy();
      });
    });

    describe('when previousStep is not empty', () => {
      beforeEach(() => {
        props.previousStep = 'content-step';
        wrapper = getWrapper();
      });

      it('displays the "Back" button', () => {
        expect(wrapper.find('.test-back-btn').exists()).toBeTruthy();
      });
    });

    describe('when showSaveBtn is false', () => {
      beforeEach(() => {
        props.showSaveBtn = false;
        wrapper = getWrapper();
      });

      it('does not display "Save" button', () => {
        expect(wrapper.find('.test-save-course').exists()).toBeFalsy();
      });
    });

    describe('when showSaveBtn is true', () => {
      beforeEach(() => {
        props.showSaveBtn = true;
        wrapper = getWrapper();
      });

      it('displays the "Save" button', () => {
        expect(wrapper.find('.test-save-course').exists()).toBeTruthy();
      });
    });
  });
});
