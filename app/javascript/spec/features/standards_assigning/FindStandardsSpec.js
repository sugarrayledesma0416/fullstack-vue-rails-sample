import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import { putToEndpoint } from 'shared/ajax_utils';
import FindStandards from 'features/standards_assigning/FindStandards.vue';
import useStandardsAssigningStore from 'features/standards_assigning/models/use_standards_assigning_store';

jest.mock('shared/ajax_utils', () => ({
  putToEndpoint: jest.fn(),
}));

describe('FindStandards.vue', () => {
  let wrapper;
  let mockStore;

  const mockAvailableSets = [
    { display_name: 'Set A', name: 'Standard A', vendor_guid: '123', adopt_year: 2020 },
    { display_name: 'Set B', name: 'Standard B', vendor_guid: '456', adopt_year: 2021 },
  ];

  const mockSearchEndpoint = '/search/standards';

  function getWrapper(props = {}) {
    return shallowMount(FindStandards, {
      props: {
        availableSets: mockAvailableSets,
        searchStandardsEndpoint: mockSearchEndpoint,
        ...props,
      },
      global: {
        plugins: [
          createTestingPinia({
            stubActions: false,
          }),
        ],
      },
    });
  }

  beforeEach(() => {
    const pinia = createTestingPinia({ stubActions: false });
    mockStore = useStandardsAssigningStore(pinia);
    mockStore.selectedStandardSet = null;
    mockStore.matchedStandards = null;
    wrapper = getWrapper();
  });

  afterEach(() => {
    wrapper.unmount();
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders the Browse dropdown.', () => {
      expect(wrapper.findComponent({ name: 'BrowseDropdown' }).exists()).toBeTruthy();
    });

    it('renders the search input', () => {
      expect(wrapper.find('input.search-standard-input').exists()).toBeTruthy();
    });

    it('renders the search button', () => {
      const searchButton = wrapper.findComponent({ name: 'StandardButton' });
      expect(searchButton.exists()).toBeTruthy();
    });

    it('renders the MatchedStandardsList component', () => {
      expect(wrapper.findComponent({ name: 'MatchedStandardsList' }).exists()).toBeTruthy();
    });
  });

  describe('Computed Properties', () => {
    it('computes availableStdSetOptions correctly', () => {
      const options = wrapper.vm.availableStdSetOptions;
      expect(options).toEqual([
        {
          key: 'Set A',
          value: 'Set A - Standard A (2020)',
          vendor_guid: '123',
        },
        {
          key: 'Set B',
          value: 'Set B - Standard B (2021)',
          vendor_guid: '456',
        },
      ]);
    });
  });

  describe('Methods', () => {
    it('initializes the search correctly', () => {
      wrapper.vm.initializeSearch();
      expect(wrapper.vm.isSearchLoading).toBe(true);
      expect(wrapper.vm.searchErrorMsg).toBe(null);
      expect(mockStore.matchedStandards).toBe(null);
    });

    it('clears search results correctly', () => {
      wrapper.vm.clearSearchResults();
      expect(mockStore.isFirstSearch).toBe(true);
      expect(mockStore.matchedStandards).toBe(null);
      expect(wrapper.vm.searchErrorMsg).toBe(null);
    });

    it('sets an error message if the search fails', async () => {
      const mockResult = { error_message: 'An error occurred' };
      putToEndpoint.mockImplementation((url, payload, successCallback) => {
        successCallback(mockResult);
      });

      wrapper.vm.searchTerm = 'Math';
      mockStore.selectedStandardSet = { vendor_guid: '123' };
      await wrapper.vm.searchStandards();

      expect(wrapper.vm.isSearchLoading).toBe(false);
      expect(wrapper.vm.searchErrorMsg).toBe(wrapper.vm.ajaxErrorMsg);
    });
  });
});
