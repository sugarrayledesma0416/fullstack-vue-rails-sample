import { mount } from '@vue/test-utils';
import Fieldset from 'features/shared/Fieldset';

let wrapper;
function getWrapper(data) {
  return mount(Fieldset, { props: data });
}

describe('Fieldset', () => {
  describe('when Fieldset is mounted', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('adds a fieldset element with class `fieldset`', () => {
      expect(wrapper.find('fieldset').classes('fieldset')).toBe(true);
    });

    it('adds a VStack element', () => {
      expect(wrapper.find('div').classes('stack')).toBe(true);
    });

    describe('when the legend prop is empty', () => {
      it('there is no legend child element', () => {
        const legendElm = wrapper.find('legend');
        expect(legendElm.exists()).toBe(false);
      });
    });
  });

  describe('when the legend prop is non-empty', () => {
    beforeEach(() => {
      wrapper = getWrapper({ legend: 'Biographical Info' });
    });

    it('adds a legend element', () => {
      const legendElm = wrapper.find('legend');
      expect(legendElm.exists()).toBe(true);
    });

    it('the legend contains the correct text', () => {
      const legendElm = wrapper.find('legend');
      expect(legendElm.exists()).toBe(true);
      expect(legendElm.text()).toEqual('Biographical Info');
    });
  });
});
