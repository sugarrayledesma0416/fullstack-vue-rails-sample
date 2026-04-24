import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import ContentStep from 'features/course_wizard/components/content_step/ContentStep';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';
import { metaTagContent } from 'shared/utils';

jest.mock('shared/utils', () => {
  const originalModule = jest.requireActual('shared/utils');
  return {
    __esModule: true,
    ...originalModule,
    metaTagContent: jest.fn(),
  };
});
delete window.location;
window.location = new URL('http://example.com/new');
window.scrollTo = jest.fn();

/**
 * This method gets wrapper for ContentStep component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(ContentStep, {
    global: {
      mocks: {
        $route: {
          name: 'content-step',
        },
      },
      provide: {
        config,
        courseDataStore,
      },
      stubs: {
        AccessLevelMessage: true,
        CopySettings: true,
        Levels: true,
        Components: true,
        Lessons: true,
        Translations: true,
        IndividualizedAssigning: true,
        GoogleClassroom: true,
        HelpRequests: true,
        ScoreReviews: true,
        ChatAvailability: true,
        EstimatedTime: true,
        FormFeedback: true,
        Standards: true,
      },
    },
  });
}

let wrapper;
let config;
let course;
let courseDataStore;
let courseOptionsResponse;

const courseOptionsUrl = 'http://example.com/new.json';

describe('ContentSpec', () => {
  beforeEach(async () => {
    courseOptionsResponse = {
      settings: [],
      available_course_packages: null,
      levels: [{ id: 1, name: 'level 1' }, { id: 2, name: 'level 2' }],
      components: [{ id: 11, name: 'component 1' }, { id: 12, name: 'component 2' }],
      schools: [{ id: 100, name: 'School 100' }, { id: 101, name: 'School 101' }],
      supported_standard_sets: [{ id: 1, name: 'standard 1' }, { id: 2, name: 'standard 2' }],
    };
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });

    config = {
      canShareToGoogleClassroomForSchool: true,
      instAdmin: false,
      isCurrentProgramSupersiteJunior: false,
      programId: 79,
      schoolId: 100,
      isVol: true,
      isEnterprise: false
    };

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
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays course name heading', () => {
      const courseName = wrapper.find('.test-course-name');
      expect(courseName.text()).toBe('some course name');
    });

    it('marks the correct breadcrumb as current', () => {
      const currentBreadcrumb = wrapper.find('.test-breadcrumb-title.title--is-current');
      expect(currentBreadcrumb.attributes('aria-current')).toBe('step');
      expect(currentBreadcrumb.text()).toBe('Content');
    });

    it('displays "SetupControls" component', () => {
      expect(wrapper.findComponent({ name: 'SetupControls' }).exists()).toBeTruthy();
    });

    it('Does not display the "AccessLevelMessage" component', () => {
      expect(
        wrapper.findComponent({ name: 'AccessLevelMessage' }).exists()
      ).toBeFalsy();
    });

    it('displays "CopySettings" component', () => {
      expect(
        wrapper.findComponent({ name: 'CopySettings' }).exists()
      ).toBeTruthy();
    });

    it('displays "Levels" component', () => {
      expect(
        wrapper.findComponent({ name: 'Levels' }).exists()
      ).toBeTruthy();
    });

    it('displays "Components" component', () => {
      expect(wrapper.findComponent({ name: 'Components' }).exists()).toBeTruthy();
    });

    it('displays "Lessons" component', () => {
      expect(wrapper.findComponent({ name: 'Lessons' }).exists()).toBeTruthy();
    });

    it(
      'does not display the "Translations" component when the course\'s' +
      'language is english.',
      () => {
        expect(wrapper.findComponent({ name: 'Translations' }).exists()).toBeFalsy();
      }
    );

    it(
      'does not display the "Translations" component when the course does not' +
      'have Vocab Tutorials.',
      () => {
        expect(wrapper.findComponent({ name: 'Translations' }).exists()).toBeFalsy();
      }
    );

    it('displays "EstimatedTime" component', () => {
      expect(wrapper.findComponent({ name: 'EstimatedTime' }).exists()).toBeTruthy();
    });

    it('displays "IndividualizedAssigning" component', () => {
      expect(wrapper.findComponent({ name: 'IndividualizedAssigning' }).exists()).toBeTruthy();
    });

    it('displays "GoogleClassroom" component', () => {
      expect(wrapper.findComponent({ name: 'GoogleClassroom' }).exists()).toBeTruthy();
    });

    it('displays "HelpRequests" component', () => {
      expect(wrapper.findComponent({ name: 'HelpRequests' }).exists()).toBeTruthy();
    });

    it('displays "ScoreReviews" component', () => {
      expect(wrapper.findComponent({ name: 'ScoreReviews' }).exists()).toBeTruthy();
    });

    it('displays "ChatAvailability" component', () => {
      expect(wrapper.findComponent({ name: 'ChatAvailability' }).exists()).toBeTruthy();
    });

    it('displays "Standards" component', () => {
      expect(wrapper.findComponent({ name: 'Standards' }).exists()).toBeTruthy();
    });

    it('scrolls to the top of the page', () => {
      const scrollSpy = jest.spyOn(window, 'scrollTo');
      expect(scrollSpy).toHaveBeenCalledWith(0, 0);
    });

    describe('When there are available course packages', () => {
      beforeEach( () => {
        courseDataStore.store.courseOptions.available_course_packages = [
          { id: 1, name: 'level 1', content_type: 'level', rank: 5 },
          { id: 2, name: 'level 2', content_type: 'level', rank: 15 },
          { id: 3, name: 'level 3', content_type: 'level', rank: 10 },
          { id: 11, name: 'component 1', content_type: 'component' },
          { id: 22, name: 'component 2', content_type: 'component' },
        ];

        wrapper = getWrapper();
      });

      it('displays the "AccessLevelMessage" component', () => {
        expect(wrapper.findComponent({ name: 'AccessLevelMessage' }).exists()).toBeTruthy();
      });

      it('does not display the Access Level category', () => {
        expect(wrapper.find('.test-access-level').exists()).toBeFalsy();
      });
    });
  });

  describe('when the config has a non-english language code', () => {
    beforeEach(() => {
      config.languageCode = 'es';
      config.hasVocabTutorials = true;
      wrapper = getWrapper();
    });

    describe('courses with Vocab Tutorials', () => {
      beforeEach(() => {
        config.hasVocabTutorials = true;
        wrapper = getWrapper();
      });

      it('displays the "Translations" component',
        () => {
          expect(wrapper.findComponent({ name: 'Translations' }).exists()).toBeTruthy();
        }
      );
    });
  });

  describe('when the course options have no components', () =>{
    beforeEach(() => {
      courseDataStore.store.courseOptions.components = [];
      wrapper = getWrapper();
    });

    it('does not display the "Components" component', () => {
      expect(wrapper.findComponent({ name: 'Components' }).exists()).toBeFalsy();
    });
  });

  describe('when the config does not support Google Classroom sharing.', () => {
    beforeEach(() => {
      config.canShareToGoogleClassroomForSchool = false;
      wrapper = getWrapper();
    });

    it('does not display the "GoogleClassroom" component', () => {
      expect(wrapper.findComponent({ name: 'GoogleClassroom' }).exists()).toBeFalsy();
    });
  });

  describe('when saving the content settings', () => {
    beforeEach(() => {
      courseDataStore.store.saving = true;
      wrapper = getWrapper();
    });

    it('displays the saving spinner', () => {
      expect(wrapper.find('.test-save-spinner').exists()).toBeTruthy();
    });
  });

  describe('Supersite Junior Programs', () => {
    beforeEach(() => {
      config.isCurrentProgramSupersiteJunior = true;
      wrapper = getWrapper();
    });

    it('does not display the "ChatAvailability" component.', () => {
      expect(wrapper.findComponent({ name: 'ChatAvailability' }).exists()).toBeFalsy();
    });
  });

  describe('Edit Course Mode', () => {
    beforeEach(() => {
      courseDataStore.newCourseMode = false;
      courseDataStore.editCourseMode = true;
      wrapper = getWrapper();
    });

    it('does not display the "CopySettings" component', () => {
      expect(wrapper.findComponent({ name: 'CopySettings' }).exists()).toBeFalsy();
    });
  });

  describe('when the program supports standard sets.', () => {
    beforeEach(() => {
      courseDataStore.store.courseOptions.supported_standard_sets = [];
      wrapper = getWrapper();
    });

    it('displays "Standards" component', () => {
      expect(wrapper.findComponent({ name: 'Standards' }).exists()).toBeFalsy();
    });
  });
});
