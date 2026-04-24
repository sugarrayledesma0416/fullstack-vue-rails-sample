import { mount } from '@vue/test-utils';
import TimeoutWarningApp from 'views/inactivity_timeout/TimeoutWarningApp';
import { reactive } from 'vue';

let wrapper;
function getInactivityTimeout(bShow, remainingTime) {
  return {
    confirmUserActivity: jest.fn(),
    dialogData: reactive({
      show: bShow,
      remainingTime,
    }),
    signOutUser: jest.fn(),
  };
}

function getWrapper(inactivityTimeout) {
  return mount(TimeoutWarningApp, {
    global: {
      provide: { inactivityTimeout },
      stubs: { TimeoutWarningModal: true },
    },
  });
}

let inactivityTimeout;
describe('TimeoutWarningModal', () => {
  describe('when reactive property "show" of dialogData in InactivityTimeout is true', () => {
    beforeEach(() => {
      const bShow = true;
      inactivityTimeout = getInactivityTimeout(bShow, 90);
      wrapper = getWrapper(inactivityTimeout);
    });

    it('displays TimeoutWarningModal component', () => {
      const modalComp = wrapper.getComponent({ name: 'TimeoutWarningModal' });
      expect(modalComp.isVisible()).toBeTruthy();
    });

    describe('when TimeoutWarningModal component emits "signout" event', () => {
      beforeEach(async () => {
        const modalComp = wrapper.getComponent({ name: 'TimeoutWarningModal' });
        await modalComp.vm.$emit('signout');
      });

      it('calls signOutUser method in inactivityTimeout', () => {
        expect(inactivityTimeout.signOutUser).toHaveBeenCalled();
      });

      it('does not call confirmUserActivity method in inactivityTimeout', () => {
        expect(inactivityTimeout.confirmUserActivity).not.toHaveBeenCalled();
      });
    });

    describe('when TimeoutWarningModal component emits "confirm" event', () => {
      beforeEach(async () => {
        const modalComp = wrapper.getComponent({ name: 'TimeoutWarningModal' });
        await modalComp.vm.$emit('confirm');
      });

      it('calls confirmUserActivity method in inactivityTimeout', () => {
        expect(inactivityTimeout.confirmUserActivity).toHaveBeenCalled();
      });

      it('does not call signOutUser method in inactivityTimeout', () => {
        expect(inactivityTimeout.signOutUser).not.toHaveBeenCalled();
      });
    });
  });

  describe('when reactive property "show" of dialogData in InactivityTimeout is false', () => {
    beforeEach(() => {
      const bShow = false;
      inactivityTimeout = getInactivityTimeout(bShow, 90);
      wrapper = getWrapper(inactivityTimeout);
    });

    it('does not display TimeoutWarningModal component', () => {
      const modalComp = wrapper.getComponent({ name: 'TimeoutWarningModal' });
      expect(modalComp.isVisible()).toBeFalsy();
    });
  });
});
