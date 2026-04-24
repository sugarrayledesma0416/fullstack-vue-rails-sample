import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import Lessons
  from 'features/course_wizard/components/content_step/settings/Lessons';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const courseOptionsResponse = { units: [{}], settings: [{}] };

/**
 * This method gets wrapper for Lessons component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(Lessons, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}

let wrapper;
let config;
let course;
let courseDataStore;

describe('Lessons', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      config = {
        instAdmin: false,
        programId: 79,
        schoolId: 100,
        isEnterprise: false,
      };
      course = new Course();
      courseDataStore = new CourseDataStore(
        course,
        config.instAdmin,
        config.isEnterprise,
        config.programId,
        config.schoolId
      );
      courseDataStore.newCourseMode = true;
      courseDataStore.store.settingsCourses = {
        contentSettingsCourse: { id: null },
      };
      courseDataStore.store.courseOptions = {
        units: [
          { id: 1, label: 'some label 1' },
          { id: 2, label: 'some label 2' },
        ],
        settings: [
          { name: 'Default Course', id: 1 },
        ],
        template_settings: [
          { name: 'Default Course', id: 1 },
        ],
      };
      courseDataStore.store.unitOptions = [
        { id: 1, label: 'some label 1' },
        { id: 2, label: 'some label 2' },
      ];

      wrapper = getWrapper();
    });

    it('displays first unit options', () => {
      expect(wrapper.find('.test-first-unit-select').exists()).toBeTruthy();
    });

    it('displays last unit options', () => {
      expect(wrapper.find('.test-last-unit-select').exists()).toBeTruthy();
    });
  });
});
