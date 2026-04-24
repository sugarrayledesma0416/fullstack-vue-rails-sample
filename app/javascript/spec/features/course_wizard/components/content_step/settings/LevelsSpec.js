import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import Levels from 'features/course_wizard/components/content_step/settings/Levels';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const courseOptionsResponse = { components: [], levels: [], settings: [] };

/**
 * This method gets wrapper for Levels component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(Levels, {
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
describe('Levels', () => {
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
      course.schoolId = 101;
      course.level = 1;
      courseDataStore.store.courseOptions = {
        available_course_packages: null,
        levels: [{ id: 1, name: 'level 1' }, { id: 2, name: 'level 2' }],
        components: [{ id: 11, name: 'component 1' }, { id: 12, name: 'component 2' }],
        schools: [{ id: 101, name: 'School 1' }, { id: 102, name: 'School 1' }],
      };

      wrapper = getWrapper();
    });

    it('displays 2 Access Level radio buttons', () => {
      expect(wrapper.findAll('.test-access-level-rb').length).toBe(2);
    });
  });
});
