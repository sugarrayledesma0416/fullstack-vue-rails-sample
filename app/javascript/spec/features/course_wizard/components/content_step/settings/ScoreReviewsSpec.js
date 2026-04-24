import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import ScoreReviews
  from 'features/course_wizard/components/content_step/settings/ScoreReviews';

const course = new Course();
const courseDataStore = {
  newCourseMode: true,
  store: reactive({
    course,
  }),
};
/**
 * This method gets wrapper for ScoreReviews component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(ScoreReviews, {
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
describe('ScoreReviews', () => {
  describe('mounted', () => {
    describe('when allowsReviewRequests is true', () => {
      beforeEach(() => {
        courseDataStore.store.course.allowsReviewRequests = true;
        wrapper = getWrapper();
      });

      it('displays the "Allow students to submit score reviews" checkbox ' +
        'in checked state', () => {
        expect(getCheckedState('.test-allow-review-requests')).toBeTruthy();
      });
    });

    describe('when allowsReviewRequests is false', () => {
      beforeEach(() => {
        courseDataStore.store.course.allowsReviewRequests = false;
        wrapper = getWrapper();
      });
      it('displays the "Allow students to submit score reviews" checkbox ' +
        'in unchecked state', () => {
        expect(getCheckedState('.test-allow-review-requests')).toBeFalsy();
      });
    });
  });
});
