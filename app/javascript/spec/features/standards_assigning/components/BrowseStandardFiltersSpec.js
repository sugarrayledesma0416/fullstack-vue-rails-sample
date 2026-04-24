import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import BrowseStandardFilters from 'features/standards_assigning/components/BrowseStandardFilters.vue';
import BrowseDropdown from 'features/standards_assigning/components/BrowseDropdown.vue';
import StandardButton from 'music/app/javascript/src/vue/StandardButton.vue';

describe('BrowseStandardFilters.vue', () => {
  let wrapper;
  const availableBrowseStdSets = ['Set 1', 'Set 2', 'Set 3'];

  function getWrapper() {
    return shallowMount(BrowseStandardFilters, {
      global: {
        plugins: [
          createTestingPinia({
            stubActions: false,
            initialState: {
              standardsAssigning: {
                selectedStandardSet: null
              },
            },
          }),
        ],
      },
      props: { availableBrowseStdSets },
    });
  }

  beforeEach(() => {
    wrapper = getWrapper();
  });

  afterEach(() => {
    wrapper.unmount();
  });

  it('renders BrowseDropdown correctly with props', () => {
    expect(wrapper.findComponent(BrowseDropdown).exists()).toBeTruthy();
    expect(wrapper.findAllComponents(BrowseDropdown).length).toBe(1);
  });

  it('renders StandardButton component correctly', () => {
    const standardButton = wrapper.findComponent(StandardButton);
    expect(standardButton.exists()).toBeTruthy();
    expect(standardButton.props('variant')).toBe('border');
  });

  it('disables the "Next" button when no values are selected', () => {
    const nextButton = wrapper.findComponent(StandardButton);
    expect(nextButton.props('disabled')).toBe(true);
  });

  describe('when dropdown values are selected', () => {
    beforeEach(async () => {
      const dropdowns = wrapper.findAllComponents(BrowseDropdown);
      await dropdowns[0].vm.$emit('update:modelValue', 'Set 1');
    });

    it('enables the "Next" button', () => {
      const nextButton = wrapper.findComponent(StandardButton);
      expect(nextButton.props('disabled')).toBe(false);
    });

    it('emits the "next" event when the "Next" button is clicked', async () => {
      const nextButton = wrapper.findComponent(StandardButton);
      await nextButton.trigger('click');

      expect(wrapper.emitted('next')).toBeTruthy();
      expect(wrapper.emitted('next').length).toBe(1);
    });
  });
});
