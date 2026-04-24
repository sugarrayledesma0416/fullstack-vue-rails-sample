import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import Translations
  from 'features/course_wizard/components/content_step/settings/Translations';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

/**
 * This method gets wrapper for Translation component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(Translations, {
    global: {
      provide: {
        config,
        courseDataStore,
      },
    },
  });
}

const courseOptionsResponse = { settings: [] };

/**
 * This method returns whether the checkbox with the given css selector is checked
 * or not in the wrapper
 * @param {string} elmSelector - Css selector for checkbox
 * @return {boolean} - Whether the checkbox is checked
 */
function getCheckedState(elmSelector) {
  return wrapper.get(elmSelector).element.checked;
}

let wrapper;
let config;
let course;
let courseDataStore;
describe('Translations', () => {
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
        enableVocabTutorialTranslations: false,
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
    });

    describe('when enableVocabTutorialTranslations is false', () => {
      beforeEach(() => {
        course.enableVocabTutorialTranslations = false;
        wrapper = getWrapper();
      });

      it('displays checkbox "Enable Vocabulary Tutorial Translations" in unchecked state', () => {
        expect(getCheckedState('.test-vocab-translations-checkbox')).toBeFalsy();
      });
    });

    describe('when enableVocabTutorialTranslations is true', () => {
      beforeEach(() => {
        course.enableVocabTutorialTranslations = true;
        wrapper = getWrapper();
      });

      it('displays checkbox "Enable Vocabulary Tutorial Translations" in checked state', () => {
        expect(getCheckedState('.test-vocab-translations-checkbox')).toBeTruthy();
      });
    });
  });
});
