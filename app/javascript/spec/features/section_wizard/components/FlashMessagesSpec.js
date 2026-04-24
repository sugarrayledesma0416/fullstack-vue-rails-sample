import { mount } from '@vue/test-utils';
import FlashMessages from 'features/section_wizard/components/FlashMessages';

const props = {
  showError: false,
  showNotice: false,
};

let wrapper;

/**
 * This method gets wrapper for FlashMessages component
 * @param {Object} propsData - vue props for FlashMessages component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(FlashMessages, { propsData });
}

describe('FlashMessages', () => {
  describe('when FlashMessages is mounted', () => {
    describe('when "showError" is false', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showError: false }};
        wrapper = getWrapper(propsData);
      });

      it('does not display flash error', () => {
        expect(wrapper.find('.test-section-wizard-flash-error').exists()).toBeFalsy();
      });
    });

    describe('when "showError" is true', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showError: true }};
        wrapper = getWrapper(propsData);
      });

      it('displays flash error', () => {
        expect(wrapper.find('.test-section-wizard-flash-error').exists()).toBeTruthy();
      });
    });

    describe('when "showNotice" is false', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showNotice: false }};
        wrapper = getWrapper(propsData);
      });

      it('does not display flash notice', () => {
        expect(wrapper.find('.test-section-wizard-flash-notice').exists()).toBeFalsy();
      });
    });

    describe('when "showNotice" is true', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showNotice: true }};
        wrapper = getWrapper(propsData);
      });

      it('displays flash notice', () => {
        expect(wrapper.find('.test-section-wizard-flash-notice').exists()).toBeTruthy();
      });
    });
  });
});
