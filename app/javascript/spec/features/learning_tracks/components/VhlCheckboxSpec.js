import { mount } from '@vue/test-utils';
import VhlCheckbox from 'features/learning_tracks/components/VhlCheckbox';

let checked = true;
let disabled = false;
let wrapper;

function getWrapper() {
  return mount(VhlCheckbox, {
    props: {
      checked,
      disabled,
      id: '1',
      testSelectorInput: 'cb-1',
      testSelectorLabel: 'cb-label-1',
    },
    slots: {
      default: 'checkbox label',
    },
  });
}

describe('VhlCheckbox', () => {
  beforeEach(() => wrapper = getWrapper());

  it('displays a label with text "checkbox label"', () => {
    expect(wrapper.get('.test-cb-label-1').text()).toBe('checkbox label');
  });
});

describe('when diabled value is false', () => {
  beforeEach(() => {
    disabled = false;
    wrapper = getWrapper();
  });

  it('displays enabled checkbox', () => {
    expect(wrapper.get('.test-cb-1').element).not.toBeDisabled;
  });
});

describe('when diabled value is true', () => {
  beforeEach(() => {
    disabled = true;
    wrapper = getWrapper();
  });

  it('displays disabled checkbox', () => {
    expect(wrapper.get('.test-cb-1').element).toBeDisabled;
  });
});

describe('when checked value is false', () => {
  beforeEach(() => {
    checked = false;
    wrapper = getWrapper();
  });

  it('displays unchecked checkbox', () => {
    expect(wrapper.get('.test-cb-1').element.checked).toBeFalsy();
  });
});

describe('when checked value is true', () => {
  beforeEach(() => {
    checked = true;
    wrapper = getWrapper();
  });

  it('displays checked checkbox', () => {
    expect(wrapper.get('.test-cb-1').element.checked).toBeTruthy();
  });
});
