import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import BrowseTree from 'features/standards_assigning/components/BrowseTree.vue';
import TreeItem from 'features/standards_assigning/components/TreeItem.vue';
import useStandardsAssigningStore from 'features/standards_assigning/models/use_standards_assigning_store';

describe('BrowseTree.vue', () => {
  let wrapper;
  let mockStore;

  const mockTreeData = [
    {
      vendor_guid: 'node-1',
      children: [
        {
          vendor_guid: 'node-1-1',
          children: [],
        },
        {
          vendor_guid: 'node-1-2',
          children: [],
        },
      ],
    },
    {
      vendor_guid: 'node-2',
      children: [],
    },
  ];

  function getWrapper(treeData = mockTreeData) {
    return shallowMount(BrowseTree, {
      props: {
        browseTreeData: treeData,
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
    wrapper = getWrapper();
  });

  afterEach(() => {
    wrapper.unmount();
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders the tree container', () => {
      expect(wrapper.find('.test-browse-tree-container').exists()).toBeTruthy();
    });

    it('renders the correct number of TreeItem components', () => {
      const treeItems = wrapper.findAllComponents(TreeItem);
      expect(treeItems.length).toBe(mockTreeData.length);
    });

    it('passes the correct props to TreeItem components', () => {
      const treeItems = wrapper.findAllComponents(TreeItem);
      treeItems.forEach((treeItem, index) => {
        expect(treeItem.props('node')).toEqual(mockTreeData[index]);
        expect(treeItem.props('depth')).toBe(0);
      });
    });
  });
});
