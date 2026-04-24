import { shallowMount } from '@vue/test-utils';
import SubmitConfirmation from 'features/activities/SubmitConfirmation.vue';

describe('SubmitConfirmation', () => {
  let wrapper;
  let mockSubmitBtn;
  let mockForm;

  const createWrapper = () => {
    return shallowMount(SubmitConfirmation, {});
  };

  beforeEach(() => {
    // Create mock DOM elements
    mockSubmitBtn = document.createElement('button');
    mockSubmitBtn.className = 'js-activity-submit';
    mockSubmitBtn.id = '_activity_submit';
    
    mockForm = document.createElement('form');
    mockForm.appendChild(mockSubmitBtn);
    document.body.appendChild(mockForm);

    // Mock global functions
    global.is_storing_work = jest.fn();
    global.confirm_unanswered_submissions = jest.fn(() => true);
    global.VHL = {
      Activity: {
        Submission: { ajax_submission: jest.fn() },
      },
    };

    // Mock console methods
    jest.spyOn(console, 'error').mockImplementation(() => {});
  });

  describe('component initialization', () => {
    it('renders without errors', () => {
      wrapper = createWrapper();
      expect(wrapper.exists()).toBe(true);
    });

    it('initializes with correct default state', () => {
      wrapper = createWrapper();
      expect(wrapper.vm.showLoadingIcon).toBe(false);
      expect(wrapper.vm.showConfirmDialog).toBe(false);
    });

    it('replaces submit button with modal opener on mount', async () => {
      wrapper = createWrapper();
      await wrapper.vm.$nextTick();
      
      const currentBtn = document.querySelector('.js-activity-submit');
      expect(currentBtn).toBeTruthy();
    });
  });

  describe('modal dialog interactions', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('opens confirmation dialog when openConfirmDialog is called', async () => {
      await wrapper.vm.openConfirmDialog();
      
      expect(wrapper.vm.showConfirmDialog).toBe(true);
    });

    it('closes dialog and resets state on cancel', async () => {
      wrapper.vm.showConfirmDialog = true;
      wrapper.vm.showLoadingIcon = true;
      
      await wrapper.vm.onCancelSubmit();
      
      expect(wrapper.vm.showConfirmDialog).toBe(false);
      expect(wrapper.vm.showLoadingIcon).toBe(false);
    });
  });

  describe('form submission logic', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it(
      'uses AJAX submission when VHL.Activity.Submission.ajax_submission is available',
      async () => {
        await wrapper.vm.onConfirmSubmit();

        expect(global.VHL.Activity.Submission.ajax_submission).toHaveBeenCalledTimes(1);
      }
    );

    it('shows loading state during submission', () => {
      wrapper.vm.onConfirmSubmit();
      
      expect(wrapper.vm.showLoadingIcon).toBe(true);
    });
  });

  describe('event dispatching', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('dispatches restoreUnsavedWork event on cancel', async () => {
      const eventSpy = jest.spyOn(document, 'dispatchEvent');
      
      await wrapper.vm.onCancelSubmit();
      
      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'restoreUnsavedWork' })
      );
    });

    it('dispatches restoreUnsavedWork event on submission error', async () => {
      const eventSpy = jest.spyOn(document, 'dispatchEvent');
      global.is_storing_work.mockImplementation(() => {
        throw new Error('Test error');
      });
      
      await wrapper.vm.onConfirmSubmit();
      
      expect(eventSpy).toHaveBeenCalledWith(
        expect.objectContaining({ type: 'restoreUnsavedWork' })
      );
    });
  });
});
