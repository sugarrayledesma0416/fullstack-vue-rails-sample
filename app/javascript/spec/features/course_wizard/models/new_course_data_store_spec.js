import Course from 'features/course_wizard/models/course';
import Category from 'features/category_wizard/models/category';
import NewCourseDataStore from 'features/course_wizard/models/new_course_data_store';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';
import { pick } from 'shared/utils';

delete window.location;
window.location = new URL('http://example.com/new');

const instAdmin = false;
const programId = 100;
const schoolId = 1;
const startDate = new Date();
const endDate = new Date();
const pastDate = new Date();
endDate.setDate(startDate.getDate() + 7);
pastDate.setDate(startDate.getDate() - 1);

jest.mock('features/section_wizard/models/section', () => {
  return {
    createSection: (section) => section.name,
  };
});

/**
 * This method converts given string to camel case.
 * @param {string} str - a key name in response from server having underscores.
 * @return {string} - string in camel case
 */
function camelize(str) {
  return str.replace(/_/g, ' ').replace(/(?:^\w|[A-Z]|\b\w)/g, function(word, index) {
    return index === 0 ? word.toLowerCase() : word.toUpperCase();
  }).replace(/\s+/g, '');
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
    standard_set_ids: [1, 2, 3],
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
      standard_set_ids: [],
    },
  ],
  available_course_packages: [
    { id: 1, name: 'level 1', content_type: 'level', rank: 5 },
    { id: 2, name: 'level 2', content_type: 'level', rank: 15 },
    { id: 3, name: 'level 3', content_type: 'level', rank: 10 },
    { id: 11, name: 'component 1', content_type: 'component' },
    { id: 22, name: 'component 2', content_type: 'component' },
  ],
  supported_standard_sets: [
    { id: 1, name: 'standard 1'},
    { id: 2, name: 'standard 2' },
    { id: 3, name: 'standard 3' },
  ],
};

let newCourseDataStore;
let course;
describe('newCourseDataStore', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/new.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: response });
    const courseSaveUrl = `/instructor/${programId}/courses.json`;
    fetchMock.mock(courseSaveUrl, { status: 200, body: {}});
    course = new Course();
    let isEnterprise = false;
    newCourseDataStore = new NewCourseDataStore(course, isEnterprise, instAdmin, programId, schoolId, 'en');
    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  it('assigns course to the store', () => {
    expect(newCourseDataStore.store.course).toEqual(course);
  });

  it('sets the loading spinner flag to false', () => {
    expect(newCourseDataStore.store.loadingOptions).toEqual(false);
  });

  describe('watcher on course.firstUnit', () => {
    describe('when first unit id is changed', () => {
      beforeEach(async () => {
        newCourseDataStore.store.course.firstUnitId = 3;
        await flushPromises();
      });

      it('changes the unitOptions based on the first unit id', () => {
        const newLastUnitOptions = newCourseDataStore.store.unitOptions.map((option) => {
          return option.id;
        });
        expect(newLastUnitOptions).toEqual([3, 4, 5, 6, 1]);
      });
    });

    describe('when the last unit id is set to less than the first unit id', () => {
      beforeEach(async () => {
        newCourseDataStore.store.course.lastUnitId = 2;
        newCourseDataStore.store.course.firstUnitId = 4;
        await flushPromises();
      });

      it('changes the last unit id to the same as first unit id', () => {
        expect(newCourseDataStore.store.course.lastUnitId).toBe(4);
      });

      it('changes the unitOptions based on the first unit id', () => {
        const newLastUnitOptions = newCourseDataStore.store.unitOptions.map((option) => {
          return option.id;
        });
        expect(newLastUnitOptions).toEqual([4, 5, 6, 1]);
      });
    });

    describe('when the last unit has a lower id but it is higher on the unit rank', () => {
      beforeEach(async () => {
        newCourseDataStore.store.course.lastUnitId = 1;
        newCourseDataStore.store.course.firstUnitId = 4;
        await flushPromises();
      });

      it('does not change the last unit id', () => {
        expect(newCourseDataStore.store.course.lastUnitId).toBe(1);
      });
    });
  });

  describe('#save', () => {
    it('sets the saving flag', () => {
      newCourseDataStore.store.saving = false;
      newCourseDataStore.save();
      expect(newCourseDataStore.store.saving).toBeTruthy();
    });

    describe('when save is successful', () => {
      beforeEach(async () => {
        newCourseDataStore.save();
        await flushPromises();
      });

      it('unsets the saving flag', () => {
        expect(newCourseDataStore.store.saving).toBeFalsy();
      });

      it('sets selected school by default', () => {
        expect(newCourseDataStore.store.course.schoolId).toEqual(1);
      });
    });
  });

  describe('when copying date settings from a previous course', () => {
    beforeEach(async () => {
      newCourseDataStore.store.settingsCourses.dateSettingsCourse = {
        start_date: startDate,
        end_date: endDate,
      };
      newCourseDataStore.store.course.learningTrack = 'foo';
      await flushPromises();
    });
    it('copies start and end date to the course being edited', () => {
      const keysToCheck = Object.keys(
        newCourseDataStore.store.settingsCourses.dateSettingsCourse
      ).map((key) => camelize(key));
      expect(pick(newCourseDataStore.store.course, ...keysToCheck)).toEqual({
        startDate: startDate,
        endDate: endDate,
      });
    });
  });

  describe('when copying content settings from a previous course', () => {
    beforeEach(async () => {
      newCourseDataStore.store.settingsCourses.contentSettingsCourse = {
        first_unit_id: 2,
        last_unit_id: 1,
        allow_audio_transcripts: false,
        video_subtitle_languages: 'none',
        video_transcript_languages: 'none',
        allow_video_popup_translation: false,
        allows_review_requests: true,
        allows_help_requests: true,
        chat_level: 'partner_chat_only',
        level: 'level',
        components: ['component'],
        id: 566,
      };
      newCourseDataStore.store.course.learningTrack = 'foo';
      await flushPromises();
    });
    it('copies all content related properties to the course being edited', () => {
      const otherKeys = ['copyCreatedActivitiesFromPreviousCourse', 'courseLibraryFrom'];
      const keysToCheck = Object.keys(
        newCourseDataStore.store.settingsCourses.contentSettingsCourse
      ).map((key) => camelize(key)).concat(otherKeys);
      expect(pick(newCourseDataStore.store.course, ...keysToCheck)).toEqual({
        firstUnitId: 2,
        lastUnitId: 1,
        allowAudioTranscripts: false,
        videoSubtitleLanguages: 'none',
        videoTranscriptLanguages: 'none',
        allowVideoPopupTranslation: false,
        allowsReviewRequests: true,
        allowsHelpRequests: true,
        chatLevel: 'partner_chat_only',
        // package level with max rank
        level: 2,
        components: [11, 22],
        copyCreatedActivitiesFromPreviousCourse: true,
        courseLibraryFrom: 566,
      });
    });
  });

  describe('when copying content settings from a previous course', () => {
    beforeEach(async () => {
      newCourseDataStore.store.settingsCourses.contentSettingsCourse = {
        first_unit_id: 1,
        last_unit_id: 6,
        allow_audio_transcripts: false,
        video_subtitle_languages: 'none',
        video_transcript_languages: 'none',
        allow_video_popup_translation: false,
        allows_review_requests: true,
        allows_help_requests: true,
        chat_level: 'partner_chat_only',
        level: 'level',
        components: ['component'],
        id: 500,
      };
      newCourseDataStore.store.course.learningTrack = 'foo';
      await flushPromises();
    });
    it('sets copyCreatedActivitiesFromPreviousCourse to true if course id is not null',
      () => {
        expect(
          newCourseDataStore.store.course.copyCreatedActivitiesFromPreviousCourse
        ).toEqual(true);
      }
    );
  });

  describe('when copying content settings from a previous course', () => {
    beforeEach(async () => {
      newCourseDataStore.store.settingsCourses.contentSettingsCourse = {
        first_unit_id: 1,
        last_unit_id: 6,
        allow_audio_transcripts: false,
        video_subtitle_languages: 'none',
        video_transcript_languages: 'none',
        allow_video_popup_translation: false,
        allows_review_requests: true,
        allows_help_requests: true,
        chat_level: 'partner_chat_only',
        level: 'level',
        components: ['component'],
        id: 500,
      };
      newCourseDataStore.store.course.learningTrack = 'foo';
      newCourseDataStore.store.course.isTemplate = true;

      await flushPromises();
    });
    it('sets copySharedActivitiesFromPreviousCourse to true if course id is not null', () => {
      expect(newCourseDataStore.store.course.copySharedActivitiesFromPreviousCourse).toEqual(true);
    });
  });

  describe('course.categories', () => {
    it('course should contain an array of Category objects without IDs', () => {
      expect(
        newCourseDataStore.store.course.categories
      ).toEqual([
        new Category({
          current_scoring_ruleset: {},
          name: 'some category name 1',
          languageCode: 'en',
        }),
        new Category({
          current_scoring_ruleset: {},
          name: 'some category name 2',
          languageCode: 'en',
        }),
      ]);
    });
  });

  describe('when copying gradebook settings from a previous course', () => {
    beforeEach(async () => {
      newCourseDataStore.store.settingsCourses.categorySettingsCourse = {
        categories: [{}],
      };
      await flushPromises();
    });
    it('copies categories to the course being edited', async () => {
      expect(newCourseDataStore.store.course.categories).toEqual(
        [new Category({ current_scoring_ruleset: {}, languageCode: 'en' })]
      );
    });
  });
  describe('when copying gradebook settings from a previous course', () => {
    beforeEach(async () => {
      newCourseDataStore.store.settingsCourses.categorySettingsCourse = {
        categories: [{ id: 1 }],
      };
      await flushPromises();
    });
    it('will not include ids for copied categories', async () => {
      expect(newCourseDataStore.store.course.categories).toEqual(
        [new Category({ current_scoring_ruleset: {}, languageCode: 'en' })]
      );
    });
  });

  describe('settings', () => {
    it('should contain an array of Section and Category objects', () => {
      expect(
        newCourseDataStore.store.courseOptions.settings
      ).toEqual([{
        sections: ['previous 1', 'previous 2'],
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
        standard_set_ids: [],
      }]);
    });
  });

  describe('validations', () => {
    it('forwards the validations run by the CourseValidator', () => {
      expect(newCourseDataStore.validations.length).toBe(5);
    });
  });
});
