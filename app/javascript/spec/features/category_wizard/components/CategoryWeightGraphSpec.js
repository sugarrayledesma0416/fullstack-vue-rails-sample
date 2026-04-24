import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import CategoryWeightGraph from 'features/category_wizard/components/CategoryWeightGraph';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

jest.mock('images/category_wizard/weighting_alert.png', () => '');

const config = {
  instAdmin: false,
  programId: 79,
  schoolId: 100,
  isEnterprise: false,
};

const courseOptionsResponse = { settings: [] };

/**
 * This method gets wrapper for CategoryWeightGraph component
 * @param {Array.<Category>} categoriesData - categories in the course for the wrapper
 * @return {Wrapper}
 */
function getWrapper(categoriesData) {
  const course = new Course();
  const courseDataStore = new CourseDataStore(
    course,
    config.instAdmin,
    config.isEnterprise,
    config.programId,
    config.schoolId
  );
  courseDataStore.store.course.categories = categoriesData;
  return mount(CategoryWeightGraph, {
    global: {
      provide: { courseDataStore },
    },
  });
}

let wrapper;
describe('CategoryWeightGraph', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    describe('when total weight of the categories is 100', () => {
      beforeEach(() => {
        const categoriesData = [
          { id: 11, name: 'Some category name 1', weightingPercent: 25 },
          { id: 12, name: 'Some category name 2', weightingPercent: 30 },
          { id: 13, name: 'Some category name 3', weightingPercent: 45 },
        ];
        wrapper = getWrapper(categoriesData);
      });

      it('does not display underweight graph', () => {
        expect(wrapper.get('.test-under-percent').isVisible()).toBeFalsy();
      });

      it('does not display underweight alert message', () => {
        expect(wrapper.get('.test-underweight-alert-msg').isVisible()).toBeFalsy();
      });

      it('does not display overweight graph', () => {
        expect(wrapper.get('.test-over-percent').isVisible()).toBeFalsy();
      });

      it('does not display overweight alert message', () => {
        expect(wrapper.get('.test-overweight-alert-msg').isVisible()).toBeFalsy();
      });

      it('displays weight graph for 100%', () => {
        expect(wrapper.get('.test-allocated-percent').isVisible()).toBeTruthy();
      });
    });

    describe('when total categories weight adds up to greater than 100', () => {
      beforeEach(() => {
        const categoriesData = [
          { id: 11, name: 'Some category name 1', weightingPercent: 75 },
          { id: 12, name: 'Some category name 2', weightingPercent: 30 },
          { id: 13, name: 'Some category name 3', weightingPercent: 45 },
        ];
        wrapper = getWrapper(categoriesData);
      });

      it('does not display underweight graph', () => {
        expect(wrapper.get('.test-under-percent').isVisible()).toBeFalsy();
      });

      it('does not display underweight alert message', () => {
        expect(wrapper.get('.test-underweight-alert-msg').isVisible()).toBeFalsy();
      });

      it('displays overweight graph', () => {
        expect(wrapper.get('.test-over-percent').isVisible()).toBeTruthy();
      });

      it('displays overweight alert message', () => {
        expect(wrapper.get('.test-overweight-alert-msg').isVisible()).toBeTruthy();
      });

      it('displays overweight alert message with information text', () => {
        expect(
          wrapper.get('.test-overweight-alert-msg').text()
        ).toBe('Category weighting 50% Over');
      });

      it('displays weight graph for 100%', () => {
        expect(wrapper.get('.test-allocated-percent').isVisible()).toBeTruthy();
      });
    });

    describe('when total categories weight adds up to lesser than 100', () => {
      beforeEach(() => {
        const categoriesData = [
          { id: 11, name: 'Some category name 1', weightingPercent: 5 },
          { id: 12, name: 'Some category name 2', weightingPercent: 30 },
          { id: 13, name: 'Some category name 3', weightingPercent: 45 },
        ];
        wrapper = getWrapper(categoriesData);
      });

      it('displays underweight graph', () => {
        expect(wrapper.find('.test-under-percent').isVisible()).toBeTruthy();
      });

      it('displays underweight alert message', () => {
        expect(wrapper.get('.test-underweight-alert-msg').isVisible()).toBeTruthy();
      });

      it('displays underweight alert message with information text', () => {
        expect(
          wrapper.get('.test-underweight-alert-msg'
          ).text()).toBe('Category weighting 20% Under');
      });

      it('does not display overweight graph', () => {
        expect(wrapper.get('.test-over-percent').isVisible()).toBeFalsy();
      });

      it('does not display overweight alert message', () => {
        expect(wrapper.get('.test-overweight-alert-msg').isVisible()).toBeFalsy();
      });

      it('displays weight graph for 100%', () => {
        expect(wrapper.get('.test-allocated-percent').isVisible()).toBeTruthy();
      });
    });
  });
});
