import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import HelpRequests
  from 'features/course_wizard/components/content_step/settings/HelpRequests';

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};
/**
 * This method gets wrapper for HelpRequests component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(HelpRequests, {
    global: {
      provide: { courseDataStore },
    },
  });
}

/**
 * This method returns whether the checkbox with the given css selector is checked
 * or not in the wrapper
 * @param {string} elmSelector - Css selector for checkbox
 * @return {boolean} - Whether the checkbox is checked
 */
function getCheckedState(elmSelector) {
  return wrapper.get(elmSelector).element.checked;
}

let wrapper;
describe('HelpRequests', () => {
  describe('mounted', () => {
    describe('when allowsHelpRequests is true', () => {
      beforeEach(() => {
        courseDataStore.store.course.allowsHelpRequests = true;
        wrapper = getWrapper();
      });

      it('displays the "Allow students to submit help requests" checkbox ' +
        'in checked state', () => {
        expect(getCheckedState('.test-allow-help-requests')).toBeTruthy();
      });
    });

    describe('when allowsHelpRequests is false', () => {
      beforeEach(() => {
        courseDataStore.store.course.allowsHelpRequests = false;
        wrapper = getWrapper();
      });

      it('displays the "Allow students to submit help requests" checkbox ' +
        'in unchecked state', () => {
        expect(getCheckedState('.test-allow-help-requests')).toBeFalsy();
      });
    });
  });
});
