import { mount } from '@vue/test-utils';
import FlashBannerComponent from 'features/flash_banner/FlashBannerComponent';

const setMessage = (message, data) => {
  message.announce = data.announce || message.announce;
  message.className = data.className || message.className;
  message.fadedOut = data.fadedOut || message.fadedOut;
  message.shown = data.shown || message.shown;
  message.text = data.text || message.text;
};

const testFlashMessageShown = async (wrapper, shown) => {
  setMessage(wrapper.vm.currentMessage, {
    shown,
  });
  await wrapper.vm.$nextTick();
  expect(wrapper.find('.test-flash-banner-group').exists()).toBe(shown);
};

const testFlashMessageClass = async (wrapper, text, className) => {
  setMessage(wrapper.vm.currentMessage, {
    shown: true,
    text,
    className,
  });
  await wrapper.vm.$nextTick();
  expect(wrapper.find(`.test-flash-banner--${className}`).exists()).toBeTruthy();
};

describe('FlashBannerComponent', () => {
  let wrapper;

  function getWrapper() {
    return mount(FlashBannerComponent);
  }

  describe('when message shown is true', () => {
    it('I can see div with class "test-flash-banner-group"', () => {
      testFlashMessageShown(getWrapper(), true);
    });

    describe('when message text is present', () => {
      it('I can see div with class ".test-flash-message" with the text', async () => {
        wrapper = getWrapper();
        setMessage(wrapper.vm.currentMessage, { shown: true, text: 'Successfully saved!' });
        await wrapper.vm.$nextTick();
        expect(wrapper.get('.test-flash-message').text()).toBe(
          'Successfully saved!'
        );
      });
    });

    describe('when message class is success', () => {
      it('I can see div with class ".test-flash-banner--success"', () => {
        testFlashMessageClass(
          getWrapper(),
          'Successfully saved!',
          'success'
        );
      });
    });

    describe('when message class is error', () => {
      it('I can see div with class ".test-flash-banner--error"', () => {
        testFlashMessageClass(
          getWrapper(),
          'Error!',
          'error'
        );
      });
    });
  });

  describe('when message shown is false', () => {
    it('I can not see div with class "test-flash-banner-group"', async () => {
      testFlashMessageShown(getWrapper(), false);
    });
  });

  describe('announce setting', () => {
    describe('when message announce is true', () => {
      it('I can see screen-reader div', async () => {
        wrapper = getWrapper();
        setMessage(
          wrapper.vm.currentMessage,
          { announce: true, shown: true, text: 'Successfully saved!' }
        );
        await wrapper.vm.$nextTick();
        expect(wrapper.get('.test-screen-reader').text()).toBe(
          'Successfully saved!'
        );
      });
    });

    describe('when message announce is false', () => {
      it('I cannot see screen-reader div', async () => {
        wrapper = getWrapper();
        setMessage(
          wrapper.vm.currentMessage,
          { announce: false, shown: true, text: 'Successfully saved!' }
        );
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-screen-reader').exists()).toBe(false);
      });
    });
  });

  describe('fadedOut setting', () => {
    describe('when message fadedOut is true', () => {
      it('flash-banner-group element has is-faded-out class', async () => {
        wrapper = getWrapper();
        setMessage(
          wrapper.vm.currentMessage,
          { fadedOut: true, shown: true, text: 'Successfully saved!' }
        );
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-flash-banner-group').classes('is-faded-out')).toBe(true);
      });
    });

    describe('when message fadedOut is false', () => {
      it('flash-banner-group element does not have is-faded-out class', async () => {
        wrapper = getWrapper();
        setMessage(
          wrapper.vm.currentMessage,
          { fadedOut: false, shown: true, text: 'Successfully saved!' }
        );
        await wrapper.vm.$nextTick();
        expect(wrapper.find('.test-flash-banner-group').classes('is-faded-out')).toBe(false);
      });
    });
  });
});
