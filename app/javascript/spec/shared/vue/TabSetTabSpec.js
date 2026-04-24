import { reactive } from 'vue';
import { mount } from '@vue/test-utils';

import TabSetTab from 'shared/vue/TabSetTab';

describe(
  'TabSetTab',
  () => {
    let tabs;
    let wrapper;
    const label = 'tab2';

    function getWrapper() {
      return mount(
        TabSetTab,
        {
          global: {
            provide: { tabs: tabs }
          },
          props: { label: label }
        }
      );
    }

    beforeEach(
      () => {
        tabs = reactive(
          [
            { label: 'tab1', selected: true },
            { label: 'tab2', selected: false }
          ]
        );
      }
    );

    it(
      'shows the tab contents if the current tab ' +
      'is marked as selected in the tab data',
      () => {
        tabs[1].selected = true;
        wrapper = getWrapper();
        const divElm = wrapper.get('div');

        expect(divElm.isVisible()).toBeTruthy();
      }
    );

    it(
      'does not show the tab contents if the current ' +
      'tab is not marked as selected in the data',
      () => {
        tabs[1].selected = false;
        wrapper = getWrapper();
        const divElm = wrapper.get('div');

        expect(divElm.isVisible()).toBeFalsy();
      }
    );
  }
)
