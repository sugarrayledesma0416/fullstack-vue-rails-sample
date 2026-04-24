import { mount } from '@vue/test-utils';
import CourseSerializer from 'features/course_wizard/services/course_serializer.js';
import SummaryStep from 'features/course_wizard/components/SummaryStep';

window.scrollTo = jest.fn();

const config = {
  currentUser: { last_name: 'Stracke' },
  instAdmin: false,
  programId: '79',
  isVol: true,
};

const course = {
  name: 'Test Course',
  displayName: 'Test Course',
  endDate: '11/2/2021',
  firstUnitId: 1,
  lastUnitId: 2,
  level: 64,
  pathType: 'custom',
  startDate: '11/1/2021',
  categories: [],
  standardSetIds: [],
};

const courseDataStore = {
  newCourseMode: true,
  store: {
    course,
    courseOptions: {
      components: [],
      levels: [{ id: 64, name: 'Portales' }],
      program: {
        unit_label: 'Lession',
      },
      units: [
        { id: 1, label: 'Lession 1' },
        { id: 2, label: 'Lession 2' },
      ],
      supported_standard_sets: [],
    },
  },
  save: jest.fn(),
};
courseDataStore.courseSerializer = new CourseSerializer(course);

const getWrapper = () => {
  return mount(SummaryStep, {
    global: {
      mocks: {
        $route: {
          name: 'summary-step',
        },
      },
      provide: {
        config,
        courseDataStore,
      },
    },
  });
};

describe('SummaryStep', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays course name heading', () => {
      const courseName = wrapper.getComponent({ name: 'StepHeader' })
        .find('.test-course-name');
      expect(courseName.text()).toBe('Test Course');
    });

    it('marks the correct breadcrumb as current', () => {
      const currentBreadcrumb = wrapper.getComponent({ name: 'StepHeader' })
        .find('.test-breadcrumb-title.title--is-current');
      expect(currentBreadcrumb.attributes('aria-current')).toBe('step');
      expect(currentBreadcrumb.text()).toBe('Summary');
    });

    it('displays course start date', () => {
      expect(wrapper.get('.test-summary-start-date').text()).toBe('11/1/2021');
    });

    it('displays course end date', () => {
      expect(wrapper.get('.test-summary-end-date').text()).toBe('11/2/2021');
    });

    it('displays course first lession', () => {
      expect(wrapper.get('.test-summary-first-unit').text()).toBe('First Lession');
      expect(wrapper.get('.test-summary-first-unit-id').text()).toBe('Lession 1');
    });

    it('displays course last lession', () => {
      expect(wrapper.get('.test-summary-last-unit').text()).toBe('Last Lession');
      expect(wrapper.get('.test-summary-last-unit-id').text()).toBe('Lession 2');
    });

    it('displays access level', () => {
      expect(wrapper.get('.test-summary-access-level').text()).toBe('Access level Portales');
    });

    it('contains Gradebook Summary component', () => {
      expect(wrapper.findComponent({ name: 'GradebookSummary' }).exists()).toBeTruthy();
    });

    it('displays "Cancel" button which redirects to "instructor dashboard" url', () => {
      expect(
        wrapper.get('.test-cancel-btn').element.href
      ).toContain('/instructor/dashboard/79');
    });

    it('scrolls to the top of the page', () => {
      const scrollSpy = jest.spyOn(window, 'scrollTo');
      expect(scrollSpy).toHaveBeenCalledWith(0, 0);
    });
  });

  describe('when "Save" button is clicked', () => {
    let saveButton;

    beforeEach(() => {
      wrapper = getWrapper();
      saveButton = wrapper.get('.test-save-course');
    });

    it('calls the courseDataStore save', async () => {
      await saveButton.trigger('click');
      expect(courseDataStore.save).toHaveBeenCalled();
    });
  });
});
