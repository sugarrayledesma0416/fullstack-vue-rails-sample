import { mount } from '@vue/test-utils';
import VhlRadioButton from 'features/course_wizard/components/VhlRadioButton';

/**
 * @typeDef RadioButtonPropsObject
 * @property {boolean} disabled
 * @property {string} id
 * @property {boolean|number|string} modelValue
 * @property {string} name
 * @property {string} testSelectorInput
 * @property {string} text
 * @property {boolean|number|string} value
 */

let wrapper;

const propsData = {
  disabled: false,
  id: '',
  modelValue: false,
  name: 'some_name',
  testSelectorInput: 'rb-1',
  text: 'some radio button label',
  value: false,
};

/**
 * This method gets wrapper for VhlRadioButton component
 * @param {RadioButtonPropsObject} propsData - vue props for VhlRadioButton component
 * @return {Wrapper}
 */
function getWrapper(propsData) {
  return mount(VhlRadioButton, { propsData });
}

describe('VhlRadioButton', () => {
  beforeEach(() => wrapper = getWrapper(propsData));

  it('displays a label with text "checkbox label"', () => {
    expect(wrapper.get('.test-radio-button-label').text()).toBe('some radio button label');
  });
});

describe('when diabled value is false', () => {
  beforeEach(() => {
    const props = { ...propsData, ...{ disabled: false }};
    wrapper = getWrapper(props);
  });

  it('displays enabled radio button', () => {
    expect(wrapper.get('.test-rb-1').element).not.toBeDisabled;
  });
});

describe('when diabled value is true', () => {
  beforeEach(() => {
    const props = { ...propsData, ...{ disabled: true }};
    wrapper = getWrapper(props);
  });

  it('displays disabled radio button', () => {
    expect(wrapper.get('.test-rb-1').element).toBeDisabled;
  });
});

describe('when model value is not equal to value prop', () => {
  beforeEach(() => {
    const props = { ...propsData, ...{ value: false, modelValue: true }};
    wrapper = getWrapper(props);
  });

  it('displays unchecked radio button', () => {
    expect(wrapper.get('.test-rb-1').element.checked).toBeFalsy();
  });
});

describe('when model value is equal to value prop', () => {
  beforeEach(() => {
    const props = { ...propsData, ...{ value: true, modelValue: true }};
    wrapper = getWrapper(props);
  });

  it('displays checked radio button', () => {
    expect(wrapper.get('.test-rb-1').element.checked).toBeTruthy();
  });
});
