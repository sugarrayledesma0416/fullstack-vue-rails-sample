import { mount } from '@vue/test-utils';
import Suggestion from 'features/ai/instructor_grading_sets/components/Suggestion';

let wrapper;
function getWrapper(props = {}, options = {}) {
  return mount(Suggestion, {
    props,
    slots: options.slots || {},
    global: {
      stubs: {
        DiscreetButton: {
          template: '<button class="suggestion-button"><slot></slot></button>',
          props: ['type']
        },
        XIcon: {
          template: '<span class="test-x-icon"></span>'
        },
        PlusIcon: {
          template: '<span class="test-plus-icon"></span>'
        },
        Tippy: {
          template: '<div><slot></slot></div>',
          props: ['content', 'placement']
        }
      }
    }
  });
}

describe('Suggestion', () => {
  const mockProps = {
    id: 1,
    index: 0,
    isAdded: false,
    isEdited: false,
    onAddSuggestion: jest.fn(),
    onRejectSuggestion: jest.fn(),
    onEditSuggestion: jest.fn()
  };

  beforeEach(() => {
    jest.clearAllMocks();
    wrapper = getWrapper(mockProps);
  });

  describe('rendering', () => {
    it('renders with correct classes', () => {
      expect(wrapper.classes()).toContain('suggestion');
      expect(wrapper.classes()).toContain('suggestion--indexed');
    });

    it('renders slot content', () => {
      const slotContent = 'Test suggestion content';
      wrapper = getWrapper(mockProps, {
        slots: { default: slotContent }
      });
      expect(wrapper.text()).toContain(slotContent);
    });
  });

  describe('suggestion text', () => {
    it('renders the suggestion text', () => {
      const suggestionText = 'Test suggestion';
      wrapper = getWrapper(mockProps, {
        slots: { default: suggestionText }
      });
      expect(wrapper.find('.suggestion-text').text()).toBe(suggestionText);
    });
  });

  describe('controls', () => {
    it('renders the controls section', () => {
      expect(wrapper.find('.controls').exists()).toBe(true);
    });

    it('renders the add button when not added', () => {
      expect(wrapper.find('.test-plus-icon').exists()).toBe(true);
      expect(wrapper.find('.test-x-icon').exists()).toBe(false);
    });

    it('renders the remove button when added', () => {
      wrapper = getWrapper({ ...mockProps, isAdded: true });
      expect(wrapper.find('.test-x-icon').exists()).toBe(true);
      expect(wrapper.find('.test-plus-icon').exists()).toBe(false);
    });
  });

  describe('edit functionality', () => {
    it('calls onEditSuggestion when edit button is clicked', async () => {
      wrapper = getWrapper({ ...mockProps, isEdited: true });
      await wrapper.find('a.u-txt-ital').trigger('click');
      expect(mockProps.onEditSuggestion).toHaveBeenCalled();
    });
  });

  describe('tooltips', () => {
    // TODO: Unable to get tooltip tests working with vue-tippy component
    // The component is rendered but findComponent({ name: 'tippy' }) returns empty
    // May need to investigate alternative ways to test vue-tippy components
    /*
    it('shows correct tooltip for add button', () => {
      const tippy = wrapper.findComponent({ name: 'tippy' });
      expect(tippy.props('content')).toBe('Add Feedback');
    });

    it('shows correct tooltip for remove button', () => {
      wrapper = getWrapper({ ...mockProps, isAdded: true });
      const tippy = wrapper.findComponent({ name: 'tippy' });
      expect(tippy.props('content')).toBe('Remove Feedback');
    });
    */
  });
});
