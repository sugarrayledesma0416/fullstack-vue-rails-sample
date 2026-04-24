import { mount } from '@vue/test-utils';
import FeedbackDisableModal from 'features/category_wizard/components/FeedbackDisableModal';

/**
 * This method gets wrapper for FeedbackDisableModal component
 * @return {VueWrapper}
 */
const getWrapper = () => {
  return mount(FeedbackDisableModal);
};

describe('FeedbackDisableModal', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays "ModalComponent" component', () => {
      expect(wrapper.findComponent({ name: 'ModalComponent' }).exists()).toBeTruthy();
    });

    it('displays text "Are you sure? This will make it harder for students to see "' +
       '"why their responses are incorrect."', () => {
      expect(wrapper.get('.test-feedback-disable-warning').text()).toBe(
        'Are you sure? This will make it harder for students to see ' +
        'why their responses are incorrect.'
      );
    });
  });

  describe('when close is triggered on "ModalComponent"', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const modalComp = wrapper.findComponent({ name: 'ModalComponent' });
      await modalComp.vm.$emit('close');
    });

    it('emits "close" event.', () => {
      expect(wrapper.emitted().close).toBeTruthy();
    });
  });
});
