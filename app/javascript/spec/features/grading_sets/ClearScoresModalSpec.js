import { mount } from '@vue/test-utils';
import ClearScoresModal from 'features/grading_sets/ClearScoresModal';

function getWrapper() {
  return mount(
    ClearScoresModal
  );
}

describe('ClearScoresModal', () => {
  let wrapper;

  beforeEach(
    () => {
      wrapper = getWrapper();
    }
  );

  describe('Clicking the cancel button', () => {
    it('Emits a closeClearScoresModal event', async () => {
      wrapper.find('.test-close-modal').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted().closeClearScoresModal).toBeTruthy();
    });
  });

  describe('Clicking the close modal x', () => {
    it('Emits a closeClearScoresModal event', async () => {
      wrapper.find('.test-modal-close-button').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted().closeClearScoresModal).toBeTruthy();
    });
  });

  describe('Clicking the Clear Scores button', () => {
    it('Emits a toggleGradingMethod event', async () => {
      wrapper.find('.test-clear-scores').trigger('click');
      await wrapper.vm.$nextTick();
      expect(wrapper.emitted().toggleGradingMethod).toBeTruthy();
    });
  });
});

