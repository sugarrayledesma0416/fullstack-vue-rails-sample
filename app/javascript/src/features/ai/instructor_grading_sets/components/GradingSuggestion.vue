<template>
  <div class="grading-suggestion">
    <Suggestion
      :id="suggestion.id"
      :index="index + 1"
      :isAdded="suggestion.accepted"
      :isEdited="suggestion.edited"
      :onAddSuggestion="accept"
      :onRejectSuggestion="reject"
      :onEditSuggestion="edit">
      {{ suggestion.errorExplanation }}
    </Suggestion>
  </div>
</template>

<script setup>
  import { defineProps } from 'vue';
  import Suggestion from './Suggestion';
  import { useGradingSuggestionsStore } from '../stores/grading_suggestions_store';

  const props = defineProps({
    appId: {
      type: String,
      required: true,
    },
    onAccept: {
      type: Function,
      required: true,
    },
    onReject: {
      type: Function,
      required: true,
    },
    onEdit: {
      type: Function,
      required: true,
    },
    suggestionId: {
      type: Number,
      required: true,
    },
    index: {
      type: Number,
      required: true,
    },
  });

  const store = useGradingSuggestionsStore();
  const suggestion = store.getSuggestion(props.appId, props.suggestionId);

  /**
   * Accepts the suggestion.
   */
  function accept() {
    suggestion.accept();
    props.onAccept();
  }

  /**
   * Rejects the suggestion.
   */
  function reject() {
    suggestion.reject();
    props.onReject();
  }

  /**
   * Edits the suggestion (Open the editor).
   */
  function edit() {
    props.onEdit();
  }
</script>
