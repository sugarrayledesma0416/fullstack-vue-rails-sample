import { mount } from '@vue/test-utils';
import * as ajaxUtils from 'shared/ajax_utils';
import PasswordScreen from 'features/assessment/components/PasswordScreen.vue';

jest.mock('shared/ajax_utils');

function getWrapper(props) {
  return mount(PasswordScreen, { props });
}

describe('PasswordScreen.vue', () => {
  let wrapper;

  beforeEach(() => {
    wrapper = getWrapper({
      requestPath: '/sections/123/activities/456',
      returnUrl: '/programs/79/section/123/assessment#past_assessments',
    });
  });

  describe('renders correctly', () => {
    it('renders the header title', () => {
      expect(
        wrapper.find('.test-password-header-title').text()
      ).toBe('Password Required');
    });

    it('renders the info text', () => {
      expect(
        wrapper.find('.test-enter-password-info').text()
      ).toBe('Enter the password required to begin this assessment.');
    });

    it('renders the password input field', () => {
      expect(wrapper.find('.test-password-input').exists()).toBeTruthy();
    });

    it('sets the correct section_id value', () => {
      expect(wrapper.find('.test-section-id').element.value).toBe('123');
    });

    it('sets the correct activity_id value', () => {
      expect(wrapper.find('.test-activity-id').element.value).toBe('456');
    });
  });

  describe('password input updates', () => {
    it('updates the password input when typing', async () => {
      const passwordInput = wrapper.find('.test-password-input');
      await passwordInput.setValue('test_password');
      expect(wrapper.vm.passwordInput).toBe('test_password');
    });
  });

  describe('continue button functionality', () => {
    let unlockAssessmentMock;

    beforeEach(() => {
      unlockAssessmentMock = jest.fn();
      wrapper.vm.unlockAssessment = unlockAssessmentMock;
    });

    it('calls unlockAssessment method when clicked', async () => {
      await wrapper.find('.test-password-continue').trigger('click');
      expect(unlockAssessmentMock).toHaveBeenCalled();
    });
  });

  describe('unlockAssessment method behavior', () => {
    describe('when fails', () => {
      beforeEach(async () => {
        ajaxUtils.postToEndpoint.mockImplementation((url, data, callback) => {
          callback({ success: false, error: 'Invalid password' });
        });

        wrapper.vm.passwordInput = 'wrong_password';
        await wrapper.find('.test-password-continue').trigger('click');
      });

      it('shows error message', () => {
        expect(wrapper.vm.errorMessage).toBe('Invalid password');
      });

      it('clears the password input', () => {
        expect(wrapper.vm.passwordInput).toBe('');
      });

      it('displays the correct error message', () => {
        expect(wrapper.find('.test-password-error-message').text()).toBe('Invalid password');
      });
    });

    describe('when succeeds', () => {
      beforeEach(async () => {
        ajaxUtils.postToEndpoint.mockImplementation((url, data, callback) => {
          callback({ success: true });
        });

        wrapper.vm.passwordInput = 'correct_password';
        await wrapper.find('.test-password-continue').trigger('click');
      });

      it('emits unlockAssessment event', () => {
        expect(wrapper.emitted().unlockAssessment).toBeTruthy();
      });

      it('emits unlockAssessment event with correct payload', () => {
        expect(wrapper.emitted().unlockAssessment[0]).toEqual([false]);
      });

      it('clears the error message', () => {
        expect(wrapper.vm.errorMessage).toBe('');
      });
    });
  });

  describe('cancel button functionality', () => {
    it('redirects to returnUrl when clicked', async () => {
      delete window.location;
      window.location = { href: '' };

      await wrapper.find('.test-password-cancel').trigger('click');

      expect(
        window.location.href
      ).toBe('/programs/79/section/123/assessment#past_assessments');
    });
  });
});
