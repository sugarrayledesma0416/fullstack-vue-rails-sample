import { mount } from '@vue/test-utils';
import SectionModal from 'features/course_wizard/components/SectionModal';

const saveCourseResponse = { id: 1, name: 'Test Course' };
const courseDataStore = {
  store: { saveCourseResponse },
  courseHttp: {
    gotoSectionWizard: jest.fn(),
    returnToDashboard: jest.fn(),
  },
};

const getWrapper = () => {
  return mount(SectionModal, {
    global: {
      provide: {
        courseDataStore,
      },
    },
  });
};

describe('SectionModal', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays a message "Do you want to create a section for this course?"', () => {
      expect(wrapper.get('.test-section-modal-body').text()).toBe(
        'Do you want to create a section for this course?'
      );
    });
  });

  describe('when "Yes" is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-section-modal-yes');
      await inputElm.trigger('click');
    });

    it('redirects to section wizard', () => {
      expect(courseDataStore.courseHttp.gotoSectionWizard).toHaveBeenCalledWith(
        saveCourseResponse
      );
    });
  });

  describe('when "No" is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const inputElm = wrapper.get('.test-section-modal-no');
      await inputElm.trigger('click');
    });

    it('redirects to instructor dashboard', () => {
      expect(courseDataStore.courseHttp.returnToDashboard).toHaveBeenCalledWith(
        saveCourseResponse
      );
    });
  });
});
