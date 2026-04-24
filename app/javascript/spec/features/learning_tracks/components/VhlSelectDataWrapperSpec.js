import { mount } from '@vue/test-utils';
import VhlSelectDataWrapper from 'features/learning_tracks/components/VhlSelectDataWrapper';

let wrapper;

/**
 * This method gets wrapper for VhlSelectDataWrapper component
 * @return {Wrapper}
 */
function getWrapper() {
  const optionsArr = [
    {
      text: 'text 1',
      value: { someKey: 'some value 1' },
    },
    {
      text: 'text 2',
      value: { someKey: 'some value 2' },
    },
    {
      text: 'text 3',
      value: { someKey: 'some value 3' },
    },
  ];
  const initialOptionValue = optionsArr[1].value;
  return mount(VhlSelectDataWrapper, {
    props: {
      id: 'course-1',
      modelValue: initialOptionValue,
      options: optionsArr,
      testSelector: 'course-1',
    },
  });
}

describe('VhlSelectDataWrapper Component', () => {
  describe('mounted', () => {
    beforeEach(() => wrapper = getWrapper());

    it('displays BasicSelect component', () => {
      expect(wrapper.findComponent({ name: 'BasicSelect' }).exists()).toBeTruthy();
    });

    it('displays "text 2" as selected option', () => {
      expect(wrapper.get('.test-selected-option-item').text()).toBe('text 2');
    });
  });

  describe('when option is changed in the dropdown', () => {
    beforeEach(async () => {
      wrapper = getWrapper();
      const optionElm = wrapper.findAll('.test-option-item')[2];
      await optionElm.trigger('change');
    });

    it('emits "update:modelValue" event with item information', () => {
      expect(
        wrapper.emitted()['update:modelValue']
      ).toStrictEqual([[{ 'someKey': 'some value 3' }]]);
    });
  });
});
