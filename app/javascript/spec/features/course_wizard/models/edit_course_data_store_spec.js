import Course from 'features/course_wizard/models/course';
import Category from 'features/category_wizard/models/category';
import EditCourseDataStore from 'features/course_wizard/models/edit_course_data_store';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';
import { pick } from 'shared/utils';

delete window.location;
window.location = new URL('http://example.com/edit#');

const instAdmin = false;
const courseId = 10;
const programId = 100;
const schoolId = 1;

const currentDate = new Date();
const startDate = new Date();
const endDate = new Date();
startDate.setDate(currentDate.getDate() - 15);
endDate.setDate(currentDate.getDate() + 15);

jest.mock('features/section_wizard/models/section', () => {
  return {
    createSection: (section) => section.name,
  };
});

window.scrollTo = jest.fn();

const categoryObjInResponse = {
  accept_late_work: true,
  credit_only: true,
  current_scoring_ruleset: {
    id: 607,
    ignore_accents: false,
    ignore_capitalization: true,
    ignore_punctuation: true,
  },
  drop_low_scores: 0,
  enhanced_feedback_disabled: false,
  has_assessment_assignments: false,
  has_assignments: true,
  id: 118,
  languageCode: 'en',
  late_work_penalty: 'flat_percent',
  max_attempts: -1,
  name: 'Credit',
  penalty_percent: 50,
  rank: 1,
  weighting_percent: 100,
};

const courseDataInResponse = {
  allow_audio_transcripts: true,
  allow_individual_assign: true,
  allow_video_popup_translation: true,
  allows_help_requests: false,
  allows_review_requests: false,
  categories: [categoryObjInResponse],
  chat_level: 'partner_chat_and_live_chat',
  components: [],
  enable_vocab_tutorial_translations: true,
  end_date: formatDateMMDDYYYY(endDate),
  first_unit_id: 304,
  id: courseId,
  is_template: false,
  last_unit_id: 309,
  level: 64,
  name: 'some course name',
  school_id: schoolId,
  sections: [
    { name: 'previous 1' },
    { name: 'previous 2' },
  ],
  share_to_google_classroom: false,
  show_estimated_times: true,
  standard_set_ids: [1, 3],
  start_date: formatDateMMDDYYYY(startDate),
  video_subtitle_languages: 'english',
  video_transcript_languages: 'foreign_and_english',
};

const courseOptionsResponse = {
  available_course_packages: [
    { id: 1, name: 'level 1', content_type: 'level', rank: 5 },
    { id: 2, name: 'level 2', content_type: 'level', rank: 15 },
    { id: 3, name: 'level 3', content_type: 'level', rank: 10 },
    { id: 11, name: 'component 1', content_type: 'component' },
    { id: 22, name: 'component 2', content_type: 'component' },
  ],
  course: courseDataInResponse,
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
      name: 'some previous course name',
      sections: [
        { name: 'previous 1' },
        { name: 'previous 2' },
      ],
    },
  ],
  units: [
    { id: 2, label: 'Lesson 2' },
    { id: 3, label: 'Lesson 3' },
    { label: 'Lesson 4', id: 4 },
    { id: 5, label: 'Lesson 5' },
    { id: 6, label: 'Lesson 6' },
    { id: 1, label: 'Lesson 1' },
  ],
  supported_standard_sets: [
    { id: 1, name: 'standard 1' },
    { id: 2, name: 'standard 2' },
    { id: 3, name: 'standard 3' },
  ],
};

const newCategoryObj = { name: 'new_cat', languageCode: 'en' };

/**
 * Get date string in mm/dd/yyyy format
 * @param {Date} date
 * @return {string}
 */
function formatDateMMDDYYYY(date) {
  let month = (date.getMonth() + 1).toString();
  let day = date.getDate().toString();
  const year = date.getFullYear().toString();
  if (month.length < 2) {
    month = '0' + month;
  }
  if (day.length < 2) {
    day = '0' + day;
  }
  return [year, month, day].join('/');
}

let editCourseDataStore;
let course;
describe('editCourseDataStore', () => {
  beforeEach(async () => {
    const courseOptionsUrl = 'http://example.com/edit.json';
    fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });
    const courseUpdateUrl = `/instructor/${programId}/courses/${courseId}.json`;
    const updateResponse = { categories: [newCategoryObj] };
    fetchMock.mock(courseUpdateUrl, { status: 200, body: updateResponse });
    const contentStepDataUrl = 'http://example.com/content_step.json';
    fetchMock.mock(contentStepDataUrl, {
      status: 200,
      body: {
        course_has_individual_assignments: true,
      },
    });

    course = new Course();
    editCourseDataStore = new EditCourseDataStore(course, instAdmin, programId, schoolId, 'en');
    await fetchMock.flush(true);
    await flushPromises();
  });

  afterEach(() => fetchMock.restore());

  it('assigns course to the store', () => {
    expect(editCourseDataStore.store.course).toEqual(course);
  });

  it('sets the loading spinner flag to false', () => {
    expect(editCourseDataStore.store.loadingOptions).toBe(false);
  });

  describe('when copying course information from course data in course options', () => {
    it('copies course properties with keys in camel case', () => {
      const keysToCheck = [
        'allowAudioTranscripts',
        'allowIndividualAssign',
        'allowVideoPopupTranslation',
        'allowsHelpRequests',
        'allowsReviewRequests',
        'categories',
        'chatLevel',
        'components',
        'enableVocabTutorialTranslations',
        'endDate',
        'firstUnitId',
        'id',
        'isTemplate',
        'lastUnitId',
        'level',
        'name',
        'schoolId',
        'sections',
        'shareToGoogleClassroom',
        'showEstimatedTimes',
        'standardSetIds',
        'startDate',
        'videoSubtitleLanguages',
        'videoTranscriptLanguages',
      ];

      const componentIds = [11, 22];
      const levelIdWithMaxRank = 2;
      const courseDataWithCamelCaseKeys = {
        allowAudioTranscripts: courseDataInResponse.allow_audio_transcripts,
        allowIndividualAssign: courseDataInResponse.allow_individual_assign,
        allowVideoPopupTranslation: courseDataInResponse.allow_video_popup_translation,
        allowsHelpRequests: courseDataInResponse.allows_help_requests,
        allowsReviewRequests: courseDataInResponse.allows_review_requests,
        categories: [
          new Category(courseDataInResponse.categories[0]),
        ],
        chatLevel: courseDataInResponse.chat_level,
        components: componentIds,
        enableVocabTutorialTranslations: courseDataInResponse.enable_vocab_tutorial_translations,
        endDate: courseDataInResponse.end_date,
        firstUnitId: courseDataInResponse.first_unit_id,
        id: courseDataInResponse.id,
        isTemplate: courseDataInResponse.is_template,
        lastUnitId: courseDataInResponse.last_unit_id,
        level: levelIdWithMaxRank,
        name: courseDataInResponse.name,
        schoolId: courseDataInResponse.school_id,
        sections: courseDataInResponse.sections,
        shareToGoogleClassroom: courseDataInResponse.share_to_google_classroom,
        showEstimatedTimes: courseDataInResponse.show_estimated_times,
        startDate: courseDataInResponse.start_date,
        standardSetIds: courseDataInResponse.standard_set_ids,
        videoSubtitleLanguages: courseDataInResponse.video_subtitle_languages,
        videoTranscriptLanguages: courseDataInResponse.video_transcript_languages,
      };

      expect(
        pick(editCourseDataStore.store.course, ...keysToCheck)
      ).toEqual(courseDataWithCamelCaseKeys);
    });
  });

  describe('course.categories', () => {
    it('course should contain an array of Category objects', () => {
      expect(
        editCourseDataStore.store.course.categories
      ).toEqual([
        new Category(categoryObjInResponse),
      ]);
    });
  });

  describe('watcher on course.firstUnit', () => {
    describe('when first unit id is changed', () => {
      beforeEach(async () => {
        editCourseDataStore.store.course.firstUnitId = 3;
        await flushPromises();
      });

      it('changes the unitOptions based on the first unit id', () => {
        const newLastUnitOptions = editCourseDataStore.store.unitOptions.map((option) => {
          return option.id;
        });
        expect(newLastUnitOptions).toEqual([3, 4, 5, 6, 1]);
      });
    });

    describe('when the last unit id is set to less than the first unit id', () => {
      beforeEach(async () => {
        editCourseDataStore.store.course.lastUnitId = 2;
        editCourseDataStore.store.course.firstUnitId = 4;
        await flushPromises();
      });

      it('changes the last unit id to the same as first unit id', () => {
        expect(editCourseDataStore.store.course.lastUnitId).toBe(4);
      });

      it('changes the unitOptions based on the first unit id', () => {
        const newLastUnitOptions = editCourseDataStore.store.unitOptions.map((option) => {
          return option.id;
        });
        expect(newLastUnitOptions).toEqual([4, 5, 6, 1]);
      });
    });

    describe('when the last unit has a lower id but it is higher on the unit rank', () => {
      beforeEach(async () => {
        editCourseDataStore.store.course.lastUnitId = 1;
        editCourseDataStore.store.course.firstUnitId = 4;
        await flushPromises();
      });

      it('does not change the last unit id', () => {
        expect(editCourseDataStore.store.course.lastUnitId).toBe(1);
      });
    });
  });

  describe('#fetchContentStepData', () => {
    it('sets courseHasIndividualAssignments in the store', () => {
      expect(editCourseDataStore.store.courseHasIndividualAssignments).toEqual(true);
    });
  });

  describe('#postCourseUpdate', () => {
    it('sets the saving flag', () => {
      editCourseDataStore.store.saving = false;
      editCourseDataStore.postCourseUpdate();
      expect(editCourseDataStore.store.saving).toBeTruthy();
    });

    describe('when update is successful', () => {
      beforeEach(async () => {
        editCourseDataStore.flashMessageState.displayNotice = jest.fn();
        editCourseDataStore.postCourseUpdate();
        await flushPromises();
      });

      it('unsets the saving flag', () => {
        expect(editCourseDataStore.store.saving).toBeFalsy();
      });

      it('scrolls to top of page', function() {
        expect(window.scrollTo).toHaveBeenCalledWith(0, 0);
      });

      it('sets notice flash message value', function() {
        const message = 'Successfully saved course settings.';
        expect(editCourseDataStore.store.flashNotice).toBe(message);
      });

      it('shows a notice flash message', function() {
        expect(editCourseDataStore.flashMessageState.displayNotice).toHaveBeenCalled();
      });

      it('re-initializes course categories with the returned value', function() {
        expect(
          editCourseDataStore.store.course.categories
        ).toEqual([new Category(newCategoryObj)]);
      });

      it('clears removed categories on course', function() {
        expect(editCourseDataStore.store.course.removedCategories).toEqual([]);
      });
    });
  });

  describe('store.courseOptions.settings', () => {
    it('should contain an array of Section instances and Category objects', () => {
      expect(
        editCourseDataStore.store.courseOptions.settings
      ).toEqual([{
        name: 'some previous course name',
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
      }]);
    });
  });

  describe('#isUpdateDisabled', () => {
    describe('when total category weight is not 100', () => {
      beforeEach(() => {
        editCourseDataStore.store.course.categories[0].weightingPercent = 30;
      });

      describe('when saving is true', function() {
        it('returns to disable update', function() {
          editCourseDataStore.store.saving = true;
          expect(editCourseDataStore.isUpdateDisabled).toBe(true);
        });
      });

      describe('when category total weight is not 100', function() {
        it('returns to disable update', function() {
          editCourseDataStore.store.saving = false;
          expect(editCourseDataStore.isUpdateDisabled).toBe(true);
        });
      });
    });

    describe('when saving is true and category total weight is 100', function() {
      it('returns to enable update', function() {
        editCourseDataStore.store.saving = false;
        editCourseDataStore.totalWeight = () => 100;
        expect(editCourseDataStore.isUpdateDisabled).toBe(false);
      });
    });

    describe('when no standard set is selected', function() {
      it('returns to disable update', function() {
        editCourseDataStore.store.course.standardSetIds = [];

        expect(editCourseDataStore.isUpdateDisabled).toBe(true);
      });
    });
  });

  describe('validations', () => {
    it('forwards the validations run by the CourseValidator', () => {
      expect(editCourseDataStore.validations.length).toBe(5);
    });
  });
});
