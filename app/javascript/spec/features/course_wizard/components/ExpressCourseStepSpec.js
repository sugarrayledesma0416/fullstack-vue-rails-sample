import { reactive } from 'vue';
import { mount } from '@vue/test-utils';
import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import ExpressCourseStep from 'features/course_wizard/components/ExpressCourseStep';
import Standards from 'features/course_wizard/components/content_step/settings/Standards';

jest.mock('features/course_wizard/services/course_options_http.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      settings: [],
      supported_standard_sets: ['standard_set_1', 'standard_set_2']
    };
  });
});

window.scrollTo = jest.fn();

const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  vol: true,
  isEnterprise: false,
};

const course = reactive(new Course());
course.pathType = 'express';
course.name = 'Test Course';
const courseDataStore = new CourseDataStore(
  course,
  config.instAdmin,
  config.isEnterprise,
  config.programId,
  config.schoolId
);

const getWrapper = () => {
  return mount(ExpressCourseStep, {
    global: {
      mocks: {
        $route: {
          name: 'express-course-step',
        },
      },
      provide: {
        config,
        courseDataStore,
      },
      stubs: {
        PreviewTable: true,
        SectionComponent: true,
        Standards: true,
        SettingCategory:true,
      },
    },
  });
};

/**
 * get a date in MMDDYYYY format
 * @param {date} date - given date.
 * @return {string}
 */
function formatDate(date) {
  let month = (date.getMonth() + 1).toString();
  let day = date.getDate().toString();
  const year = date.getFullYear().toString();
  if (month.length < 2) {
    month = '0' + month;
  }
  if (day.length < 2) {
    day = '0' + day;
  }
  return [month, day, year].join('/');
}

describe('ExpressCourseStep', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays the course name heading', () => {
      expect(wrapper.find('.test-course-name').text()).toBe('Test Course');
    });

    it('marks the correct breadcrumb as current', () => {
      const currentBreadcrumb = wrapper.find('.test-breadcrumb-title.title--is-current');
      expect(currentBreadcrumb.attributes('aria-current')).toBe('step');
      expect(currentBreadcrumb.text()).toBe('Details');
    });

    it('displays "PreviewTable" component', () => {
      expect(wrapper.findComponent({ name: 'PreviewTable' }).exists()).toBeTruthy();
    });

    it('displays "SectionComponent" component', () => {
      expect(wrapper.findComponent({ name: 'SectionComponent' }).exists()).toBeTruthy();
    });

    it('scrolls to the top of the page', () => {
      const scrollSpy = jest.spyOn(window, 'scrollTo');
      expect(scrollSpy).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('when course name greater than 75 characters', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const textInput = wrapper.get('.test-course-name-input');
      await textInput.setValue('11111111112222222222333333333344444444445555555555666666666677777777778888888888');
    });

    it('displays error "Your course name cannot be longer than 75 characters."', () => {
      expect(wrapper.get('.test-course-name-validation-error').text()).toBe(
        'Your course name cannot be longer than 75 characters.');
    });
  });

  describe('when course name blank', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const textInput = wrapper.get('.test-course-name-input');
      await textInput.setValue('some value');
      await textInput.setValue('');
    });

    it('displays error "Course name is required."', () => {
      expect(wrapper.get('.test-course-name-validation-error').text()).toBe(
        'Course name is required.');
    });
  });

  describe('when end date is before current date', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const date = new Date();
      date.setDate(date.getDate() - 1);
      const endDate = wrapper.get('.test-end-date');
      await endDate.setValue(formatDate(date));
    });

    it('displays error "Your end date cannot be in the past."', () => {
      expect(wrapper.get('.test-course-end-date-validation-error').text()).toBe(
        'Your end date cannot be in the past.');
    });
  });

  describe('when end date is before start date', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const startDate = wrapper.get('.test-start-date');
      const endDate = wrapper.get('.test-end-date');
      await startDate.setValue('2/11/2021');
      await endDate.setValue('1/11/2021');
    });

    it('displays error "Your end date cannot be before your start date."', () => {
      expect(wrapper.get('.test-course-date-validation-error').text()).toBe(
        'Your end date cannot be before your start date.');
    });
  });
  
  describe('when there are standard set up in the program', () => {
    it('renders SettingCategory with Standards component', () => {
      wrapper = getWrapper();

      let SettingCategory = wrapper.findComponent({ name: 'SettingCategory' });

      expect(SettingCategory.exists()).toBe(true);
      expect(SettingCategory.attributes('title')).toBe('Standards');
    });

    it('does not show standards error', () => {
      expect(wrapper.find('.test-standards-validation-error').exists()).toBe(false);
    });
  });

  describe('when there are no standard set up in the program', () => {
    beforeEach(() => {
      courseDataStore.store.courseOptions.supported_standard_sets = [];
      wrapper = getWrapper();
    });

    it('does not render SettingCategory with Standards component', () => {
      expect(wrapper.findComponent({ name: 'SettingCategory' }).exists()).toBe(false);
    });
  });
});
