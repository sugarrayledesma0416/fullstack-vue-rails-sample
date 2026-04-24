import { mount } from '@vue/test-utils';
import Expandable from 'features/learning_tracks/components/Expandable';

/**
 * @typeDef {ExpandablePropsObject}
 * @property {boolean} expand - Whether component is in expanded state
 */

/**
 * This method returns whether slot content is in expanded state.
 * We check presence of css class 'expanded' to assert collapsed or expanded state.
 * This is because component uses css transition and max-height value in css
 * to show/ hide the content instead of display:none etc.
 * So usual test methods isVisible() or exists() won't work.
 * @param {Wrapper} wrapper - wrapper for Expandable component
 * @return {boolean}
 */
function isContentExpanded(wrapper) {
  return wrapper.get('.test-expanded-body').classes('expanded');
}

let wrapper;
/**
 * This method gets wrapper for Expandable component
 * @param {ExpandablePropsObject} propsData - vue props for Expandable component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(Expandable, {
    propsData,
    slots: {
      default: '<div class="test-div-in-slot">content here</div>',
    },
  });
}

describe('Expandable', () => {
  describe('onMounted', () => {
    describe('when "expand" is false in the props', () => {
      beforeEach(() => {
        const propsData = { expand: false };
        wrapper = getWrapper(propsData);
      });

      it('contains provided content in the slot', () => {
        expect(
          wrapper.find('.test-expanded-body').html()
        ).toContain('<div class="test-div-in-slot">content here</div>');
      });

      it('does not show content', () => {
        expect(wrapper.find('.test-expanded-body').isVisible()).toBeFalsy();
      });

      it('has collapsed content without class "expanded"', () => {
        expect(isContentExpanded(wrapper)).toBeFalsy();
      });
    });

    describe('when "expand" is true in the props', () => {
      beforeEach(() => {
        const propsData = { expand: true };
        wrapper = getWrapper(propsData);
      });

      it('contains provided content in the slot', () => {
        expect(
          wrapper.find('.test-expanded-body').html()
        ).toContain('<div class="test-div-in-slot">content here</div>');
      });

      it('shows content', () => {
        expect(wrapper.find('.test-expanded-body').isVisible()).toBeTruthy();
      });

      it('has expanded content with class "expanded"', () => {
        expect(isContentExpanded(wrapper)).toBeTruthy();
      });
    });
  });
});
