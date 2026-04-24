import { reactive } from 'vue';
import Course from 'features/course_wizard/models/course';
import CourseValidator from 'features/course_wizard/models/course_validator';

import { add, sub } from 'date-fns';

const today = new Date();

/**
 * @private
 * get a date in MMDDYYYY format which is given days in future or past
 * @param {number} daysFromToday - days from today.
 * positive value for future and negative for past date
 * @return {string}
 */
function dateFromTodayMMDDYYYY(daysFromToday) {
  const date = new Date();
  date.setDate(today.getDate() + daysFromToday);
  return dateMMDDYYYY(date);
}

/**
 * @private
 * Return a date as a string with MM/DD/YYYY format.
 * @param {Date} date
 * @return {string}
 */
function dateMMDDYYYY(date) {
  let month = (date.getMonth() + 1).toString();
  let day = date.getDate().toString();
  const year = date.getFullYear().toString();
  if (month.length < 2) {
    month = '0' + month;
  }
  if (day.length < 2) {
    day = '0' + day;
  }
  return [month, day, year].join('/');
}

const defaultCourseCategories = [
  {
    weightingPercent: 50,
  },
  {
    weightingPercent: 50,
  },
];

let courseValidator;
let course;
describe('CourseValidator', () => {
  beforeEach(async () => {
    course = new Course();
    course.categories = defaultCourseCategories;
    const store = reactive({ course });
    courseValidator = new CourseValidator(store);
  });

  it('assigns store to the store', () => {
    expect(courseValidator.store.course).toEqual(course);
  });

  describe('#validateDates', () => {
    describe('when both start and end date are populated', () => {
      describe('when the start date is less than end date', () => {
        beforeEach(() => {
          courseValidator.store.course = {
            startDate: dateFromTodayMMDDYYYY(0),
            endDate: dateFromTodayMMDDYYYY(7),
            dueDates: 'Monday',
            categories: defaultCourseCategories,
          };
        });

        it('returns that dates are valid', () => {
          expect(courseValidator.validateDates()).toBe(true);
        });
      });

      describe('when the start date is greater than end date', () => {
        beforeEach(() => {
          courseValidator.store.course = {
            startDate: dateFromTodayMMDDYYYY(14),
            endDate: dateFromTodayMMDDYYYY(7),
            dueDates: 'Monday',
            categories: defaultCourseCategories,
          };
        });

        it('returns that dates are invalid', () => {
          expect(courseValidator.validateDates()).toBe(false);
        });

        it('validates the start date', () => {
          const validation = courseValidator.findValidation('course-start-date');
          expect(validation.status).toBe('invalid');
        });

        it('validates the end date', () => {
          const validation = courseValidator.findValidation('course-end-date');
          expect(validation.status).toBe('valid');
        });
      });
    });
  });

  describe('#findValidation', () => {
    let validation;

    describe('when the end date is greater than today', () => {
      beforeEach(() => {
        courseValidator.store.course = {
          startDate: dateFromTodayMMDDYYYY(0),
          endDate: dateFromTodayMMDDYYYY(1),
          dueDates: 'Monday',
          categories: defaultCourseCategories,
        };
      });

      it('validates the start date', () => {
        validation = courseValidator.findValidation('course-start-date');
        expect(validation.status).toBe('valid');
      });

      it('validates the end date', () => {
        validation = courseValidator.findValidation('course-end-date');
        expect(validation.status).toBe('valid');
      });
    });

    describe('when the end date is today', () => {
      beforeEach(() => {
        courseValidator.store.course = {
          startDate: dateFromTodayMMDDYYYY(0),
          endDate: dateFromTodayMMDDYYYY(0),
          dueDates: 'Monday',
          categories: defaultCourseCategories,
        };
      });

      it('validates the end date', () => {
        validation = courseValidator.findValidation('course-end-date');
        expect(validation.status).toBe('valid');
      });
    });

    describe('when the end date is less than today', () => {
      beforeEach(() => {
        courseValidator.store.course = {
          startDate: dateFromTodayMMDDYYYY(0),
          endDate: dateFromTodayMMDDYYYY(-1),
          dueDates: 'Monday',
          categories: defaultCourseCategories,
        };
        validation = courseValidator.findValidation('course-end-date');
      });

      it('marks the end date field as invalid', () => {
        expect(validation.status).toBe('invalid');
      });

      it('sets a validation message for the end date field', () => {
        expect(validation.description).toEqual('Your end date cannot be in the past.');
      });
    });

    describe('when the end date is 3 years from now', () => {
      beforeEach(() => {
        const endDate = add(new Date(), { years: 3 });

        courseValidator.store.course = {
          startDate: dateFromTodayMMDDYYYY(0),
          endDate: dateMMDDYYYY(endDate),
          dueDates: 'Monday',
          categories: defaultCourseCategories,
        };
        validation = courseValidator.findValidation('course-end-date');
      });

      it('marks the end date field as invalid', () => {
        expect(validation.status).toBe('invalid');
      });

      it('sets a validation message for the end date field', () => {
        expect(validation.description).toEqual(
          'Your end date must not be more than 3 years from now.'
        );
      });
    });

    describe('when the end date is less than 3 years from now', () => {
      beforeEach(() => {
        // Add 3 years and then subtract one day.
        const endDate = sub(add(new Date(), { years: 3 }), { days: 1 });

        courseValidator.store.course = {
          startDate: dateFromTodayMMDDYYYY(0),
          endDate: dateMMDDYYYY(endDate),
          dueDates: 'Monday',
          categories: defaultCourseCategories,
        };
      });

      it('validates the end date', () => {
        validation = courseValidator.findValidation('course-end-date');
        expect(validation.status).toBe('valid');
      });
    });
  });

  describe('validating total category weight', () => {
    describe('when the total weight is 100', () => {
      it('validates the total category weight', () => {
        const validation = courseValidator.findValidation('total-category-weight');
        expect(validation.status).toBe('valid');
      });
    });

    describe('when the total weight is not 100', () => {
      beforeEach(() => {
        courseValidator.store.course.categories[0].weightingPercent = 20;
      });

      it('invalidates the total category weight', () => {
        const validation = courseValidator.findValidation('total-category-weight');
        expect(validation.status).toBe('invalid');
      });
    });
  });
});
