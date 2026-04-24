import { reactive } from 'vue';
import CourseFormState from 'features/course_wizard/models/course_form_state';

const today = new Date();

let courseFormState;
let store;
describe('CourseFormState', () => {
  beforeEach(async () => {
    store = reactive({
      course: {
        name: 'test course name',
        startDate: today,
        endDate: today,
        sections: ['test section 1', 'test section 2'],
      },
      numSections: { chosen: 2 },
    });
    courseFormState = new CourseFormState(store);
  });

  it('assigns store to the store', () => {
    expect(courseFormState.store).toEqual(store);
  });

  describe('#isChanged', () => {
    describe('when the course name is not changed after marking clean', () => {
      beforeEach(() => {
        courseFormState.markClean();
      });

      it('returns that form state is not changed', () => {
        expect(courseFormState.isChanged).toBe(false);
      });
    });

    describe('when the course name is changed after marking clean', () => {
      beforeEach(() => {
        courseFormState.markClean();
        store.course.name = 'test course name 2';
      });

      it('returns that form state is changed', () => {
        expect(courseFormState.isChanged).toBe(true);
      });
    });

    describe('when the course start date is changed after marking clean', () => {
      beforeEach(() => {
        courseFormState.markClean();
        store.course.startDate.setDate(today.getDate() + 7);
      });

      it('returns that form state is changed', () => {
        expect(courseFormState.isChanged).toBe(true);
      });
    });

    describe('when the course end date is changed after marking clean', () => {
      beforeEach(() => {
        courseFormState.markClean();
        store.course.endDate.setDate(today.getDate() + 7);
      });

      it('returns that form state is changed', () => {
        expect(courseFormState.isChanged).toBe(true);
      });
    });

    describe('when the course sections are changed after marking clean', () => {
      beforeEach(() => {
        courseFormState.markClean();
        store.course.sections = ['test section 1', 'test section 3'];
      });

      it('returns that form state is changed', () => {
        expect(courseFormState.isChanged).toBe(true);
      });
    });

    describe('when the section count is changed after marking clean', () => {
      beforeEach(() => {
        courseFormState.markClean();
        store.numSections = 3;
      });

      it('returns that form state is changed', () => {
        expect(courseFormState.isChanged).toBe(true);
      });
    });
  });
});
