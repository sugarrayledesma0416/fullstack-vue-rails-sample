import { mount } from '@vue/test-utils';
import FlashMessages from 'features/course_wizard/components/FlashMessages';

/**
 * @typeDef FlashMessagesPropsObject
 * @property {string} flashError
 * @property {string} flashNotice
 * @property {boolean} showError
 * @property {boolean} showNotice
 */

const props = {
  flashError: 'Some error text',
  flashNotice: 'Some notice text',
  showError: false,
  showNotice: false,
};

let wrapper;

/**
 * This method gets wrapper for FlashMessages component
 * @param {FlashMessagesPropsObject} propsData - vue props for FlashMessages component
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
        expect(wrapper.find('.test-course-wizard-flash-error').exists()).toBeFalsy();
      });
    });

    describe('when "showError" is true', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showError: true }};
        wrapper = getWrapper(propsData);
      });

      it('displays flash error with message text provided via prop "flashError"', () => {
        expect(wrapper.get('.test-course-wizard-flash-error').text('Some error text')).toBeTruthy();
      });
    });

    describe('when "showNotice" is false', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showNotice: false }};
        wrapper = getWrapper(propsData);
      });

      it('does not display flash notice', () => {
        expect(wrapper.find('.test-course-wizard-flash-notice').exists()).toBeFalsy();
      });
    });

    describe('when "showNotice" is true', () => {
      beforeEach(() => {
        const propsData = { ...props, ...{ showNotice: true }};
        wrapper = getWrapper(propsData);
      });

      it('displays flash notice with message text provided via prop "flashNotice"', () => {
        expect(
          wrapper.get('.test-course-wizard-flash-notice').text('Some notice text')
        ).toBeTruthy();
      });
    });
  });
});
