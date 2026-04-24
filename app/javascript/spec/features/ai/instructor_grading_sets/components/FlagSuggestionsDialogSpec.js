import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import FlagSuggestionsDialog from 'features/ai/instructor_grading_sets/components/FlagSuggestionsDialog';
import { useGradingSuggestionsStore } from 'features/ai/instructor_grading_sets/stores/grading_suggestions_store';

let wrapper;
let pinia;
let store;

const mockAppId = 'test-feedback';
const mockSuggestions = [
  {
    id: 1,
    ratingCategoryId: null,
    ratingComment: '',
    errorExplanation: 'Test suggestion 1'
  },
  {
    id: 2,
    ratingCategoryId: null,
    ratingComment: '',
    errorExplanation: 'Test suggestion 2'
  }
];

const mockOverallComment = {
  id: 'overall',
  ratingCategoryId: null,
  ratingComment: '',
  overallComment: 'Test overall comment',
  explanation: 'Test explanation'
};

const mockRatingCategories = [
  { id: 1, name: 'Category 1' },
  { id: 2, name: 'Category 2' }
];

function getWrapper(props = {}) {
  return mount(FlagSuggestionsDialog, {
    props: {
      appId: mockAppId,
      onCloseDialog: jest.fn(),
      ...props
    },
    global: {
      plugins: [pinia],
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
        FlagSuggestion: {
          template: `
            <div class="test-flag-suggestion">
              <input type="checkbox" class="test-suggestion-checkbox" @change="$emit('selection', $event.target.checked)" />
              <select class="test-rating-category" @change="$emit('ratingCategorySelection', $event.target.value)">
                <option v-for="category in categories" :key="category.id" :value="category.id">
                  {{ category.name }}
                </option>
              </select>
              <textarea v-if="showRatingComment" class="test-rating-comment" @input="$emit('ratingCommentChange', $event.target.value)"></textarea>
              <slot></slot>
            </div>
          `,
          props: ['suggestion', 'categories', 'showRatingComment', 'onSelection', 'onRatingCategorySelection', 'onRatingCommentChange']
        },
        StandardButton: {
          template: '<button class="test-standard-button" :disabled="disabled" @click="$emit(\'click\')"><slot></slot></button>',
          props: ['variant', 'disabled']
        }
      }
    }
  });
}

describe('FlagSuggestionsDialog', () => {
  beforeEach(() => {
    pinia = createPinia();
    setActivePinia(pinia);
    store = useGradingSuggestionsStore();

    // Mock store app data with all required fields for GradingSuggestionsAppModel
    store.registerApp({
      feedbackElementId: mockAppId,
      id: mockAppId,
      suggestions: mockSuggestions,
      overallComment: mockOverallComment,
      ratingCategories: mockRatingCategories,
      ratingDetails: { comment: '' },
      showFlagSuggestionDialog: true,
      defaultRatingCategoryId: 1,
      overallCommentElement: 'test-overall-comment',
      overallCommentName: 'test-overall-comment-name',
      suggestionsElementName: 'test-suggestions',
      suggestionJob: { status: 'completed' }
    });
  });

  describe('initialization', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('renders the basic dialog component', () => {
      expect(wrapper.find('.test-basic-dialog').exists()).toBe(true);
    });

    it('displays correct dialog title', () => {
      const dialog = wrapper.find('.test-basic-dialog');
      expect(dialog.attributes('title')).toBe('Help us improve the AI feedback.');
    });

    it('renders flag suggestions for each suggestion', () => {
      const flagSuggestions = wrapper.findAll('.test-flag-suggestion');
      expect(flagSuggestions).toHaveLength(mockSuggestions.length + 1); // +1 for overall comment
    });

    it('renders cancel and submit buttons', () => {
      const buttons = wrapper.findAll('.test-standard-button');
      expect(buttons).toHaveLength(2);
      expect(buttons[0].text()).toBe('Cancel');
      expect(buttons[1].text()).toBe('Submit');
    });
  });

  describe('suggestion flagging', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('enables submit button when suggestion is selected with rating category', async () => {
      const flagSuggestion = wrapper.find('.test-flag-suggestion');
      await flagSuggestion.find('.test-suggestion-checkbox').setValue(true);
      await flagSuggestion.find('.test-rating-category').setValue('1');

      const submitButton = wrapper.findAll('.test-standard-button')[1];
      expect(submitButton.attributes('disabled')).toBeFalsy();
    });
  });

  describe('dialog actions', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('calls onCloseDialog when cancel button is clicked', async () => {
      const cancelButton = wrapper.findAll('.test-standard-button')[0];
      await cancelButton.trigger('click');
      expect(wrapper.props('onCloseDialog')).toHaveBeenCalled();
    });

    it('calls onCloseDialog when submit button is clicked', async () => {
      // First select a suggestion and rating category
      const flagSuggestion = wrapper.find('.test-flag-suggestion');
      await flagSuggestion.find('.test-suggestion-checkbox').setValue(true);
      await flagSuggestion.find('.test-rating-category').setValue('1');

      // Then click submit
      const submitButton = wrapper.findAll('.test-standard-button')[1];
      await submitButton.trigger('click');
      expect(wrapper.props('onCloseDialog')).toHaveBeenCalled();
    });
  });

  describe('additional feedback', () => {
    beforeEach(() => {
      wrapper = getWrapper();
    });

    it('shows additional feedback textarea when a suggestion is selected', async () => {
      const flagSuggestion = wrapper.find('.test-flag-suggestion');
      await flagSuggestion.find('.test-suggestion-checkbox').setValue(true);

      expect(wrapper.find('.additional-feedback').exists()).toBe(true);
    });

    it('saves additional feedback when submitted', async () => {
      // Select a suggestion and rating category
      const flagSuggestion = wrapper.find('.test-flag-suggestion');
      await flagSuggestion.find('.test-suggestion-checkbox').setValue(true);
      await flagSuggestion.find('.test-rating-category').setValue('1');

      // Add additional feedback
      const additionalFeedback = wrapper.find('.additional-feedback');
      await additionalFeedback.setValue('Test additional feedback');

      // Submit
      const submitButton = wrapper.findAll('.test-standard-button')[1];
      await submitButton.trigger('click');

      // Check that the feedback was saved
      expect(store.getApp(mockAppId).ratingDetails.comment).toBe('Test additional feedback');
    });
  });
});
