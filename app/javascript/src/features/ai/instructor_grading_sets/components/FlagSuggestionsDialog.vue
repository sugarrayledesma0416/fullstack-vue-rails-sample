<template>
  <BasicDialog
    v-show="app.showFlagSuggestionDialog"
    class="flagging-dialog"
    :class="{ 'is-open': app.showFlagSuggestionDialog }"
    :isConfirmationDialog="false"
    :isModal="true"
    title="Help us improve the AI feedback."
    @close-dialog="cancelFlaggingHeader">
    <template #body>
      <div class="u-mar-bot-16">
        Flag which suggestions were incorrect or need improvement:
      </div>
      <FlagSuggestion
        v-for="(suggestion, index) in state.suggestions"
        :key="suggestion.id"
        class="grading-suggestion"
        :index="index"
        :suggestion="suggestion"
        :categories="app.ratingCategories"
        :showRatingComment="suggestion.ratingCategoryId === app.defaultRatingCategoryId"
        :onSelection="(checked) => changeSuggestionSelection(suggestion, checked)"
        :onRatingCategorySelection="(categoryId) => setSuggestionRatingCategoryId(suggestion, categoryId)"
        :onRatingCommentChange="(value) => setSuggestionRatingComment(suggestion, value)">
        {{ suggestion.errorExplanation }}
      </FlagSuggestion>
      <FlagSuggestion
        v-if="state.overallComment"
        class="overall-comment"
        :suggestion="state.overallComment"
        :categories="app.ratingCategories"
        :showRatingComment="state.overallComment.ratingCategoryId === app.defaultRatingCategoryId"
        :onSelection="(checked) => changeSuggestionSelection(state.overallComment, checked)"
        :onRatingCategorySelection="(categoryId) => setSuggestionRatingCategoryId(state.overallComment, categoryId)"
        :onRatingCommentChange="(value) => setSuggestionRatingComment(state.overallComment, value)">
        {{ state.overallComment.overallComment }}. {{ state.overallComment.explanation }}
      </FlagSuggestion>
      <div v-if="someSuggestionSelected">
        <div class="u-mar-bot-8">
          Any additional feedback about the AI suggestions? (optional)
        </div>
        <div class="c-form-item">
          <textarea
            v-model="state.additionalComment"
            class="additional-feedback"
            autocomplete="off"
            rows="3" />
        </div>
      </div>
    </template>
    <template #footer>
      <div class="flagging-dialog__buttons">
        <StandardButton
          class="u-mar-rt-8  js-dialog-a11y__first-focus-elm"
          @click="cancelFlaggingHeader">
          Cancel
        </StandardButton>
        <StandardButton
          variant="primary"
          class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
          :class="testClass('submit-button')"
          :disabled="isSubmitButtonDisabled()"
          @click="saveFlaggingDialog">
          Submit
        </StandardButton>
      </div>
    </template>
  </BasicDialog>
</template>

<script setup>
  import { defineProps, reactive, computed } from 'vue';
  import FlagSuggestion from './FlagSuggestion';
  import { useGradingSuggestionsStore } from '../stores/grading_suggestions_store';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import { StandardButton, testClass } from 'music';

  const props = defineProps({
    appId: {
      type: String,
      required: true,
    },
    onCloseDialog: {
      type: Function,
      required: true,
    },
  });

  const store = useGradingSuggestionsStore();
  const app = store.getApp(props.appId);

  const state = reactive({
    suggestions: app.suggestions.map((suggestion) => {
      return makeReactiveSuggestion(suggestion);
    }),
    overallComment: makeReactiveOverallComment(app.overallComment),
    additionalComment: app.ratingDetails.comment,
  });

  /**
   * Returns an object from a grading suggestion object.
   * @param {SuggestionModel} suggestion
   * @return {Object|null}
   */
  function makeReactiveSuggestion(suggestion) {
    return {
      id: suggestion.id,
      ratingCategoryId: suggestion.ratingCategoryId,
      ratingComment: suggestion.ratingComment,
      errorExplanation: suggestion.errorExplanation,
    };
  }

  /**
   * Returns an object from an overall comment object.
   * @param {OverallCommentModel} overallComment
   * @return {Object|null}
   */
  function makeReactiveOverallComment(overallComment) {
    if (overallComment) {
      return {
        id: overallComment.id,
        ratingCategoryId: overallComment.ratingCategoryId,
        ratingComment: overallComment.ratingComment,
        overallComment: overallComment.overallComment,
        explanation: overallComment.explanation,
      };
    } else {
      return null;
    }
  }

  const someSuggestionSelected = computed(() => {
    const suggestionSelected = state.suggestions.some((suggestion) => {
      return suggestion.ratingCategoryId !== null;
    });
    return suggestionSelected || state.overallComment?.ratingCategoryId !== null;
  });

  /**
   * Function called when the user cancel the flagging by closing the modal.
   * It reverts the temporary changes done to each suggestion.
   */
  function cancelFlaggingHeader() {
    // Revert changes
    state.suggestions.forEach((ratedSuggestion) => {
      const suggestion = app.getSuggestion(ratedSuggestion.id);
      ratedSuggestion.ratingComment = suggestion.ratingComment;
      ratedSuggestion.ratingCategoryId = suggestion.ratingCategoryId;
    });
    if (state.overallComment) {
      state.overallComment.ratingComment = app.overallComment.ratingComment;
      state.overallComment.ratingCategoryId = app.overallComment.ratingCategoryId;
    }
    state.additionalComment = app.ratingDetails.comment;

    props.onCloseDialog();
  }

  /**
   * Save the rating properties into the suggestions objects.
   */
  function saveFlaggingDialog() {
    // Apply changes
    state.suggestions.forEach((ratedSuggestion) => {
      const suggestion = app.getSuggestion(ratedSuggestion.id);
      suggestion.ratingCategoryId = ratedSuggestion.ratingCategoryId;
      // Only save the comment if the suggestion is checked
      if (ratedSuggestion.ratingCategoryId !== null) {
        suggestion.ratingComment = ratedSuggestion.ratingComment;
      } else {
        suggestion.ratingComment = '';
      }
    });
    if (state.overallComment) {
      app.overallComment.ratingCategoryId = state.overallComment.ratingCategoryId;
      if (state.overallComment.ratingCategoryId !== null) {
        app.overallComment.ratingComment = state.overallComment.ratingComment;
      } else {
        app.overallComment.ratingComment = '';
      }
    }
    app.ratingDetails.comment = state.additionalComment;

    props.onCloseDialog();
  }

  /**
   * Called when a suggestion is checked/unchecked.
   * @param {Object} suggestion
   * @param {boolean} checked
   */
  function changeSuggestionSelection(suggestion, checked) {
    if (checked) {
      suggestion.ratingCategoryId = 0;
    } else {
      suggestion.ratingCategoryId = null;
    }
  }

  /**
   * Called when a suggestion's rating category is changed.
   * @param {Object} suggestion
   * @param {number} categoryId
   */
  function setSuggestionRatingCategoryId(suggestion, categoryId) {
    suggestion.ratingCategoryId = categoryId;
  }

  /**
   * Called when a suggestion is comment is updated.
   * @param {Object} suggestion
   * @param {string} comment
   */
  function setSuggestionRatingComment(suggestion, comment) {
    suggestion.ratingComment = comment;
  }

  /**
   * Returns true if the Submit button should be disabled.
   * This is the case when a suggestion is selected but no rating category is selected.
   * @return {boolean}
   */
  function isSubmitButtonDisabled() {
    return state.suggestions.some((suggestion) => {
      return isSuggestionRatingCategorySelected(suggestion);
    }) || (state.overallComment && isSuggestionRatingCategorySelected(state.overallComment));
  }

  /**
   * Returns true if the suggestion is selected but no rating category is selected
   * @param {Object} suggestion
   * @return {Boolean}
   */
  function isSuggestionRatingCategorySelected(suggestion) {
    return suggestion.ratingCategoryId === 0;
  }
</script>

<style lang="sass" scoped>
  .flagging-dialog__buttons {
    display: flex;
    justify-content: flex-end;
  }
</style>
