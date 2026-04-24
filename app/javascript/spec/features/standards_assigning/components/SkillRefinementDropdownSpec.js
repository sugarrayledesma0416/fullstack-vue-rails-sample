import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import BasicDisclosure from
  'music/app/javascript/src/components/basic_disclosure/v1.1/BasicDisclosure';
import SkillRefinementDropdown from
  'features/standards_assigning/components/SkillRefinementDropdown';
import useStandardsAssigningStore from
  'features/standards_assigning/models/use_standards_assigning_store';

const skillsData = [
  { name: 'Reading', refinements: ['Interpretive: Text', 'Interpretive: Authentic Text'] },
  { name: 'Writing', refinements: ['Presentational', 'Interpersonal'] },
];

function factory() {
  setActivePinia(createPinia());
  const store = useStandardsAssigningStore();
  store.$patch({
    skills: skillsData,
    selectedSkills: [],
    visibleRefinements: {},
  });

  const wrapper = mount(SkillRefinementDropdown, {
    global: {
      plugins: [createPinia()],
      stubs: { BasicDisclosure },
    },
  });

  return { wrapper, store };
}

describe('SkillRefinementDropdown', () => {
  let wrapper; 
  let store;

  beforeEach(() => {
    ({ wrapper, store } = factory());
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('renders the dropdown header text correctly when no skills are selected', () => {
    expect(wrapper.find('.disclosure-header-text').text()).toBe('Select Skill');
  });

  it('toggles the dropdown when clicked', async () => {
    const disclosure = wrapper.findComponent(BasicDisclosure);

    await disclosure.vm.$emit('disclosureClick');
    expect(wrapper.vm.isExpanded).toBe(true);

    await disclosure.vm.$emit('disclosureClick');
    expect(wrapper.vm.isExpanded).toBe(false);
  });

  it('clears all selected skills when "Deselect All" is clicked', async () => {
    await wrapper.find('.deselect-all').trigger('click');
    expect(store.selectedSkills).toEqual([]);
  });
});
