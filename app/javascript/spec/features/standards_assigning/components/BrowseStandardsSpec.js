import { shallowMount, flushPromises } from '@vue/test-utils';
import BrowseStandards from 'features/standards_assigning/components/BrowseStandards.vue';
import useStandardsAssigningStore from 'features/standards_assigning/models/use_standards_assigning_store';
import { getFromEndpoint } from 'music';

jest.mock('features/standards_assigning/models/use_standards_assigning_store');
jest.mock('music', () => ({
  getFromEndpoint: jest.fn(),
  testClass: (cls) => cls,
}));

const availableBrowseStdSets = [
  { display_name: 'Set1', name: 'Name1', adopt_year: 2020, vendor_guid: 'guid1' },
  { display_name: 'Set2', name: 'Name2', adopt_year: 2021, vendor_guid: 'guid2' },
];
const availableGradeLevels = ['K', '1', '2'];
const browseStandardUrl = '/api/browse';

function factory(storeOverrides = {}, propsOverrides = {}) {
  const store = {
    showBrowseTree: false,
    isFirstSearch: true,
    matchedStandards: null,
    selectedStandards: [],
    selectedStandardSet: null,
    setSelectedStandardSet: jest.fn(),
    setShowBrowseTree: jest.fn(),
    updateMatchedStandards: jest.fn(),
    ...storeOverrides,
  };
  useStandardsAssigningStore.mockReturnValue(store);
  return {
    wrapper: shallowMount(BrowseStandards, {
      props: {
        availableBrowseStdSets,
        availableGradeLevels,
        browseStandardUrl,
        ...propsOverrides,
      },
    }),
    store,
  };
}

describe('BrowseStandards.vue', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders BrowseStandardFilters when showBrowseTree is false', () => {
    const { wrapper } = factory({ showBrowseTree: false });
    expect(wrapper.findComponent({ name: 'BrowseStandardFilters' }).exists()).toBeTruthy();
  });

  it('renders Breadcrumb and BrowseTree when showBrowseTree is true', () => {
    const { wrapper } = factory({ showBrowseTree: true });
    expect(wrapper.findComponent({ name: 'Breadcrumb' }).exists()).toBeTruthy();
    expect(wrapper.findComponent({ name: 'BrowseTree' }).exists()).toBeTruthy();
  });

  it('shows spinner when isSearchLoading is true', async () => {
    const { wrapper } = factory();
    wrapper.vm.isSearchLoading = true;
    await wrapper.vm.$nextTick();
    expect(wrapper.find('.c-spinner-wrapper').exists()).toBeTruthy();
  });

  it('shows error message when searchErrorMsg is set', async () => {
    const { wrapper } = factory();
    wrapper.vm.searchErrorMsg = 'Error!';
    await wrapper.vm.$nextTick();
    expect(wrapper.find('.error-msg').text()).toContain('Error!');
  });

  it('shows get started state when isFirstSearch is true', () => {
    const { wrapper } = factory({ isFirstSearch: true });
    expect(wrapper.find('.no-standards-title').text()).toContain('Begin Browse');
  });

  it('shows no results state when matchedStandards is empty', () => {
    const { wrapper } = factory({ matchedStandards: [], isFirstSearch: false });
    expect(wrapper.find('.no-standards-title').text()).toContain('No Results Found');
  });

  it('auto-selects standard set and calls onBrowseNext if only one set', async () => {
    const singleSet = [availableBrowseStdSets[0]];
    const setSelectedStandardSet = jest.fn();
    const setShowBrowseTree = jest.fn();
    useStandardsAssigningStore.mockReturnValue({
      ...factory().store,
      setSelectedStandardSet,
      setShowBrowseTree,
    });
    shallowMount(BrowseStandards, {
      props: {
        availableBrowseStdSets: singleSet,
        availableGradeLevels,
        browseStandardUrl,
      },
    });
    expect(setSelectedStandardSet).toHaveBeenCalledWith({
      key: singleSet[0].display_name,
      value: `${singleSet[0].display_name} - ${singleSet[0].name} (${singleSet[0].adopt_year})`,
      vendor_guid: singleSet[0].vendor_guid,
    });
  });

  it('clearStandardSearchResults resets store and error', async () => {
    const { wrapper, store } = factory({
      selectedStandards: [1],
      matchedStandards: [2],
    });
    wrapper.vm.searchErrorMsg = 'err';
    wrapper.vm.clearStandardSearchResults();
    expect(store.selectedStandards).toEqual([]);
    expect(store.matchedStandards).toBeNull();
    expect(wrapper.vm.searchErrorMsg).toBeNull();
  });

  it('resetStandardSet calls setShowBrowseTree and resets search', () => {
    const setShowBrowseTree = jest.fn();
    const { wrapper, store } = factory({ setShowBrowseTree });
    wrapper.vm.resetStandardSet();
    expect(setShowBrowseTree).toHaveBeenCalledWith(false);
    expect(store.isFirstSearch).toBeTruthy();
  });

  it('onBrowseNext calls getFromEndpoint and updates loading', async () => {
    const { wrapper, store } = factory({ selectedStandardSet: { vendor_guid: 'guid1' } });
    getFromEndpoint.mockImplementation((url, cb) => cb({ matched_browse_standards: [] }));
    wrapper.vm.onBrowseNext();
    expect(getFromEndpoint).toHaveBeenCalledWith(
      expect.stringContaining('standard_set_vendor_guid=guid1'),
      expect.any(Function)
    );
    await flushPromises();
    expect(wrapper.vm.isSearchLoading).toBeFalsy();
  });

  it('loadBrowseTree sets error if data.error_message', () => {
    const { wrapper } = factory();
    wrapper.vm.loadBrowseTree({ error_message: 'fail' });
    expect(wrapper.vm.searchErrorMsg).toContain(
      'There was a problem processing your search'
    );
  });

  it('loadBrowseTree updates store and browseTreeData on success', () => {
    const updateMatchedStandards = jest.fn();
    const setShowBrowseTree = jest.fn();
    const { wrapper, store } = factory({ updateMatchedStandards, setShowBrowseTree });
    const data = { matched_browse_standards: [{ id: 1 }] };
    wrapper.vm.loadBrowseTree(data);
    expect(updateMatchedStandards).toHaveBeenCalledWith(
      JSON.stringify(data.matched_browse_standards),
      'BROWSE'
    );
    expect(wrapper.vm.browseTreeData).toEqual(data.matched_browse_standards);
    expect(setShowBrowseTree).toHaveBeenCalledWith(true);
  });
});
