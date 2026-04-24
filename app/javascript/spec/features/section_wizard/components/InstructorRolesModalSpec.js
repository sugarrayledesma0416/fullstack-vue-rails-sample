import { mount } from '@vue/test-utils';
import InstructorRolesModal from 'features/section_wizard/components/InstructorRolesModal';

let wrapper;

/**
 * This method gets wrapper for InstructorRolesModal component
 * @return {Wrapper}
 */
function getWrapper() {
  return mount(InstructorRolesModal);
}

/**
 * This method simulates event triggering from given component
 * @param {Wrapper} wrapper - Wrapper for InstructorRolesModal component
 * @param {String} compName - Component name
 * @param {String} eventName - Event name to trigger
 */
async function triggerCompEvent(wrapper, compName, eventName) {
  const comp = wrapper.findComponent({ name: compName });
  await comp.vm.$emit(eventName);
}

describe('InstructorRolesModal', () => {
  beforeEach(() => {
    wrapper = getWrapper();
  });

  describe('when InstructorRolesModal is mounted', () => {
    it('displays co-instructor role information', () => {
      expect(wrapper.find('.test-co-instructor-role-info').exists()).toBeTruthy();
    });

    it('displays assistant role information', () => {
      expect(wrapper.find('.test-assistant-role-info').exists()).toBeTruthy();
    });

    it('triggers event "close" when receives it from "ModalComponent" component',
      async () => {
        await triggerCompEvent(wrapper, 'ModalComponent', 'close');
        expect(wrapper.emitted('close')).toHaveLength(1);
      }
    );
  });
});
