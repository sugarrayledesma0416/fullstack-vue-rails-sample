import Course from 'features/course_wizard/models/course';
import CourseDataStore from 'features/course_wizard/models/new_course_data_store';
import fetchMock from 'fetch-mock';
import GradebookStep from 'features/course_wizard/components/GradebookStep';
import { mount } from '@vue/test-utils';
import { reactive } from 'vue';

jest.mock('images/category_wizard/weighting_alert.png', () => '');

delete window.location;
window.location = new URL('http://example.com/new');
window.scrollTo = jest.fn();

const courseOptionsResponse = {
  settings: [{ id: 1, name: 'course 1', sections: [{ id: 314 }] }],
  supported_standard_sets: [],
};
const courseOptionsUrl = 'http://example.com/new.json';
fetchMock.mock(courseOptionsUrl, { status: 200, body: courseOptionsResponse });

const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  isVol: true,
  isEnterprise: false
};

const course = reactive(new Course());
course.name = 'New Course';
course.pathType = 'custom';
const courseDataStore = new CourseDataStore(
  course,
  config.instAdmin,
  config.isEnterprise,
  config.programId,
  config.schoolId
);

const getWrapper = () => {
  return mount(GradebookStep, {
    global: {
      mocks: {
        $route: {
          name: 'gradebook-step',
        },
      },
      provide: {
        config,
        courseDataStore,
      },
      stubs: { Tutorial: true, BasicSelect: true },
    },
  });
};

describe('GradebookStep Component', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays course heading as "New Course"', () => {
      const courseName = wrapper.getComponent({ name: 'StepHeader' })
        .find('.test-course-name');
      expect(courseName.text()).toBe('New Course');
    });

    it('marks the correct breadcrumb as current', () => {
      const currentBreadcrumb = wrapper.getComponent({ name: 'StepHeader' })
        .find('.test-breadcrumb-title.title--is-current');
      expect(currentBreadcrumb.attributes('aria-current')).toBe('step');
      expect(currentBreadcrumb.text()).toBe('Gradebook');
    });

    it('displays use settings label as "Use category settings from..."', () => {
      expect(
        wrapper.get('.test-copy-settings').text()
      ).toBe('Use category settings from...');
    });

    it('displays "BasicSelect" component for copying category settings', () => {
      expect(wrapper.findComponent({ name: 'BasicSelect' }).exists()).toBeTruthy();
    });

    it('displays "Gradebook Categories" in Gradebook Category heading', () => {
      expect(wrapper.get('.test-category-heading').text()).toContain('Gradebook Categories');
    });

    it('displays "Tutorial" component', () => {
      expect(wrapper.findComponent({ name: 'Tutorial' }).exists()).toBeTruthy();
    });

    it('displays "view tutorial" link as default', () => {
      expect(wrapper.get('.test-tutorial-disclosure-text').text()).toBe('View Tutorial');
    });

    it('scrolls to the top of the page', () => {
      const scrollSpy = jest.spyOn(window, 'scrollTo');
      expect(scrollSpy).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('on "view tutorial" disclosure click', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-tutorial-disclosure-text').trigger('click');
    });

    it('displays "hide tutorial" link as default', () => {
      expect(wrapper.get('.test-tutorial-disclosure-text').text()).toBe('Hide Tutorial');
    });
  });
});
