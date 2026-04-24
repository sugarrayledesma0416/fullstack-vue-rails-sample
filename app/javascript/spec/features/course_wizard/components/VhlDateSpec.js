import { mount } from '@vue/test-utils';
import VhlDate from 'features/course_wizard/components/VhlDate';

const modelValue = '11/01/2021';

const getWrapper = () => {
  return mount(VhlDate, {
    props: {
      modelValue,
      testSelector: 'date-input',
    },
  });
};

describe('VhlDate', () => {
  let wrapper;

  describe('mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('displays input with modelValue as its value', () => {
      expect(wrapper.get('.test-date-input').element.value).toBe(modelValue);
    });
  });

  describe('when date is changed', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const input = wrapper.get('.test-date-input');
      await input.setValue('11/01/2021');
    });

    it('emits "update:modelValue" event', () => {
      expect(wrapper.emitted()['update:modelValue']).toBeTruthy();
    });
  });

  describe('when "changeDate" event is triggered on input', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const input = wrapper.get('.test-date-input');
      await input.trigger('changeDate');
    });

    it('emits "update:modelValue" event', () => {
      expect(wrapper.emitted()['update:modelValue']).toBeTruthy();
    });
  });
});
