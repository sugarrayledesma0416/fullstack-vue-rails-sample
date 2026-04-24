import { mount } from '@vue/test-utils';
import Icon from 'features/shared/Icon';

function getWrapper(data) {
  return mount(Icon, {
    data() {
      return data;
    },
  });
}

describe('Icon', () => {
  it('adds the c-svg class to the svg element', () => {
    const wrapper = getWrapper({ svg: '<svg></svg>' });
    expect(wrapper.find('svg').classes('c-svg')).toBe(true);
  });
});
