import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import AudioText from 'features/course_wizard/components/content_step/settings/AudioText';
import fetchMock from 'fetch-mock';

/**
 * This method gets wrapper for ContentStep component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(AudioText, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}

const response = {
  units: [{
    label: 'Lesson 2',
    id: 2,
  }, {
    label: 'Lesson 3',
    id: 3,
  }, {
    label: 'Lesson 4',
    id: 4,
  }, {
    label: 'Lesson 5',
    id: 5,
  }, {
    label: 'Lesson 6',
    id: 6,
  }, {
    label: 'Lesson 1',
    id: 1,
  }],
  course: {
    school_id: 1,
  },
  settings: [
    {
      categories: [
        {
          current_scoring_ruleset: {},
          id: 100,
          name: 'some category name 1',
        },
        {
          current_scoring_ruleset: {},
          id: 101,
          name: 'some category name 2',
        },
      ],
      sections: [
        { name: 'previous 1' },
        { name: 'previous 2' },
      ],
    },
  ],
  available_course_packages: [
    { id: 1, name: 'level 1', content_type: 'level', rank: 5 },
    { id: 2, name: 'level 2', content_type: 'level', rank: 15 },
    { id: 3, name: 'level 3', content_type: 'level', rank: 10 },
    { id: 11, name: 'component 1', content_type: 'component' },
    { id: 22, name: 'component 2', content_type: 'component' },
  ],
};

let wrapper;
let config;
let course;
let courseDataStore;

describe('AudioText', () => {
  beforeEach(async () => {
    delete window.location;
    window.location = new URL('http://example.com/new');

    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: response });

    config = {
      instAdmin: false,
      programId: 79,
      schoolId: 100,
      isEnterprise: false
    };

    course = new Course();
    course.allowAudioTranscripts = true;

    courseDataStore = new CourseDataStore(
      course,
      config.instAdmin,
      config.isEnterprise,
      config.programId,
      config.schoolId
    );
  });

  afterEach(() => fetchMock.restore());

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    describe('when audio transcripts are allowed', () => {
      beforeEach(() => {
        courseDataStore.store.course.allowAudioTranscripts = true;
        wrapper = getWrapper();
      });

      it('is checked', () => {
        expect(wrapper.get('.test-audio-transcripts-checkbox').element.checked).toBeTruthy();
      });
    });

    describe('when audio transcripts are not allowed', () => {
      beforeEach(() => {
        courseDataStore.store.course.allowAudioTranscripts = false;
        wrapper = getWrapper();
      });

      it('is not checked', () => {
        expect(wrapper.get('.test-audio-transcripts-checkbox').element.checked).toBeFalsy();
      });
    });
  });
});
