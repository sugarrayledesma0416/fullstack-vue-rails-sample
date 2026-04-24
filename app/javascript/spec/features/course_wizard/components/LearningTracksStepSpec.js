import { mount } from '@vue/test-utils';
import LearningTracksStep from 'features/course_wizard/components/LearningTracksStep';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const mockLearningTracksStepDataStore = {
  expressCreate: jest.fn(),
  jobProgress: {
    shouldShow: false,
  },
  store: {
    course: {
      sections: [
        {}, {},
      ],
    },
    unitRange: {
      firstUnitIndex: '0',
      lastUnitIndex: '1',
    },
    learningTracksConfig: {
      chooseTrack: false,
      previousCourses: [{
        id: 39,
        name: 'sddf',
        sections: [{ id: 54, name: 'test 1234' }],
      }],
    },
    sectionSource: {
      type: 'course',
    },
    setupDescriptions: {
      learning_tracks: false,
    },
    disableAllControls: false,
  },
  assignmentCalendar: {
    copyIgc: false,
  },
};

jest.mock('features/course_wizard/models/learning_tracks_step_data_store.js', () => {
  return jest.fn().mockImplementation(() => mockLearningTracksStepDataStore);
});

window.scrollTo = jest.fn();

let wrapper;

/**
 * This method gets wrapper for LearningTracksStep component
 * @return {Wrapper}
 */
const getWrapper = () => {
  return mount(LearningTracksStep, {
    global: {
      mocks: {
        $route: {
          name: 'learning-tracks-step',
        },
      },
      provide: {
        config,
        courseDataStore,
      },
      stubs: {
        SaveCourseModal: true,
      },
    },
    propsData: {
      loadingIconPath: '/images/loading.gif',
    },
  });
};

const courseOptionsResponse = { settings: [] };

const learningTracksResponse = {
  strands: { Contextos: { color: '#BE0027', name: 'Contextos' }},
  tracks: {
    Communicative: { description: '<b>Supports</b>', subtracks: { Complete: {}}},
  },
};

let config;
let course;
let courseDataStore;

describe('LearningTracksStep', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });

    const learningTracksUrl = '/instructor/79/learning_tracks.json';
    fetchMock.mock(learningTracksUrl, { status: 200, body: learningTracksResponse });

    config = {
      canShareToGoogleClassroomForSchool: true,
      instAdmin: false,
      isCurrentProgramSupersiteJunior: false,
      programId: 79,
      schoolId: 100,
      isVol: true,
      isEnterprise: false,
    };
    course = new Course();
    course.name = 'Test Course';
    course.pathType = 'express';
    courseDataStore = new CourseDataStore(
      course,
      config.instAdmin,
      config.isEnterprise,
      config.programId,
      config.schoolId
    );

    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays the course name heading', () => {
      expect(wrapper.find('.test-course-name').text()).toBe('Test Course');
    });

    it('marks the correct breadcrumb as current', () => {
      const currentBreadcrumb = wrapper.find('.test-breadcrumb-title.title--is-current');
      expect(currentBreadcrumb.attributes('aria-current')).toBe('step');
      expect(currentBreadcrumb.text()).toBe('Assignments');
    });

    it('displays LearningTrackApp component', () => {
      expect(wrapper.findComponent({ name: 'LearningTrackApp' }).exists()).toBeTruthy();
    });

    it('displays SetupControls component', () => {
      expect(wrapper.findComponent({ name: 'SetupControls' }).exists()).toBeTruthy();
    });

    it('scrolls to the top of the page', () => {
      const scrollSpy = jest.spyOn(window, 'scrollTo');
      expect(scrollSpy).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('when "save" event is emitted', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const setupControls = wrapper.findComponent({ name: 'SetupControls' });
      await setupControls.vm.$emit('save');
    });

    it('calls expressCreate method of LearningTracksStepDataStore', () => {
      expect(mockLearningTracksStepDataStore.expressCreate).toHaveBeenCalledWith();
    });
  });

  describe('when "shouldShow" jobProgress flag is false in LearningTracksStepDataStore', () => {
    beforeEach(() => {
      mockLearningTracksStepDataStore.jobProgress.shouldShow = false;
      wrapper = getWrapper();
    });

    it('does not display SaveCourseModal component', () => {
      expect(wrapper.findComponent({ name: 'SaveCourseModal' }).exists()).toBeFalsy();
    });
  });

  describe('when "shouldShow" jobProgress flag is true in LearningTracksStepDataStore', () => {
    beforeEach(() => {
      mockLearningTracksStepDataStore.jobProgress.shouldShow = true;
      wrapper = getWrapper();
    });

    it('displays SaveCourseModal component', () => {
      expect(wrapper.findComponent({ name: 'SaveCourseModal' }).exists()).toBeTruthy();
    });
  });
});
