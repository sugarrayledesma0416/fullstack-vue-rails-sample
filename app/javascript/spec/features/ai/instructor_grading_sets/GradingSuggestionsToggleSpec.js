import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import GradingSuggestionsToggle from 'features/ai/instructor_grading_sets/GradingSuggestionsToggle';
import { useGradingSuggestionsStore } from 'features/ai/instructor_grading_sets/stores/grading_suggestions_store';

// At the top of the file, add the following mock for fetch
global.fetch = jest.fn(() =>
  Promise.resolve({
    ok: true,
    json: () => Promise.resolve({}),
  })
);

let wrapper;
function getWrapper(props = {}) {
  return mount(GradingSuggestionsToggle, {
    props,
    global: {
      plugins: [createPinia()],
      stubs: {
        BasicDialog: {
          template: `
            <div class="test-basic-dialog" :title="title">
              <slot name="body"></slot>
              <slot name="footer"></slot>
            </div>
          `,
          props: ['isConfirmationDialog', 'isModal', 'title']
        },
        StandardButton: {
          template: '<button class="test-standard-button" @click="$emit(\'click\')"><slot></slot></button>',
          props: ['variant', 'class']
        },
        'ai-grading-sets-stars-icon': {
          template: '<span class="test-stars-icon"></span>'
        }
      }
    }
  });
}

describe('GradingSuggestionsToggle', () => {
  const mockProps = {
    featureEnabledAtProgramLevel: 'true',
    featureEnabledAtUserLevel: 'true'
  };

  beforeEach(() => {
    setActivePinia(createPinia());
    wrapper = getWrapper(mockProps);
  });

  describe('rendering', () => {
    it('renders the toggle button', () => {
      expect(wrapper.find('.button').exists()).toBe(true);
    });

    it('renders the stars icon', () => {
      expect(wrapper.find('.test-stars-icon').exists()).toBe(true);
    });

    it('shows correct label when suggestions are enabled', () => {
      expect(wrapper.find('.label').text()).toBe('Turn AI Off');
    });

    it('shows correct label when suggestions are disabled', async () => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = false;
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.label').text()).toBe('Turn AI On');
    });
  });

  describe('button state', () => {
    it('applies correct class when suggestions are enabled', () => {
      expect(wrapper.find('.button').classes()).toContain('button--on');
    });

    it('removes class when suggestions are disabled', async () => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = false;
      await wrapper.vm.$nextTick();
      expect(wrapper.find('.button').classes()).not.toContain('button--on');
    });
  });

  describe('toggle functionality', () => {
    it('shows confirmation dialog when disabling suggestions', async () => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = true;
      await wrapper.find('.button').trigger('click');
      expect(store.showDisableSuggestionsConfirmation).toBe(true);
    });

    it('does not show confirmation dialog when enabling suggestions', async () => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = false;
      await wrapper.find('.button').trigger('click');
      expect(store.showDisableSuggestionsConfirmation).toBe(false);
    });
  });

  describe('confirmation dialog', () => {
    beforeEach(async () => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = true;
      store.showDisableSuggestionsConfirmation = true;
      await wrapper.vm.$nextTick();
    });

    it('renders the confirmation dialog', () => {
      expect(wrapper.find('.test-basic-dialog').exists()).toBe(true);
    });

    it('shows correct dialog title', () => {
      const dialog = wrapper.find('.test-basic-dialog');
      expect(dialog.attributes('title')).toBe('Disable AI-Assisted Feedback?');
    });

    it('shows correct dialog content', () => {
      expect(wrapper.text()).toContain(
        'This action will remove AI-generated suggestions, and any unsaved changes related to AI-assisted feedback will be lost.'
      );
    });

    it('renders cancel and disable buttons', () => {
      const buttons = wrapper.findAll('.test-standard-button');
      expect(buttons).toHaveLength(2);
      expect(buttons[0].text()).toBe('cancel');
      expect(buttons[1].text()).toBe('disable');
    });

    it('cancels toggle when cancel button is clicked', async () => {
      const store = useGradingSuggestionsStore();
      await wrapper.findAll('.test-standard-button')[0].trigger('click');
      expect(store.showDisableSuggestionsConfirmation).toBe(false);
      expect(store.suggestionsEnabled).toBe(true);
    });

    it('confirms toggle when disable button is clicked', async () => {
      const store = useGradingSuggestionsStore();
      // Mock the API response
      global.fetch.mockResolvedValueOnce({
        ok: true,
        json: () => Promise.resolve({ toggleValue: false })
      });

      await wrapper.findAll('.test-standard-button')[1].trigger('click');
      // Wait for the API call to complete
      await new Promise(resolve => setTimeout(resolve, 0));
      await wrapper.vm.$nextTick();

      expect(store.showDisableSuggestionsConfirmation).toBe(false);
      expect(store.suggestionsEnabled).toBe(false);
    });
  });

  describe('when feature is disabled at program level', () => {
    beforeEach(() => {
      wrapper = getWrapper({
        ...mockProps,
        featureEnabledAtProgramLevel: 'false'
      });
    });

    it('does not render the toggle button', () => {
      expect(wrapper.find('.button').exists()).toBe(false);
    });
  });
});
