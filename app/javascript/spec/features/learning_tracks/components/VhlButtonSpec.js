import { mount } from '@vue/test-utils';
import VhlButton from 'features/learning_tracks/components/VhlButton';

/**
 * @typeDef {VhlButtonPropsObject}
 * @property {boolean} disabled - Whether button is disabled
 * @property {string} featureVariant - Feature Variant of button
 * @property {string} state - Button state
 * @property {string} title - Title attribute of button
 * @property {string} type - Type attribute of button
 * @property {string} variant - Variant of button
 */

let wrapper;

const propsData = {
  disabled: false,
  featureVariant: '',
  state: 'default',
  title: 'some title',
  type: 'button',
  variant: '',
};

/**
 * This method gets wrapper for VhlButton component
 * @param {VhlButtonPropsObject} propsData - vue props for VhlButton component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(VhlButton, {
    propsData,
    slots: {
      default: '<div class="test-div-in-slot">button text</div>',
    },
  });
}

describe('VhlButton Component', () => {
  describe('mounted', () => {
    beforeEach(() => wrapper = getWrapper(propsData));

    it('displays button', () => {
      expect(wrapper.get('.test-vhl-button').exists()).toBeTruthy();
    });

    it('displays content in the slot', () => {
      expect(
        wrapper.find('.test-vhl-button').html()
      ).toContain('<div class="test-div-in-slot">button text</div>');
    });

    it('emits click event on click', async () => {
      await wrapper.get('.test-vhl-button').trigger('click');
      expect(wrapper.emitted().click).toBeTruthy();
    });
  });

  describe('when disabled prop is true', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ disabled: true }};
      wrapper = getWrapper(newData);
    });

    it('displays disabled button', () => {
      expect(wrapper.get('.test-vhl-button').element).toBeDisabled;
    });
  });

  describe('when variant prop is "primary"', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ variant: 'primary' }};
      wrapper = getWrapper(newData);
    });

    it('displays button with variant class "button--primary"', () => {
      expect(wrapper.get('.test-vhl-button').classes('button--primary')).toBeTruthy();
    });
  });

  describe('when featureVariant prop is "learning-tracks"', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ featureVariant: 'learning-tracks' }};
      wrapper = getWrapper(newData);
    });

    it('displays button with feature variant class "button--learning-tracks"', () => {
      expect(
        wrapper.get('.test-vhl-button').classes('button--learning-tracks')
      ).toBeTruthy();
    });
  });
});
