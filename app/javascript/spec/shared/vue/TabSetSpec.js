import { reactive } from 'vue';
import { mount } from '@vue/test-utils';

import TabSet from 'shared/vue/TabSet';

describe(
  'TabSet',
  () => {
    let tabs;
    let wrapper;
    const label = 'My TabSet';

    function getWrapper() {
      return mount(
        TabSet,
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
      'renders a div with the aria-label set to the label prop',
      () => {
        wrapper = getWrapper();
        const tabListElm = wrapper.get('.test-tab-list');

        expect(tabListElm.attributes('aria-label')).toEqual('My TabSet');
      }
    );

    it(
      'sets the is-selected class on the link for the tab that is marked ' +
      'as selected in the tab data',
      () => {
        wrapper = getWrapper();
        const tabLinkElm = wrapper.findAll('a')[0];
        expect(tabLinkElm.classes()).toContain('is-selected');
      }
    );

    it(
      'does not set the is-selected class on the links for tabs that are ' +
      'not marked as selected in the data',
      () => {
        wrapper = getWrapper();
        const tabLinkElm = wrapper.findAll('a')[1];
        expect(tabLinkElm.classes()).not.toContain('is-selected');
      }
    );

    describe(
      'clicking on the link for an unselected tab',
      () => {
        beforeEach(
          async () => {
            wrapper = getWrapper();
            const tabLinkElm = wrapper.findAll('a')[1];

            await tabLinkElm.trigger('click');
          }
        )

        it(
          'marks the clicked tab as selected',
          () => {
            expect(tabs[1].selected).toBeTruthy();
          }
        );

        it(
          'marks the tabs that were not clicked as unselected',
          () => {
            expect(tabs[0].selected).toBeFalsy();
          }
        );
      }
    );

    describe(
      'clicking on the link for the selected tab',
      () => {
        beforeEach(
          async () => {
            wrapper = getWrapper();
            const tabLinkElm = wrapper.findAll('a')[0];

            await tabLinkElm.trigger('click');
          }
        )

        it(
          'does not change the selected status of the clicked tab',
          () => {
            expect(tabs[0].selected).toBeTruthy();
          }
        );

        it(
          'does not change the selected status of tabs that were not clicked',
          () => {
            expect(tabs[1].selected).toBeFalsy();
          }
        );
      }
    );
  }
)
