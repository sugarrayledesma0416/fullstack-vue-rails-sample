import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import EstimatedTime
  from 'features/course_wizard/components/content_step/settings/EstimatedTime';

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};

/**
 * This method gets wrapper for EstimatedTime component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(EstimatedTime, {
    global: {
      provide: { courseDataStore },
    },
  });
}

let wrapper;
describe('EstimatedTime', () => {
  describe('mounted', () => {
    describe('when showEstimatedTimes is true', () => {
      beforeEach(() => {
        courseDataStore.store.course.showEstimatedTimes = true;
        wrapper = getWrapper();
      });

      it('displays checkbox for allowing students to see estimated times in checked state', () => {
        const checkbox = wrapper.get('.test-estimated-times');
        expect(checkbox.element.checked).toBeTruthy();
      });
    });

    describe('when showEstimatedTimes is false', () => {
      beforeEach(() => {
        courseDataStore.store.course.showEstimatedTimes = false;
        wrapper = getWrapper();
      });

      it('displays checkbox for allowing students to see estimated times in checked state', () => {
        const checkbox = wrapper.get('.test-estimated-times');
        expect(checkbox.element.checked).toBeFalsy();
      });
    });
  });
});
