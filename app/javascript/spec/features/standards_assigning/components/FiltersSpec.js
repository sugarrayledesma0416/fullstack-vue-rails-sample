import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import Filters from 'features/standards_assigning/components/Filters';
import {
  appliedFilters,
  tocJson,
} from './../standards_assigning_fixture.js';

const store = createTestingPinia(
  {
    stubActions: false,
    initialState: {
      store: {
        appliedFilters: appliedFilters,
      },
    },
  }
);

function getWrapper() {
  return shallowMount(
    Filters,
    {
      global: {
        plugins: [store],
      },
      props: {
        programTocType: 'Unit',
        tocJson: tocJson,
        preloadStandardsFilter: '{}',
      },
    }
  );
}

describe(
  'Filters',
  () => {
    let wrapper;
    let defaultUnits = [];
    beforeEach(
      () => {
        wrapper = getWrapper();
        wrapper.vm.store.initToc(tocJson);
        wrapper.vm.store.setDefaultSelectedTocItems();
        defaultUnits = wrapper.vm.store.selectedTocItems;
      }
    );

    it('passes programTocType to the TocSelector component', () => {
      const tocSelector = wrapper.findComponent({ name: 'TocSelector' });
      expect(tocSelector.componentVM.tocItems).toEqual(wrapper.vm.store.tocItems);
      expect(tocSelector.componentVM.programTocType).toEqual(wrapper.vm.programTocType);
    });

    it('sets all Units/Lessons selected by default', () => {
      expect(wrapper.vm.store.selectedTocItems).toEqual(defaultUnits);
    });

    it('updates the store when status is changed', async () => {
      wrapper.find('.test-standard-set-status').setValue('Assigned');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.selectedStatus).toEqual('Assigned');
      wrapper.find('.test-standard-set-status').setValue('Unassigned');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.selectedStatus).toEqual('Unassigned');
      wrapper.find('.test-standard-set-status').setValue('All');
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.store.selectedStatus).toEqual('All');
    });

    it('updates the store when the contentType is changed', async () => {
      const select = wrapper.get('.test-standard-set-content-type');
      select.element.value = 'Activity';
      await select.trigger('change');
      expect(wrapper.vm.store.selectedContentType).toEqual('Activity');
      select.element.value = 'Activity';
      await select.trigger('change');
      await wrapper.find('select').setValue('Assessment');
      expect(wrapper.vm.store.selectedContentType).toEqual('Assessment');
      await wrapper.find('select').setValue('Teacher Edition');
      expect(wrapper.vm.store.selectedContentType).toEqual('Teacher Edition');
      await wrapper.find('select').setValue('All');
      expect(wrapper.vm.store.selectedContentType).toEqual('All');
    });

    it('disables the select status filter when Teacher Edition is selected', async () => {
      const statusFilter = wrapper.find('.test-standard-set-status');
      const select = wrapper.get('.test-standard-set-content-type');
      select.element.value = 'Teacher Edition';
      await select.trigger('change');
      expect(statusFilter.element.disabled).toBeTruthy();
    });

    describe('Filter reset', () => {
      it('sets selected TOC Unit/Lesson in the store to default', () => {
        wrapper.find('.test-reset-filters').trigger('click');
        expect(wrapper.vm.store.selectedTocItems).toEqual([]);
      });
    });
  }
);
