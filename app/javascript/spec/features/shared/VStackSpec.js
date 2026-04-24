import { mount } from '@vue/test-utils';
import VStack from 'features/shared/VStack';

let wrapper;
function getWrapper(data) {
  return mount(VStack, { props: data });
}

describe('VStack', () => {
  describe('when VStack is mounted', () => {
    it('adds an element with class `stack`', () => {
      wrapper = getWrapper();
      expect(wrapper.find('div').classes('stack')).toBe(true);
    });
  });

  describe('when the spacing prop is set to `lg`', () => {
    it('adds a class `stack--lg`', () => {
      wrapper = getWrapper({ spacing: 'lg' });
      expect(wrapper.find('div').classes('stack--lg')).toBe(true);
    });
  });

  describe('when the align prop is set to `end`', () => {
    beforeEach(() => {
      wrapper = getWrapper({ align: 'end' });
    });

    it('adds a class `stack--end`', () => {
      expect(wrapper.find('div').classes('stack--end')).toBe(true);
    });
  });

  describe('when no props are set', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('no modifier classes are added', () => {
      expect(wrapper.find('div[class*="--"]').exists()).toBe(false);
    });
  });
});
