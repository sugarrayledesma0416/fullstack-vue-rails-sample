import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import GoogleClassroom
  from 'features/course_wizard/components/content_step/settings/GoogleClassroom';

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};

/**
 * This method gets wrapper for GoogleClassroom component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(GoogleClassroom, {
    global: {
      provide: { courseDataStore },
    },
  });
}

let wrapper;
describe('GoogleClassroom', () => {
  describe('mounted', () => {
    describe('when shareToGoogleClassroom is true', () => {
      beforeEach(() => {
        courseDataStore.store.course.shareToGoogleClassroom = true;
        wrapper = getWrapper();
      });

      it('displays "Google Share Enabled" setting in checked state', () => {
        expect(wrapper.get('.test-google-classroom-input').element.checked).toBeTruthy();
      });
    });

    describe('when shareToGoogleClassroom is false', () => {
      beforeEach(() => {
        courseDataStore.store.course.shareToGoogleClassroom = false;
        wrapper = getWrapper();
      });

      it('displays "Google Share Enabled" setting in unchecked state', () => {
        expect(wrapper.get('.test-google-classroom-input').element.checked).toBeFalsy();
      });
    });
  });
});
