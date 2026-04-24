import { mount } from '@vue/test-utils';
import Screenshot from 'features/course_wizard/components/Screenshot';

/**
 * @typeDef ScreenshotPropsObject
 * @property {string} mode
 * @property {string} title
 */

let wrapper;

/**
 * This method gets wrapper for Screenshot component
 * @param {ScreenshotPropsObject} propsData - vue props for Screenshot component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(Screenshot, { propsData });
}

/**
 * This method simulates event triggering from given component
 * @param {Wrapper} wrapper - Wrapper for Screenshot component
 * @param {String} compName - Component name
 * @param {String} eventName - Event name to trigger
 */
async function triggerCompEvent(wrapper, compName, eventName) {
  const comp = wrapper.findComponent({ name: compName });
  await comp.vm.$emit(eventName);
}

describe('Screenshot', () => {
  beforeEach(() => {
    const propsData = {
      mode: 'subtitle',
      title: 'some title',
    };
    wrapper = getWrapper(propsData);
  });

  describe('when Screenshot is mounted', () => {
    it('displays "ModalComponent" component', () => {
      expect(wrapper.findComponent({ name: 'ModalComponent' }).exists()).toBeTruthy();
    });

    it('displays screenshot body with mode specific css class', () => {
      expect(wrapper.get('.test-screenshot-body').classes('screenshot--subtitle')).toBeTruthy();
    });

    it('triggers event "close" when receives it from "ModalComponent" component',
      async () => {
        await triggerCompEvent(wrapper, 'ModalComponent', 'close');
        expect(wrapper.emitted('close')).toHaveLength(1);
      }
    );
  });
});
