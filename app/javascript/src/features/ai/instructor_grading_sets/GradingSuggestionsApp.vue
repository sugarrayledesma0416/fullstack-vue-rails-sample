<template>
  <div>
    <FoilPanel
      class="grading-suggestions-app"
      :class="{'hidden': !store.suggestionsEnabled}">
      <GradingModal
        :show="showModal"
        :error-message="modalErrorMessage"
        @close="closeModal"
      />
      <SuggestionsPanel
        v-if="store.suggestionsEnabled && app.foundNoSuggestions()">
        <template #header-text>
          AI-Generated Suggestions
        </template>
        <template #suggestions>
          <span class="grading-suggestions-not-found-message">
            AI analysis of this response identified no errors.
          </span>
        </template>
      </SuggestionsPanel>

      <SuggestionsPanel
        v-if="app.suggestions.length && store.suggestionsEnabled">
        <template #header-text>
          AI-Generated Suggestions
        </template>
        <template #header-controls>
          <tippy
            :content="'Give Feedback'"
            placement="top">
            <DiscreetButton
              type="button"
              :class="testClass('flag-icon')"
              @click.prevent="openFlagDialog">
              <FlagIcon />
            </DiscreetButton>
          </tippy>
        </template>
        <template #suggestions>
          <GradingSuggestion
            v-for="(suggestion, index) in app.suggestions"
            :key="suggestion.id"
            :appId="appId"
            :index="index"
            :onAccept="() => addSuggestionToEditor(suggestion)"
            :onReject="() => removeSuggestionFromEditor(suggestion)"
            :onEdit="() => editSuggestion(suggestion)"
            :suggestionId="suggestion.id" />
        </template>
      </SuggestionsPanel>

      <br v-if="app.suggestions.length && store.suggestionsEnabled">

      <SuggestionsPanel
        v-if="app.overallComment && store.suggestionsEnabled">
        <template #header-text>
          Overall Feedback
        </template>
        <template #header-controls>
          <tippy
            v-if="app.suggestions.length == 0"
            :content="'Give Feedback'"
            placement="top">
            <DiscreetButton
              type="button"
              :class="testClass('flag-icon')"
              @click.prevent="openFlagDialog">
              <FlagIcon />
            </DiscreetButton>
          </tippy>
        </template>
        <template #suggestions>
          <OverallFeedback
            :overallComment="app.overallComment"
            :onAccept="addOverallCommentToEditor"
            :onReject="removeOverallCommentFromEditor" />
        </template>
      </SuggestionsPanel>

      <SuggestionsPanel v-else-if="app.suggestions.length && store.suggestionsEnabled">
        <template #header-text>
          Overall Feedback
        </template>
        <template #suggestions>
          <i>AI feedback is not available for this submission.</i>
        </template>
      </SuggestionsPanel>
      <div v-if="hasNoAIFeedback">
        <div v-if="emptyResponse">
          <i>No AI-generated feedback or suggestions found for this submission.</i>
        </div>
        <div v-else>
          <i>No AI feedback or suggestions found for this submission.</i>
          <button
            type="button"
            class="c-link  u-txt-black  u-txt-under"
            style="border: none; background: none; padding: 0; font: inherit; cursor: pointer;"
            @click="startFeedback">
            Try generating suggestions now.
          </button>
        </div>
      </div>
      <HiddenFormFields
        :appId="appId"
        :overallCommentInputName="overallCommentHiddenFormElmName"
        :suggestionInputName="gradingSuggestionsHiddenFormElmName"
        :ratingDetailsInputName="ratingDetailsHiddenFormElmName" />
      <FlagSuggestionsDialog
        :appId="appId"
        :onCloseDialog="closeFlagDialog" />
    </FoilPanel>
  </div>
</template>

<script>
  export default {
    /**
     * Expose the name of this app to Vue DevTools, useful for pages that mount a large number of
     * Vue apps.
     */
    name: 'GradingSuggestionsApp',
  };
</script>

<script setup>
  import { computed, watch, ref } from 'vue';
  /* eslint-disable-next-line no-unused-vars */
  import FroalaEditor from 'froala-editor';
  import SuggestionsPanel from './components/SuggestionsPanel';
  import GradingSuggestion from './components/GradingSuggestion';
  import FoilPanel from './components/FoilPanel';
  import DiscreetButton from './components/DiscreetButton';
  import FlagIcon from './components/FlagIcon';
  import OverallFeedback from './components/OverallFeedback';
  import { useGradingSuggestionsStore } from './stores/grading_suggestions_store';
  import HiddenFormFields from './components/HiddenFormFields';
  import {
    acceptOverallComment,
    removeOverallComment,
    setupOverallCommentInterop } from './lib/overall_comment';
  import { Tippy } from 'vue-tippy';
  import FlagSuggestionsDialog from './components/FlagSuggestionsDialog';
  import { testClass } from 'music';
  import GradingModal from 'shared/grading/GradingModal.vue';
  import { useAiGradingPolling } from 'shared/composables/useAiGradingPolling';
  const props = defineProps(
    {
      feedbackElmId: { required: true, type: String },
      gradingSuggestions: { required: true, type: String },
      gradingSuggestionJob: { required: true, type: String },
      gradingSuggestionsHiddenFormElmName: { required: true, type: String },
      overallComment: { required: true, type: String },
      overallCommentElmId: { required: true, type: String },
      overallCommentHiddenFormElmName: {
        type: String,
        required: true,
      },
      aiGradingSuggestionsSettingUrl: { required: true, type: String },
      ratingCategories: { required: true, type: String },
      ratingDetails: { required: true, type: String },
      defaultRatingCategoryId: { required: true, type: String },
      ratingDetailsHiddenFormElmName: { required: true, type: String },
      activityId: { required: true, type: Number },
      programId: { required: true, type: Number },
      sectionId: { required: true, type: Number },
    }
  );

  const showModal = ref(false);
  const modalErrorMessage = ref(null);

  function closeModal() {
    showModal.value = false;
    modalErrorMessage.value = null;
  }

  const appId = props.feedbackElmId;

  const store = useGradingSuggestionsStore();
  store.registerApp(
    {
      feedbackElement: document.getElementById(props.feedbackElmId),
      id: appId,
      overallComment: props.overallComment ? JSON.parse(props.overallComment) : null,
      overallCommentElement: document.getElementById(props.overallCommentElmId),
      ratingCategories: JSON.parse(props.ratingCategories),
      ratingDetails: props.ratingDetails ? JSON.parse(props.ratingDetails) : null,
      defaultRatingCategoryId: Number(props.defaultRatingCategoryId),
      suggestions: JSON.parse(props.gradingSuggestions),
      suggestionJob: JSON.parse(props.gradingSuggestionJob),
      suggestionsElementName: props.gradingSuggestionsHiddenFormElmName,
    }
  );

  const app = store.getApp(appId);

  const editor = document.getElementById(props.feedbackElmId)['data-froala.editor'];

  const hasNoAIFeedback = computed(
    () => store.suggestionsEnabled && app.suggestions.length == 0 && !app.overallComment
  );

  const emptyResponse = computed(
    () => app.suggestionJob.status === 'failed_empty_response'
  );

  const {
    startAIFeedback,
    startPolling,
    stopPolling,
    checkGradingStatus,
    status
  } = useAiGradingPolling({
    activityId: props.activityId,
    programId: props.programId,
    sectionId: props.sectionId,
    onSuccess: () => {
      window.onbeforeunload = null;
      showModal.value = false;
      window.location.reload();
    },
    onFailure: () => {
      showModal.value = false;
      modalErrorMessage.value = 'An unexpected error occurred.';
    }
  });

  document.addEventListener(
    'compositionEditorInitializedEvent',
    (e) => {
      if (e.detail.element.id === props.feedbackElmId) {
        editor.comment_inline.setAIGeneratedCommentEventHandlers({
          onCommentDelete: onGradingSuggestionDelete,
          onCommentEdit: onGradingSuggestionEdit,
          onCommentListChange: onGradingSuggestionListChange,
        });

        if (store.suggestionsEnabled) {
          addAllSuggestions();
        } else {
          removeAllSuggestions();
        }
      }
    }
  );

  if (app.overallComment) setupOverallCommentInterop(app.overallComment, props.overallCommentElmId);

  /**
   * Callback when the user deletes a grading suggestion from the Froala editor.
   * This callback is *not* called when deleting a grading suggestion programatically.
   * @param {number} gradingSuggestionId - The ID of the grading suggestion
   */
  function onGradingSuggestionDelete(gradingSuggestionId) {
    const gradingSuggestion = app.suggestions.find(
      (suggestion) => suggestion.id === gradingSuggestionId
    );

    if (gradingSuggestion) {
      gradingSuggestion.reject();
    }
  }

  /**
   * Callback when the user edits a grading suggestion in the Froala editor.
   * @param {number} gradingSuggestionId - The ID of the grading suggestion
   * @param {string} content - The edited content of the grading suggestion
   */
  function onGradingSuggestionEdit(gradingSuggestionId, content) {
    const gradingSuggestion = app.suggestions.find(
      (gradingSuggestion) => gradingSuggestion.id == gradingSuggestionId
    );

    if (gradingSuggestion) {
      gradingSuggestion.edited = gradingSuggestion.errorExplanation !== content;
    }
  }

  /**
   * Callback when the list of grading suggestions in modified in the editor due
   * to the use of the undo/redo feature.
   * @param {Array<Suggestion>} suggestions - The list of suggestions present in the editor
   */
  function onGradingSuggestionListChange(suggestions) {
    app.suggestions.forEach((appSuggestion) => {
      const editorSuggestion = suggestions.find((suggestion) => suggestion.id == appSuggestion.id);

      if (editorSuggestion) {
        if (!appSuggestion.accepted) {
          appSuggestion.accept();
        }
        appSuggestion.edited = appSuggestion.errorExplanation !== editorSuggestion.content;
      } else {
        if (!appSuggestion.rejected) {
          appSuggestion.reject();
        }
      }
    });
  }

  function startFeedback() {
    showModal.value = true;
    startAIFeedback({});
  }

  /**
   * Add all the suggestions
   */
  function addAllSuggestions() {
    app.suggestions.forEach((suggestion, index) => {
      // Only apply suggestions that have not been accepted and not explicitly rejected
      if (!suggestion.accepted && !suggestion.rejected) {
        suggestion.accept();
        addSuggestionToEditor(suggestion);
      }
    });
  }

  /**
   * Open the instructor comment box if not already open.
   * Disable the instructor comment checkbox if grading suggestions are enabled.
   */
  function openInstructorCommentBox() {
    const commentsSelectorElm = document.getElementById('show_hide_comments');
    if (commentsSelectorElm) {
      if (commentsSelectorElm.checked == false) {
        commentsSelectorElm.click();
      }
      commentsSelectorElm.disabled = store.suggestionsEnabled;
    }
  }

  /**
    * Add the specified overall comment to the instructor comment.
    */
  function addOverallCommentToEditor() {
    acceptOverallComment(
      app.overallComment, props.overallCommentElmId, { callback: openInstructorCommentBox });
  }

  /**
    * Remove specified overall comment from the instructor comment,
    * preserving any other text in the instructor comment.
    */
  function removeOverallCommentFromEditor() {
    removeOverallComment(
      app.overallComment, props.overallCommentElmId, { callback: openInstructorCommentBox });
  }

  /**
   * @typedef Suggestion
   * @property {number} id - primary key of suggestion record in database
   * @property {string} incorrect_text - the text to be replaced
   * @property {string} suggested_correct_text - suggested replacement
   * @property {string} error_explanation - reason for suggested replacement
   * @property {boolean} accepted - true if user want to use the suggestion
   */

  /**
   * @param {Suggestion} suggestion
   * Add specified suggestion to student response.
   */
  function addSuggestionToEditor(suggestion) {
    const index = app.suggestions.findIndex(
      (element) => element.id == suggestion.id
    );

    editor.comment_inline.createAiGeneratedCommentInline({
      commentInline: suggestion.errorExplanation,
      commentNumber: index + 1,
      gradingSuggestionId: suggestion.id,
      incorrectText: suggestion.incorrectText,
      incorrectTextBeginOffset: suggestion.incorrectTextBeginOffset,
      incorrectTextEndOffset: suggestion.incorrectTextEndOffset,
    });
  }

  /**
   * Remove specified suggestion from student response.
   * @param {Suggestion} suggestion
   */
  function removeSuggestionFromEditor(suggestion) {
    editor.comment_inline.deleteAiGeneratedCommentInline({
      gradingSuggestionId: suggestion.id,
    });
  }

  /**
   * @param {Suggestion} suggestion
   * Open the editor to edit the specified suggestion.
   */
  function editSuggestion(suggestion) {
    editor.comment_inline.openAiGeneratedCommentInline({
      gradingSuggestionId: suggestion.id,
    });
  }

  /**
   * Remove all suggestions.
   */
  function removeAllSuggestions() {
    app.suggestions.forEach(
      (suggestion) => {
        if (suggestion.accepted) {
          removeSuggestionFromEditor(suggestion);
        }
        // Mark the suggestion as removed (no longer applied, but
        // not explicitly rejected).
        suggestion.remove();
      }
    );
    // Reset the undo stack to block the user from adding the suggestions back
    // using the undo feature.
    editor.undo.reset();
  }

  watch(
    () => store.suggestionsEnabled,
    (newValue, oldValue) => {
      openInstructorCommentBox();
      toggleGradingSuggestions(newValue, oldValue);
      toggleOverallComment(newValue);
    }
  );

  /**
   * Toggles the grading suggestions on/off based on the new value.  Attempting to toggle
   * suggestions before the store has initialized can cause issues with the Froala instance, to
   * prevent this, the function checks if the old value is a boolean before proceeding.
   * @param {boolean | null} newToggleValue
   * @param {boolean | null} oldToggleValue
   */
  function toggleGradingSuggestions(newToggleValue, oldToggleValue) {
    if (typeof oldToggleValue === 'boolean') {
      newToggleValue ? addAllSuggestions() : removeAllSuggestions();
    }
  }

  /**
   * Toggles the overall comment on/off based on the new value.
   * @param {boolean | null} toggleValue
   */
  function toggleOverallComment(toggleValue) {
    if (app.overallComment) {
      if (toggleValue) {
        if (!app.overallComment.accepted && !app.overallComment.rejected) {
          app.overallComment.accept();
          addOverallCommentToEditor();
        }
      } else {
        removeOverallCommentFromEditor();
        app.overallComment.remove();
      }
    }
  }

  /**
   * Open the flag dialog.
   */
  function openFlagDialog() {
    app.showFlagSuggestionDialog = true;

    // Disable the fixed header when the modal is open
    $('#grading_set_static_wrap').toggleClass('fix_at_top', false);
  }

  /**
   * Close the flag dialog.
   */
  function closeFlagDialog() {
    app.showFlagSuggestionDialog = false;
  }
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .grading-suggestions-not-found-message {
    font-family: 'Open Sans', sans-serif;
    font-style: italic;
  }

  .grading-suggestions-app {
    margin-top: 1rem;
    &--hidden {
      clip: rect(0 0 0 0);
      clip-path: inset(50%);
      height: 1px;
      overflow: hidden;
      position: absolute;
      white-space: nowrap;
      width: 1px;
    }
  }
</style>
