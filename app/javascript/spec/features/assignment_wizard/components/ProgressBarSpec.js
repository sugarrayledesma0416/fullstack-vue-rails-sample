import { mount } from '@vue/test-utils';
import ProgressBar from 'features/assignment_wizard/components/ProgressBar';

const label = '10%';
const value = 10;
let wrapper;

function getWrapper() {
  return mount(ProgressBar, {
    props: {
      label, value,
    },
  });
}

describe('ProgressBar', () => {
  beforeEach(() => wrapper = getWrapper());

  it('displays the progress bar label', () => {
    expect(wrapper.get('.test-progress-label').text()).toBe('10%');
  });

  it('applies the expected width on progressbar value', () => {
    const elm = wrapper.get('.test-progress-value').element;
    expect(elm.style.getPropertyValue('width')).toBe('10%');
  });
});
