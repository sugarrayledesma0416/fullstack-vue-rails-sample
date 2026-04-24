import { mount } from '@vue/test-utils';
import VhlExpander from 'features/learning_tracks/components/VhlExpander';

/**
 * @typeDef {VhlExpanderPropsObject}
 * @property {string} headerText - Header text
 */

const propsData = { headerText: 'Some header text' };

let wrapper;
/**
 * This method gets wrapper for VhlExpander component
 * @param {VhlExpanderPropsObject} propsData - vue props for VhlExpander component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(VhlExpander, {
    propsData,
    slots: {
      default: '<div class="test-div-in-slot">content here</div>',
    },
  });
}

/**
 * This method returns whether child component 'Expandable' is in expanded state
 * based on its 'expand' vue prop value.
 * @param {Wrapper} wrapper - wrapper for VhlExpander component
 * @return {boolean}
 */
function isContentExpanded(wrapper) {
  const childComp = wrapper.findComponent({ name: 'Expandable' });
  return childComp.componentVM.expand;
}

let expanderButtonElm;
describe('VhlExpander', () => {
  describe('onMounted', () => {
    beforeEach(() => {
      wrapper = getWrapper(propsData);
    });

    it('displays "Some header text" text on header', () => {
      expect(wrapper.get('.test-expander-header-text').text()).toBe('Some header text');
    });

    it('displays expander button without class "is-expanded"', () => {
      expect(wrapper.get('.test-expander-button').classes('is-expanded')).toBeFalsy();
    });

    it('displays expander icon on header', () => {
      expect(wrapper.get('.test-expander-image').exists()).toBeTruthy();
    });

    it('displays "Expandable" component', () => {
      expect(wrapper.findComponent({ name: 'Expandable' }).exists()).toBeTruthy();
    });

    it('contains provided content in the slot', () => {
      expect(
        wrapper.find('.test-expander-body').html()
      ).toContain('<div class="test-div-in-slot">content here</div>');
    });

    it('has collapsed content', () => {
      expect(isContentExpanded(wrapper)).toBeFalsy();
    });
  });

  describe('when expander button is clicked', () => {
    beforeEach(async () => {
      wrapper = getWrapper(propsData);
      expanderButtonElm = wrapper.get('.test-expander-button');
      await expanderButtonElm.trigger('click');
    });

    it('displays expander button with class "is-expanded"', () => {
      expect(wrapper.get('.test-expander-button').classes('is-expanded')).toBeTruthy();
    });

    it('contains provided content in the slot', () => {
      expect(
        wrapper.find('.test-expander-body').html()
      ).toContain('<div class="test-div-in-slot">content here</div>');
    });

    it('has expanded content', () => {
      expect(isContentExpanded(wrapper)).toBeTruthy();
    });

    describe('when expander button is clicked again', () => {
      it('has collapsed content', async () => {
        await expanderButtonElm.trigger('click');
        expect(isContentExpanded(wrapper)).toBeFalsy();
      });
    });
  });
});
