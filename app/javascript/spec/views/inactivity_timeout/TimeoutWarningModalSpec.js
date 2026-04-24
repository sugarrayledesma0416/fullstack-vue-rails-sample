import { mount } from '@vue/test-utils';
import TimeoutWarningModal from 'views/inactivity_timeout/TimeoutWarningModal';

let wrapper;

function getWrapper(remainingTime) {
  return mount(TimeoutWarningModal, {
    props: { remainingTime },
  });
}

describe('TimeoutWarningModal', () => {
  beforeEach(() => {
    wrapper = getWrapper(90);
  });

  it('emits "signout" event on "Sign out" button click', async () => {
    await wrapper.get('.test-cancel-timeout-btn').trigger('click');
    expect(wrapper.emitted().signout).toBeTruthy();
  });

  it('emits "confirm" event on "I m here" button click', async () => {
    await wrapper.get('.test-confirm-timeout-btn').trigger('click');
    expect(wrapper.emitted().confirm).toBeTruthy();
  });

  describe('when timer value is 90 seconds', () => {
    beforeEach(() => {
      const remainingTimeInSec = 90;
      wrapper = getWrapper(remainingTimeInSec);
    });

    it('displays warning text with round off timer value 2 minute', () => {
      const warningTextElm = wrapper.get('.test-timeout-warning');
      const expectedText = 'Please confirm you are still there. ' +
        'If not, you will be logged out in 2 minutes.';
      expect(warningTextElm.text()).toBe(expectedText);
    });
  });

  describe('when timer value is 50 seconds', () => {
    beforeEach(() => {
      const remainingTimeInSec = 50;
      wrapper = getWrapper(remainingTimeInSec);
    });

    it('displays warning text with round off timer value 1 minute', () => {
      const warningTextElm = wrapper.get('.test-timeout-warning');
      const expectedText = 'Please confirm you are still there. ' +
        'If not, you will be logged out in a minute.';
      expect(warningTextElm.text()).toBe(expectedText);
    });
  });
});
