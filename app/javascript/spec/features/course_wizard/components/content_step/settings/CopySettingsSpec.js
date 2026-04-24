import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import CopySettings
  from 'features/course_wizard/components/content_step/settings/CopySettings';
import fetchMock from 'fetch-mock';
import flushPromises from 'flush-promises';

delete window.location;
window.location = new URL('http://example.com/new');

const courseOptionsResponse = { units: [{}], settings: [{}] };

/**
 * This method gets wrapper for CopySettingsAndLessons component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(CopySettings, {
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

describe('CopySettings', () => {
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
        isEnterprise: false
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

    describe('when instAdmin is true', () => {
      beforeEach(() => {
        config.instAdmin = true;
        wrapper = getWrapper();
      });

      it('displays "Use settings from Course" radio button', () => {
        expect(wrapper.find('.test-settings-from-course-rb').exists()).toBeTruthy();
      });

      it('displays "Use settings from Template" radio button', () => {
        expect(wrapper.find('.test-settings-from-template-rb').exists()).toBeTruthy();
      });
    });

    describe('when instAdmin is false', () => {
      beforeEach(() => {
        config.instAdmin = false;
        wrapper = getWrapper();
      });

      it('does not display "Use settings from Course" radio button', () => {
        expect(wrapper.find('.test-settings-from-course-rb').exists()).toBeFalsy();
      });

      it('displays "Use settings from Template" radio button', () => {
        expect(wrapper.find('.test-settings-from-template-rb').exists()).toBeFalsy();
      });
    });

    describe('when contentSettingsCourseSource is "course"', () => {
      beforeEach(() => {
        courseDataStore.store.course.contentSettingsCourseSource = 'course';
        wrapper = getWrapper();
      });

      it('displays "Use content settings from Previous Courses" select', () => {
        expect(wrapper.find('.test-settings-from-prev-course-select').exists()).toBeTruthy();
      });

      it('does not display "Use content settings from Previous Course Templates" select', () => {
        expect(
          wrapper.find('.test-settings-from-prev-course-template-select').exists()
        ).toBeFalsy();
      });
    });

    describe('when contentSettingsCourseSource is "template"', () => {
      beforeEach(() => {
        courseDataStore.store.course.contentSettingsCourseSource = 'template';
        wrapper = getWrapper();
      });

      it('does not display "Use content settings from Previous Courses" select', () => {
        expect(wrapper.find('.test-settings-from-prev-course-select').exists()).toBeFalsy();
      });

      it('displays "Use content settings from Previous Course Templates" select', () => {
        expect(
          wrapper.find('.test-settings-from-prev-course-template-select').exists()
        ).toBeTruthy();
      });
    });

    describe('when contentSettingsCourse does not have id', () => {
      beforeEach(() => {
        courseDataStore.store.settingsCourses.contentSettingsCourse.id = null;
        wrapper = getWrapper();
      });

      it('does not display "Copy instructor-created activities" checkbox', () => {
        expect(
          wrapper.find('.test-copy-instructor-created-activities-checkbox').exists()
        ).toBeFalsy();
      });

      it('does not display "Copy shared instructor-created activities" checkbox', () => {
        expect(
          wrapper.find('.test-copy-shared-instructor-created-activities-checkbox').exists()
        ).toBeFalsy();
      });
    });

    describe('when instAdmin is false and contentSettingsCourse has id', () => {
      beforeEach(() => {
        config.instAdmin = false;
        courseDataStore.store.settingsCourses.contentSettingsCourse.id = 1;
        wrapper = getWrapper();
      });

      it('displays "Copy instructor-created activities" checkbox', () => {
        expect(
          wrapper.find('.test-copy-instructor-created-activities-checkbox').exists()
        ).toBeTruthy();
      });
    });

    describe('when instAdmin is true and contentSettingsCourse has id', () => {
      beforeEach(() => {
        config.instAdmin = true;
        courseDataStore.store.settingsCourses.contentSettingsCourse.id = 1;
        wrapper = getWrapper();
      });

      it('displays "Copy shared instructor-created activities" checkbox', () => {
        expect(
          wrapper.find('.test-copy-shared-instructor-created-activities-checkbox').exists()
        ).toBeTruthy();
      });
    });
  });
});
