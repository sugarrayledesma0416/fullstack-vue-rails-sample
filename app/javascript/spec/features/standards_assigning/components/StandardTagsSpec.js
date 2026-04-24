import { shallowMount } from '@vue/test-utils';
import { createTestingPinia } from '@pinia/testing';
import StandardTags from 'features/standards_assigning/components/StandardTags.vue';
import useStandardsAssigningStore from 'features/standards_assigning/models/use_standards_assigning_store';

describe('StandardTags', () => {
  let wrapper;
  const mockItems = ['item1', 'item2', 'item3'];
  let mockStore;

  function getWrapper(cartItems = mockItems) {
    return shallowMount(StandardTags, {
      props: { cartItems },
      global: {
        plugins: [
          createTestingPinia({
            stubActions: false,
            initialState: {
              standardsAssigning: {
                matchedStandards: [],
              },
            },
            createSpy: jest.fn,
          }),
        ],
      },
    });
  }

  beforeEach(() => {
    const pinia = createTestingPinia({
      stubActions: false,
      initialState: {
        standardsAssigning: {
          matchedStandards: [],
        },
      },
    });
    mockStore = useStandardsAssigningStore(pinia);
    mockStore.convertStandardGuidToNumber = jest.fn((items) => items.map((item) => `processed-${item}`));
    wrapper = shallowMount(StandardTags, {
      props: { cartItems: mockItems },
      global: {
        plugins: [pinia],
      },
    });
  });

  afterEach(() => {
    wrapper.unmount();
    jest.clearAllMocks();
  });

  describe('Rendering', () => {
    it('renders nothing when cartItems is empty', () => {
      const emptyWrapper = getWrapper([]);
      expect(emptyWrapper.findAll('.test-cart-item')).toHaveLength(0);
    });

    it('renders the correct number of cart items', () => {
      const cartItems = wrapper.findAll('.test-cart-item');
      expect(cartItems).toHaveLength(mockItems.length);
    });

    it('renders the correct processed labels for cart items', () => {
      const labels = wrapper.findAll('.label');
      labels.forEach((label, index) => {
        expect(label.text()).toBe(`processed-${mockItems[index]}`);
      });
    });
  });

  describe('Functionality', () => {
    it('calls convertStandardGuidToNumber with the correct cartItems', () => {
      expect(mockStore.convertStandardGuidToNumber).toHaveBeenCalledWith(mockItems);
    });
  });
});
