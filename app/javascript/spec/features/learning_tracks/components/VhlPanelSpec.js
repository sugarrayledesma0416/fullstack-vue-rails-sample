import { mount } from '@vue/test-utils';
import VhlPanel from 'features/learning_tracks/components/VhlPanel';

let wrapper;

const propsData = {
  featureVariant: '',
  state: '',
  variant: '',
};

/**
 * This method gets wrapper for VhlPanel component
 * @param {Object} propsData - vue props for VhlPanel component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(VhlPanel, {
    propsData,
    slots: {
      header: '<div class="test-div-in-header-slot">header text</div>',
      body: '<div class="test-div-in-body-slot">body text</div>',
      footer: '<div class="test-div-in-footer-slot">footer text</div>',
    },
  });
}

describe('VhlPanel Component', () => {
  describe('mounted', () => {
    beforeEach(() => wrapper = getWrapper(propsData));

    it('displays panel', () => {
      expect(wrapper.get('.test-vhl-panel').exists()).toBeTruthy();
    });

    it('displays panel with standard variant class "panel"', () => {
      expect(wrapper.get('.test-vhl-panel').classes('panel')).toBeTruthy();
    });

    it('displays content in the header slot', () => {
      expect(
        wrapper.find('.test-panel-header').html()
      ).toContain('<div class="test-div-in-header-slot">header text</div>');
    });

    it('displays content in the body slot', () => {
      expect(
        wrapper.find('.test-panel-body').html()
      ).toContain('<div class="test-div-in-body-slot">body text</div>');
    });

    it('displays content in the footer slot', () => {
      expect(
        wrapper.find('.test-panel-footer').html()
      ).toContain('<div class="test-div-in-footer-slot">footer text</div>');
    });
  });

  describe('when variant prop is "padded"', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ variant: 'padded' }};
      wrapper = getWrapper(newData);
    });

    it('displays panel with variant class "panel--padded"', () => {
      expect(wrapper.get('.test-vhl-panel').classes('panel--padded')).toBeTruthy();
    });
  });

  describe('when featureVariant prop is "learning-tracks"', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ featureVariant: 'learning-tracks' }};
      wrapper = getWrapper(newData);
    });

    it('displays panel with feature variant class "panel--learning-tracks"', () => {
      expect(
        wrapper.get('.test-vhl-panel').classes('panel--learning-tracks')
      ).toBeTruthy();
    });
  });

  describe('when state prop is "active"', () => {
    beforeEach(() => {
      const newData = { ...propsData, ...{ state: 'active' }};
      wrapper = getWrapper(newData);
    });

    it('displays panel with state class "is-active"', () => {
      expect(
        wrapper.get('.test-vhl-panel').classes('is-active')
      ).toBeTruthy();
    });
  });
});
