import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import AccessLevelMessage from 'features/course_wizard/components/content_step/AccessLevelMessage';
import fetchMock from 'fetch-mock';

/**
 * This method gets wrapper for ContentStep component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(AccessLevelMessage, {
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

const response = {
  settings: [],
  available_course_packages: null,
  levels: [
    { id: 1, name: 'level 1' },
    { id: 2, name: 'level 2' },
    { id: 1, name: 'level 102' },
  ],
  components: [{ id: 11, name: 'component 1' }, { id: 12, name: 'component 2' }],
  schools: [{ id: 100, name: 'School 100' }, { id: 101, name: 'School 101' }],
};

describe('AccessLevelMessage', () => {
  beforeEach(async () => {
    config = {
      canShareToGoogleClassroomForSchool: true,
      instAdmin: false,
      isCurrentProgramSupersiteJunior: false,
      programId: 79,
      schoolId: 100,
      isVol: true,
      isEnterprise: false
    };

    delete window.location;
    window.location = new URL('http://example.com/new');

    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: response });

    course = new Course();
    course.name = 'some course name';
    course.pathType = 'custom';
    course.schoolId = 100;
    course.level = 1;

    courseDataStore = new CourseDataStore(
      course,
      config.instAdmin,
      config.isEnterprise,
      config.programId,
      config.schoolId
    );

    await fetchMock.flush(true);
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays the school name', () => {
      expect(wrapper.find('.test-school').text()).toBe('School 100');
    });

    it('displays the levels for which the school can access', () => {
      expect(wrapper.find('.test-levels').text()).toBe('level 1, level 102');
    });
  });
});
