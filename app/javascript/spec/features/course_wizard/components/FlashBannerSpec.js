import { mount } from '@vue/test-utils';
import FlashBanner from 'features/course_wizard/components/FlashBanner';

/**
 * @typeDef FlashBannerPropsObject
 * @property {string} message
 * @property {string} variant
 */

const propsData = {
  message: 'Some flash message text',
  variant: '',
};

let wrapper;

/**
 * This method gets wrapper for FlashBanner component
 * @param {FlashBannerPropsObject} propsData - vue props for FlashBanner component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(FlashBanner, { propsData });
}

describe('FlashBanner', () => {
  describe('when FlashBanner is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsData);
    });

    it('displays provided message', () => {
      expect(wrapper.text('Some flash message text')).toBeTruthy();
    });
  });

  describe('when variant prop is "error"', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ variant: 'error' }};
      wrapper = getWrapper(newData);
    });

    it('displays banner with variant class "flash-banner--error"', () => {
      expect(wrapper.classes('flash-banner--error')).toBeTruthy();
    });
  });
});
