import { mount } from '@vue/test-utils';
import MultiSelect from 'features/standards_assigning/components/MultiSelect.vue';
import { createTestingPinia } from '@pinia/testing';
import useStandardsAssigningStore from 'features/standards_assigning/models/use_standards_assigning_store';

describe('MultiSelect.vue', () => {
  let wrapper;
  let mockStore;

  const mockData = [
    { id: 1, name: 'Option 1' },
    { id: 2, name: 'Option 2' },
    { id: 3, name: 'Option 3' },
  ];

  function getWrapper(props = {}) {
    return mount(MultiSelect, {
      props: {
        data: mockData,
        type: 'test',
        ...props,
      },
      global: {
        plugins: [
          createTestingPinia({ stubActions: false }),
        ],
      },
    });
  }

  beforeEach(() => {
    const pinia = createTestingPinia({ stubActions: false });
    mockStore = useStandardsAssigningStore(pinia);
    mockStore.resetAllFilters = false;
    wrapper = getWrapper();
    wrapper.vm.store = mockStore;
  });

  afterEach(() => {
    wrapper.unmount();
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    beforeEach(async () => {
      await wrapper.setProps({ resetAll: true });
    });

    it('renders the dropdown container', () => {
      expect(wrapper.find('.multi-select').exists()).toBeTruthy();
    });

    it('renders the "Deselect All" button when resetAll is true', () => {
      const deselectAllButton = wrapper.find('.test-deselect-all-button');
      expect(deselectAllButton.exists()).toBeTruthy();
    });

    it('disables the "Deselect All" button when no options are selected', () => {
      const deselectAllButton = wrapper.find('.test-deselect-all-button');
      expect(deselectAllButton.attributes()).toHaveProperty('disabled');
    });
  });

  describe('Functionality', () => {
    it('emits "update:selectedItems" when an option is selected', async () => {
      const checkbox = wrapper.findAll('input[type="checkbox"]').at(0);
      await checkbox.setChecked(true);
      expect(wrapper.emitted('update:selectedItems')).toBeTruthy();
      expect(wrapper.emitted('update:selectedItems')[0]).toEqual([
        { value: '1', isChecked: true },
      ]);
    });

    it('updates the dropdown text based on the number of selected items', async () => {
      wrapper.vm.selectedItems = [1];
      expect(wrapper.vm.dropdownText).toBe('1 test Selected');
      wrapper.vm.selectedItems = [1, 2];
      expect(wrapper.vm.dropdownText).toBe('2 test Selected');
      wrapper.vm.selectedItems = [];
      expect(wrapper.vm.dropdownText).toBe('Select test');
    });

    it('closes the dropdown when clicking outside', async () => {
      wrapper.vm.isExpanded = true;
      document.dispatchEvent(new Event('click'));
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.isExpanded).toBe(false);
    });

    it('closes the dropdown when the Escape key is pressed', async () => {
      wrapper.vm.isExpanded = true;
      const event = new KeyboardEvent('keydown', { key: 'Escape' });
      document.dispatchEvent(event);
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.isExpanded).toBe(false);
    });

    it('selects no item by default on mount if type is "unit"', async () => {
      wrapper = getWrapper({ type: 'unit' });
      await wrapper.vm.$nextTick();
      expect(wrapper.vm.selectedItems).toEqual([]);
    });
  });
});
