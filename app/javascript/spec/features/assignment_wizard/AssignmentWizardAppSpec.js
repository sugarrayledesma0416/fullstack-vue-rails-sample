import { mount } from '@vue/test-utils';
import AssignmentWizardApp from 'features/assignment_wizard/AssignmentWizardApp';

const loadingIconPath = '/images/loading_32.gif';
const programId = 14;
const courseId = 12345;
const sectionId = 99;
const categories = [{ 'Category 1': 'blah', 'Category 2': 'blah' }];
const courseInfo = { name: 'testCourse', categories };

jest.mock('features/assignment_wizard/models/assignment_wizard_init_data.js', () => {
  return jest.fn().mockImplementation(() => {
    return {
      fetchCourseAndTrackDataAndUpdateModel: jest.fn(),
    };
  });
});

window.VHL = {
  Common: {
    parse_query_string: () => {
      return { section_id: sectionId };
    },
  },
};

delete window.location;
const locationUrl = `http://example.com/instructor/${programId}/course/${courseId}/` +
  `assignment_wizard?section_id=${sectionId}`;
window.location = new URL(locationUrl);

const getWrapper = () => {
  return mount(AssignmentWizardApp, {
    global: {
      stubs: {
        LearningTrackApp: true,
        CategoryMapping: true,
        SaveCourseModal: true,
      },
    },
    props: { loadingIconPath },
  });
};

let wrapper;

describe('AssignmentWizardApp', () => {
  describe('onMounted', () => {
    beforeEach(() => wrapper = getWrapper());

    it('disables the save button', () => {
      expect(wrapper.get('.test-assignment-wizard-save').element).toBeDisabled();
    });

    it('displays "LearningTrackApp" component', () => {
      expect(wrapper.findComponent({ name: 'LearningTrackApp' }).exists()).toBeTruthy();
    });

    it('does not displays "CategoryMapping" component', () => {
      expect(wrapper.findComponent({ name: 'CategoryMapping' }).exists()).toBeFalsy();
    });

    it('does not displays "SaveCourseModal" component', () => {
      expect(wrapper.findComponent({ name: 'SaveCourseModal' }).exists()).toBeFalsy();
    });
  });

  describe('when assignmentWizard.store.courseInfo is present', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.assignmentWizard.store.courseInfo = courseInfo;
      await wrapper.vm.$nextTick();
    });

    it('displays course name', () => {
      expect(wrapper.get('.test-course-name').text()).toBe('testCourse');
    });
  });

  describe('when CategoryMapping component is visible', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.assignmentWizard.store.categoryMappingList = [
        'Credit',
        'Graded',
        'Quizzes',
        'Tests',
      ];
      wrapper.vm.localstore.showCategoryMapping = true;
      wrapper.vm.assignmentWizard.store.categories = categories;
      wrapper.vm.assignmentWizard.store.courseInfo = courseInfo;
      wrapper.vm.assignmentWizard.store.usingPredefinedTrack = false;
      await wrapper.vm.$nextTick();
    });

    it('displays "CategoryMapping" component', () => {
      expect(wrapper.findComponent({ name: 'CategoryMapping' }).exists()).toBeTruthy();
    });
  });

  describe('when SaveCourseModal component is visible', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      wrapper.vm.assignmentWizard.jobProgress.shouldShow = true;
      await wrapper.vm.$nextTick();
    });

    it('displays "SaveCourseModal" component', () => {
      expect(wrapper.findComponent({ name: 'SaveCourseModal' }).exists()).toBeTruthy();
    });
  });
});
