import { mount } from '@vue/test-utils';
import { createPinia, setActivePinia } from 'pinia';
import GradingSuggestionsApp from 'features/ai/instructor_grading_sets/GradingSuggestionsApp';
import { useGradingSuggestionsStore } from 'features/ai/instructor_grading_sets/stores/grading_suggestions_store';

let wrapper;
let pinia;

function getWrapper(props = {}) {
  return mount(GradingSuggestionsApp, {
    props,
    global: {
      plugins: [pinia],
      stubs: {
        SuggestionsPanel: {
          template: '<div class="test-suggestions-panel"><slot name="header-text"></slot><slot name="header-controls"></slot><slot name="suggestions"></slot></div>',
          props: ['suggestions']
        },
        GradingSuggestion: {
          template: '<div class="test-grading-suggestion" :app-id="appId" :index="index" :suggestion-id="suggestionId"></div>',
          props: ['appId', 'index', 'onAccept', 'onReject', 'onEdit', 'suggestionId']
        },
        OverallFeedback: {
          template: '<div class="test-overall-feedback" :overall-comment="JSON.stringify(overallComment)"></div>',
          props: ['overallComment', 'onAccept', 'onReject']
        },
        FlagSuggestionsDialog: {
          template: '<div class="test-flag-dialog" :app-id="appId"></div>',
          props: ['appId', 'onCloseDialog']
        },
        GradingModal: {
          template: '<div class="test-grading-modal" :show="show" :error-message="errorMessage" @close="onClose"></div>',
          props: ['show', 'errorMessage', 'onClose']
        },
        FoilPanel: {
          template: '<div class="test-foil-panel"><slot></slot></div>'
        },
        DiscreetButton: {
          template: '<button class="test-discreet-button"><slot></slot></button>'
        },
        FlagIcon: {
          template: '<span class="test-flag-icon"></span>'
        },
        HiddenFormFields: {
          template: '<div class="test-hidden-fields" :app-id="appId" :overall-comment-input-name="overallCommentInputName" :suggestion-input-name="suggestionInputName" :rating-details-input-name="ratingDetailsInputName"></div>',
          props: ['appId', 'overallCommentInputName', 'suggestionInputName', 'ratingDetailsInputName']
        }
      }
    }
  });
}

describe('GradingSuggestionsApp', () => {
  const mockProps = {
    feedbackElmId: 'test-feedback',
    gradingSuggestions: JSON.stringify([]),
    gradingSuggestionJob: JSON.stringify({ status: 'completed' }),
    gradingSuggestionsHiddenFormElmName: 'test-suggestions',
    overallComment: JSON.stringify(null),
    overallCommentElmId: 'test-comment',
    overallCommentHiddenFormElmName: 'test-overall-comment',
    aiGradingSuggestionsSettingUrl: '/test-url',
    ratingCategories: JSON.stringify([]),
    ratingDetails: JSON.stringify(null),
    defaultRatingCategoryId: '1',
    ratingDetailsHiddenFormElmName: 'test-rating-details',
    activityId: 1,
    programId: 1,
    sectionId: 1
  };

  beforeAll(() => {
    pinia = createPinia();
  });

  beforeEach(() => {
    setActivePinia(pinia);
    const store = useGradingSuggestionsStore();
    store.apps = [];
    document.body.innerHTML = `
      <div id="test-feedback" data-froala.editor="{}"></div>
      <div id="test-comment"></div>
    `;
    // Mock the Froala editor
    const editor = {
      comment_inline: {
        setAIGeneratedCommentEventHandlers: jest.fn()
      },
      undo: {
        reset: jest.fn()
      }
    };
    document.getElementById(mockProps.feedbackElmId)['data-froala.editor'] = editor;
    wrapper = getWrapper(mockProps);
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe('initialization', () => {
    it('registers the app with the store', () => {
      const store = useGradingSuggestionsStore();
      expect(store.getApp(mockProps.feedbackElmId)).toBeDefined();
    });

    it('sets up the editor event handlers', () => {
      const editor = document.getElementById(mockProps.feedbackElmId)['data-froala.editor'];
      // Trigger the composition editor initialization event
      document.dispatchEvent(new CustomEvent('compositionEditorInitializedEvent', {
        detail: { element: { id: mockProps.feedbackElmId } }
      }));
      expect(editor.comment_inline.setAIGeneratedCommentEventHandlers).toHaveBeenCalled();
    });
  });

  describe('when suggestions are enabled', () => {
    beforeEach(() => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = true;
    });

    describe('when there are no suggestions', () => {
      it('displays the no suggestions message', () => {
        expect(wrapper.find('.grading-suggestions-not-found-message').exists()).toBe(true);
        expect(wrapper.find('.grading-suggestions-not-found-message').text())
          .toBe('AI analysis of this response identified no errors.');
      });
    });

    //TODO: Add tests for when there are suggestions
  });

  describe('when suggestions are disabled', () => {
    beforeEach(() => {
      const store = useGradingSuggestionsStore();
      store.suggestionsEnabled = false;
    });

    it('hides the suggestions panel', () => {
      expect(wrapper.find('.grading-suggestions-app').classes()).toContain('hidden');
    });
  });

  describe('overall feedback', () => {
    const mockOverallComment = {
      id: 1,
      overallComment: 'Test overall comment',
      explanation: 'Test explanation',
      accepted: false
    };

    //TODO: Add tests for when there is an overall comment

    //TODO: Add tests for when there is no overall comment
  });

  describe('flag dialog', () => {
    it('renders the flag dialog component', () => {
      expect(wrapper.find('.test-flag-dialog').exists()).toBe(true);
    });

    it('passes correct props to flag dialog', () => {
      const flagDialog = wrapper.find('.test-flag-dialog');
      expect(flagDialog.attributes()).toEqual({
        'app-id': mockProps.feedbackElmId,
        'class': 'test-flag-dialog'
      });
    });
  });

  describe('grading modal', () => {
    it('renders the grading modal component', () => {
      expect(wrapper.find('.test-grading-modal').exists()).toBe(true);
    });

    it('passes correct props to grading modal', () => {
      const gradingModal = wrapper.find('.test-grading-modal');
      expect(gradingModal.attributes()).toEqual({
        'show': 'false',
        'class': 'test-grading-modal'
      });
    });
  });

  describe('hidden form fields', () => {
    it('renders the hidden form fields component', () => {
      expect(wrapper.find('.test-hidden-fields').exists()).toBe(true);
    });

    it('passes correct props to hidden form fields', () => {
      const hiddenFields = wrapper.find('.test-hidden-fields');
      expect(hiddenFields.attributes()).toEqual({
        'app-id': mockProps.feedbackElmId,
        'overall-comment-input-name': mockProps.overallCommentHiddenFormElmName,
        'suggestion-input-name': mockProps.gradingSuggestionsHiddenFormElmName,
        'rating-details-input-name': mockProps.ratingDetailsHiddenFormElmName,
        'class': 'test-hidden-fields'
      });
    });
  });
});
