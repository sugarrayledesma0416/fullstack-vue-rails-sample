import { mount } from '@vue/test-utils';
import FormItem from 'features/shared/FormItem';

let wrapper;
function getWrapper(data) {
  return mount(FormItem, { props: data });
}

describe('FormItem', () => {
  describe('when FormItem is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper({ label: 'First Name', inputId: 'first_name' });
    });

    it('adds a label element with a `for` attribute set to the inputId prop', () => {
      expect(wrapper.find('label').attributes('for')).toBe('first_name');
    });

    it('and the label contains the string value passed in', () => {
      expect(wrapper.find('label').text()).toBe('First Name');
    });
  });

  describe('when the `hint` prop is present', () => {
    beforeEach(() => {
      wrapper = getWrapper({ label: 'Temperature', inputId: 'temp', hint: 'Use Fahrenheit.' });
    });

    it('adds the hint element with the correct class and inner text', () => {
      const hintElm = wrapper.find('.form-item__hint');
      expect(hintElm.exists()).toBe(true);
      expect(hintElm.text()).toBe('Use Fahrenheit.');
    });
  });

  describe('when the `hideLabel` prop is true', () => {
    beforeEach(() => {
      wrapper = getWrapper({ label: 'Temperature', inputId: 'temp', hideLabel: true });
    });

    it('the label is present but hidden to sighted users', () => {
      const labelElm = wrapper.find('label');
      expect(labelElm.exists()).toBe(true);
      expect(labelElm.classes('u-screen-reader-only')).toBe(true);
    });
  });
});
