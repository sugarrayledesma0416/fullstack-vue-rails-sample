import { mount } from '@vue/test-utils';
import SaveCourseModal from 'features/assignment_wizard/components/SaveCourseModal';

/**
 * @typeDef SaveCourseModalPropsType
 * @property {string} jobCompleteMsg
 * @property {string} jobInprogressMsg
 * @property {AssignmentWizard|LearningTracksStepDataStore} parentModel
 */

const jobProgress = {
  jobIds: [],
  isJobCompleted: false,
};

const parentModel = {
  jobProgress,
  returnToDashboard: jest.fn(),
};

const propsData = {
  jobCompleteMsg: '',
  jobInprogressMsg: '',
  parentModel,
};

/**
 * This method gets wrapper for SaveCourseModal component
 * @param {SaveCourseModalPropsType} propsData
 * @return {Wrapper}
 */
const getWrapper = (propsData) => {
  return mount(SaveCourseModal, {
    propsData,
  });
};

describe('SaveCourseModal', () => {
  let wrapper;

  describe('when the job to save course is not completed', () => {
    describe('when custom messages are not provided', () => {
      beforeEach(() => {
        jobProgress.isJobCompleted = false;
        wrapper = getWrapper(propsData);
      });

      it('displays heading "Setting up assignments for your course"', () => {
        expect(wrapper.get('.test-job-inprogress-msg__heading').text()).toBe(
          'Setting up assignments for your course'
        );
      });

      it('displays text "This will take a few moments."', () => {
        expect(wrapper.get('.test-job-inprogress-msg__text').text()).toBe(
          'This will take a few moments.'
        );
      });
    });

    describe('when custom messages are provided', () => {
      beforeEach(() => {
        jobProgress.isJobCompleted = false;
        const props = { ...propsData, ...{ jobInprogressMsg: 'job in progess custom mesage' }};
        wrapper = getWrapper(props);
      });

      it('displays heading "job in progess custom mesage"', () => {
        expect(wrapper.get('.test-job-inprogress-msg__heading').text()).toBe(
          'job in progess custom mesage'
        );
      });
    });
  });

  describe('when the jobs to save course are completed', () => {
    describe('when custom messages are not provided', () => {
      beforeEach(() => {
        jobProgress.isJobCompleted = true;
        wrapper = getWrapper(propsData);
      });

      it('displays heading "Assignments successfully created!"', () => {
        expect(wrapper.get('.test-job-complete-msg__heading').text()).toBe(
          'Assignments successfully created!'
        );
      });

      it('displays "OK" button', () => {
        expect(wrapper.get('.test-job-complete-msg button').text()).toBe(
          'OK'
        );
      });

      it('calls "returnToDashboard" on "OK" button click', async () => {
        await wrapper.get('.test-job-complete-msg button').trigger('click');
        expect(parentModel.returnToDashboard).toHaveBeenCalled();
      });
    });

    describe('when custom messages are provided', () => {
      beforeEach(() => {
        jobProgress.isJobCompleted = true;
        const props = { ...propsData, ...{ jobCompleteMsg: 'job completion custom mesage' }};
        wrapper = getWrapper(props);
      });

      it('displays heading "Assignments successfully created!"', () => {
        expect(wrapper.get('.test-job-complete-msg__heading').text()).toBe(
          'job completion custom mesage'
        );
      });
    });
  });

  describe('when the Ids of jobs to save course are present.', () => {
    beforeEach(() => {
      jobProgress.jobIds = ['1234'];
      wrapper = getWrapper(propsData);
    });

    it('displays the progress bar', () => {
      expect(wrapper.find('.test-save-course__progressbar').exists()).toBeTruthy();
    });
  });

  describe('when the Ids of jobs to save course are not present.', () => {
    beforeEach(() => {
      jobProgress.jobIds = [];
      wrapper = getWrapper(propsData);
    });

    it('does not display the progress bar', () => {
      expect(wrapper.find('.test-save-course__progressbar').exists()).toBeFalsy();
    });
  });
});
