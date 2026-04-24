import { mount } from '@vue/test-utils';
import FormFeedback from 'features/shared/FormFeedback';

let wrapper;
function getWrapper(data) {
  return mount(FormFeedback, { props: data });
}

describe('FormFeedback', () => {
  describe('when FormFeedback has `type` of "error"', () => {
    beforeEach(() => {
      wrapper = getWrapper({ type: 'error' });
    });

    it('has a class with the "--error" modifier', () => {
      expect(wrapper.classes('form-item-feedback--error')).toBe(true);
    });
  });

  describe('when FormFeedback has `type` of "success"', () => {
    beforeEach(() => {
      wrapper = getWrapper({ type: 'success' });
    });

    it('has a class with the "--success" modifier', () => {
      expect(wrapper.classes('form-item-feedback--success')).toBe(true);
    });
  });
});
