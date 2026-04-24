import Course from 'features/course_wizard/models/course';
import NewCourseDataStore from 'features/course_wizard/models/new_course_data_store';
import LearningTracksStepDataStore
  from 'features/course_wizard/models/learning_tracks_step_data_store';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const instAdmin = false;
const programId = 100;
const schoolId = 1;
const isEnterprise = false;

const mockCourseHttp = {
  expressCreate: jest.fn(() => Promise.resolve({ data: { job_id: 10, course_id: 20 }})),
};

jest.mock('features/course_wizard/services/course_http.js', () => {
  return jest.fn().mockImplementation(() => mockCourseHttp);
});

jest.mock('features/learning_tracks/models/send_section_template_stats.js', () => {
  return {
    sectionTemplateStats: jest.fn(),
    sendSectionStats: jest.fn(),
    sendSectionTemplateStats: jest.fn(),
  };
});

const learningTracksResponse = {
  tracks: {
    a: {
      subtracks: {
        a_subtrack: {
          strands: ['strand1', 'strand2'],
        },
      },
      description: '',
    },
    b: {
      subtracks: { 'b_subtrack': {
        strands: [],
      }},
      description: '',
    },
  },
  activities: {
    1: {
      id: 1,
      minutes_to_complete: 10,
    },
    2: {
      id: 2,
      minutes_to_complete: 20,
    },
  },
  strands: {
    strand1: { color: 'blue' },
    strand2: { color: 'red' },
  },
};

const courseOptionsResponse = {
  settings: [
    { id: 1, name: 'course 1', sections: [{ id: 314 }] },
  ],
  previous_courses: ['course 1', 'course 2'],
  program: { unit_label: 'Lesson' },
};

let learningTracksStepDataStore;
let courseDataStore;
let calendarObj;
describe('LearningTracksStepDataStore', () => {
  beforeEach(async () => {
    const learningTracksUrl = `/instructor/${programId}/learning_tracks.json`;
    fetchMock.mock(learningTracksUrl, { status: 200, body: learningTracksResponse });
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
    const course = new Course();
    courseDataStore = new NewCourseDataStore(course, instAdmin, isEnterprise, programId, schoolId);
    const assignmentCalendar = {};
    learningTracksStepDataStore = new LearningTracksStepDataStore(
      courseDataStore,
      assignmentCalendar,
      instAdmin,
      programId,
      schoolId
    );
    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  describe('on initialization', function() {
    it('shares reactive store with NewCourseDataStore', function() {
      expect(learningTracksStepDataStore.store).toEqual(courseDataStore.store);
    });

    it('sets previous courses on the config', function() {
      expect(
        learningTracksStepDataStore.store.learningTracksConfig.previous_courses
      ).toEqual(['course 1', 'course 2']);
    });
  });

  describe('#express create', function() {
    beforeEach(() => {
      calendarObj = {
        calendar: 'calendar',
        course_package_ids: [1],
        categories: 'categories',
      };
      learningTracksStepDataStore.store.calendar = calendarObj;
      spyOn(mockCourseHttp, 'expressCreate').and.callThrough();
      learningTracksStepDataStore.expressCreate();
    });

    it('sends along the course, calendar, package ids, and categores to course http',
      function() {
        expect(mockCourseHttp.expressCreate).toHaveBeenCalledWith(
          learningTracksStepDataStore.store.course,
          calendarObj
        );
      }
    );
  });
});
