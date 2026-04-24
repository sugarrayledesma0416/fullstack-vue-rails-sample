import { mount } from '@vue/test-utils';
import GearMenu from 'features/category_wizard/components/GearMenu';

const menuItems= [
  { text: 'menu item text 1', id: 'menu-item-1' },
  { text: 'menu item text 2', id: 'menu-item-2' },
];

/**
 * This method gets wrapper for GearMenu component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(GearMenu, {
    propsData: {
      menuItems,
      linkText: 'some link text',
    },
  });
}

describe('GearMenu', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays menu opener link with given text', () => {
      expect(wrapper.get('.test-gear-menu-opener').text('some link text')).toBeTruthy();
    });

    it('does not display menu items', () => {
      expect(wrapper.find('.test-gear-menu').isVisible()).toBeFalsy();
    });
  });

  describe('when menu opener link is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      await wrapper.get('.test-gear-menu-opener').trigger('click');
    });

    it('displays menu opener link with given text', () => {
      expect(wrapper.get('.test-gear-menu-opener').text('some link text')).toBeTruthy();
    });

    it('displays menu', () => {
      expect(wrapper.get('.test-gear-menu').isVisible()).toBeTruthy();
    });

    it('displays 2 menu items', () => {
      expect(wrapper.findAll('.test-gear-menu-item').length).toBe(2);
    });

    it('displays menu item with text', () => {
      const itemElms = wrapper.findAll('.test-gear-menu-item');
      expect(itemElms[0].text('menu item text 1')).toBeTruthy();
    });
  });

  describe('when menu item is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const itemElms = wrapper.findAll('.test-gear-menu-item');
      await itemElms[0].trigger('click');
    });

    it('emits "click" event', () => {
      expect(wrapper.emitted().click).toBeTruthy();
    });

    it('hides menu items', () => {
      expect(wrapper.find('.test-gear-menu').isVisible()).toBeFalsy();
    });
  });
});
