import { mount } from '@vue/test-utils';
import { reactive } from 'vue';
import TocSelector from 'features/standards_assigning/components/TocSelector.vue';
import MultiSelect from 'features/standards_assigning/components/MultiSelect.vue';
import useStandardsAssigningStore
  from 'features/standards_assigning/models/use_standards_assigning_store.js';

jest.mock('features/standards_assigning/models/use_standards_assigning_store.js');

describe('TocSelector.vue', () => {
  let wrapper;
  let store;

  const propsData = {
    tocItems: [
      { id: 1, name: 'Unit 1' },
      { id: 2, name: 'Unit 2' },
      { id: 3, name: 'Unit 3' },
    ],
    programTocType: 'Unit',
  };

  beforeEach(() => {
    store = reactive({
      selectedTocItems: [],
      selectedSkills: [],
      selectedRefinements: [],
      setDefaultSelectedTocItems: jest.fn(),
    });
    useStandardsAssigningStore.mockReturnValue(store);

    wrapper = mount(TocSelector, {
      props: propsData,
      global: {
        components: {
          MultiSelect,
        },
        provide: {
          selectedUnit: 1,
        },
      },
    });
  });

  it('renders the MultiSelect component', () => {
    expect(wrapper.findComponent(MultiSelect).exists()).toBeTruthy();
  });

  it('handles selected items correctly as 1 is default selected', async () => {
    const multiSelect = wrapper.findComponent(MultiSelect);
    await multiSelect.vm.$emit('update:selectedItems', { value: 2, isChecked: true });

    expect(wrapper.vm.selectedUnitsCheckbox).toEqual([1, 2]);
    expect(store.selectedTocItems).toEqual([1, 2]);
    expect(wrapper.emitted()['applyFilter']).toBeTruthy();
  });

  it('handles deselecting items correctly as 1 unit is default selected', async () => {
    const multiSelect = wrapper.findComponent(MultiSelect);
    await multiSelect.vm.$emit('update:selectedItems', { value: 2, isChecked: true });
    await multiSelect.vm.$emit('update:selectedItems', { value: 2, isChecked: false });

    expect(wrapper.vm.selectedUnitsCheckbox).toEqual([1]);
    expect(store.selectedTocItems).toEqual([1]);
    expect(wrapper.emitted()['applyFilter']).toBeTruthy();
  });

  it('handles deselecting all items correctly', async () => {
    const multiSelect = wrapper.findComponent(MultiSelect);
    await multiSelect.vm.$emit('update:selectedItems', { value: 2, isChecked: true });
    await multiSelect.vm.$emit('update:deselectAll');

    expect(wrapper.vm.selectedUnitsCheckbox).toEqual([]);
    expect(store.setDefaultSelectedTocItems).toHaveBeenCalled();
    expect(wrapper.emitted()['applyFilter']).toBeTruthy();
  });

  it('watches store.selectedTocItems and calls deselectAllUnits when empty', async () => {
    store.selectedTocItems.push(1);
    await wrapper.vm.$nextTick();
    store.selectedTocItems = [];
    await wrapper.vm.$nextTick();

    expect(wrapper.vm.selectedUnitsCheckbox).toEqual([]);
    expect(store.setDefaultSelectedTocItems).toHaveBeenCalled();
    expect(wrapper.emitted()['applyFilter']).toBeTruthy();
  });
});
