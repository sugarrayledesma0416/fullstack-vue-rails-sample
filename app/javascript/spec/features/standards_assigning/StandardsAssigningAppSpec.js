import { shallowMount } from '@vue/test-utils';
import StandardsAssigningApp from 'features/standards_assigning/StandardsAssigningApp.vue';
import Filters from 'features/standards_assigning/components/Filters.vue';
import AlignedItemsResults from 'features/standards_assigning/components/AlignedItemsResults.vue';
import StandardsResultsFooter from 'features/standards_assigning/components/StandardsResultsFooter.vue';
import { createTestingPinia } from '@pinia/testing';
import useStandardsAssigningStore from 'features/standards_assigning/models/use_standards_assigning_store';

jest.mock('shared/ajax_utils', () => ({
  putToEndpoint: jest.fn(),
}));

beforeAll(() => {
  global.IntersectionObserver = jest.fn(() => ({
    observe: jest.fn(),
    unobserve: jest.fn(),
    disconnect: jest.fn(),
  }));
});

describe('StandardsAssigningApp.vue', () => {
  let wrapper;
  let mockStore;

  const mockProps = {
    availableSetsJson: JSON.stringify([{ id: 1, name: 'Set A' }]),
    availableBrowseStandardSets: JSON.stringify([{ id: 1, name: 'Browse Set A' }]),
    availableGradeLevels: JSON.stringify([{ id: 1, name: 'Grade 1' }]),
    browseStandardUrl: '/browse',
    contentLibrary: {},
    courseSettingsUrl: '/course-settings',
    dataForAssignedItemEndpoint: '/data-endpoint',
    dueDateLinkBaseUrl: '/due-date',
    individualAssigningUrl: '/individual-assigning',
    instructorSearchStandardsByAssetPath: '/search-standards',
    instructorStandardsAssigningPath: '/assign-standards',
    preloadStandardsFilter: 'filter',
    programTocType: 'toc',
    searchAssetsEndpoint: '/search-assets',
    searchStandardsEndpoint: '/search-standards',
    selectedUnit: '',
    standardsForInit: JSON.stringify([]),
    showSkillsAndRefinementFilters: 'true',
    vhlAssessments: {},
    vhlCommon: {},
    tocJson: JSON.stringify({ units: [{ id: 1, name: 'Unit 1' }] })
  };

  function getWrapper(props = {}) {
    return shallowMount(StandardsAssigningApp, {
      props: {
        ...mockProps,
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
    mockStore.selectedStandards = [];
    mockStore.alignedItems = [];
    wrapper = getWrapper();
  });

  afterEach(() => {
    wrapper.unmount();
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders the warning message when no available sets are provided', () => {
      wrapper = getWrapper({ availableSetsJson: JSON.stringify([]) });
      expect(wrapper.find('.test-warning-icon').exists()).toBeTruthy();
    });

    it('renders the Filters component', () => {
      expect(wrapper.findComponent(Filters).exists()).toBeTruthy();
    });

    it('renders the FindStandards component when viewMode is "FIND"', async () => {
      wrapper.vm.viewMode = 'FIND';
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent({ name: 'FindStandards' }).exists()).toBeTruthy();
    });

    it('renders the BrowseStandards component when viewMode is "BROWSE"', async () => {
      wrapper.vm.viewMode = 'BROWSE';
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent({ name: 'BrowseStandards' }).exists()).toBeTruthy();
    });

    it('renders the AlignedItemsResults component when viewMode is "RESULTS"', async () => {
      wrapper.vm.viewMode = 'RESULTS';
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent(AlignedItemsResults).exists()).toBeTruthy();
    });

    it('renders the spinner when isSearchLoading is true', async () => {
      wrapper.vm.isSearchLoading = true;
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.test-search-spinner').exists()).toBeTruthy();
    });

    it('renders the error message when searchErrorMsg is set', async () => {
      wrapper.vm.searchErrorMsg = 'An error occurred';
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.test-search-error').text()).toBe('An error occurred');
    });

    it('renders the StandardsResultsFooter component when viewMode is "FIND" or "BROWSE"', async () => {
      wrapper.vm.viewMode = 'FIND';
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent(StandardsResultsFooter).exists()).toBeTruthy();

      wrapper.vm.viewMode = 'BROWSE';
      await wrapper.vm.$nextTick();
      expect(wrapper.findComponent(StandardsResultsFooter).exists()).toBeTruthy();
    });
  });

  describe('Computed Properties', () => {
    beforeEach(() => {
      wrapper.vm.isSearchLoading = false;
      wrapper.vm.searchErrorMsg = null;
      wrapper.vm.store.alignedItems = [];
    });

    it('computes isEmptySearch correctly', () => {
      expect(wrapper.vm.isEmptySearch).toBeTruthy();
      wrapper.vm.store.alignedItems = [{ id: 1 }];
      expect(wrapper.vm.isEmptySearch).toBe(false);
    });
  });

  describe('Methods', () => {
    it('initializes the search correctly', () => {
      wrapper.vm.initializeSearch();
      expect(wrapper.vm.nextKey).toBe('');
      expect(wrapper.vm.isSearchLoading).toBe(true);
      expect(wrapper.vm.searchErrorMsg).toBe(null);
      expect(mockStore.alignedItems).toEqual([]);
      expect(mockStore.standardsInfo).toEqual({});
    });

    it('builds the request payload correctly', () => {
      const payload = wrapper.vm.buildRequestPayload(['unit1'], ['skill1'], ['refinement1']);
      expect(payload).toEqual({
        selected_standards: [],
        selected_units: ['unit1'],
        selected_skills: ['skill1'],
        selected_refinements: ['refinement1'],
        selected_content_type: null,
      });
    });

    it('switches view modes correctly', async () => {
      wrapper.vm.switchView('FIND');
      expect(wrapper.vm.viewMode).toBe('FIND');

      wrapper.vm.switchView('BROWSE');
      expect(wrapper.vm.viewMode).toBe('BROWSE');

      wrapper.vm.switchView('RESULTS');
      expect(wrapper.vm.viewMode).toBe('RESULTS');
    });
  });
});
