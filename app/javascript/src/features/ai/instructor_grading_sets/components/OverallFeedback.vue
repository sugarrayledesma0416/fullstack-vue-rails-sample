<template>
  <div class="overall-feedback">
    <p
      v-if="overallComment.overallComment.length === 0"
      class="unavailable">
      AI feedback is not available for this submission.
    </p>
    <Suggestion
      v-else
      :id="overallComment.id"
      :isAdded="overallComment.accepted === true"
      :isEdited="overallComment.edited === true"
      :onAddSuggestion="accept"
      :onRejectSuggestion="reject">
      {{ overallComment.overallComment }}. {{ overallComment.explanation }}
    </Suggestion>
  </div>
</template>

<script setup>
  import Suggestion from './Suggestion';

  const props = defineProps({
    onAccept: {
      type: Function,
      required: true,
    },
    onReject: {
      type: Function,
      required: true,
    },
    /**
     * A reference to the overall comment in the store.
     */
    overallComment: {
      type: Object,
      required: true,
    },
  });

  /**
   * Accepts the overall comment.
   */
  function accept() {
    props.overallComment.accept();
    props.onAccept();
  }

  /**
   * Rejects the overall comment.
   */
  function reject() {
    props.overallComment.reject();
    props.onReject();
  }
</script>

<style lang="scss" scoped>
  .overall-feedback {
    font-family: Open Sans, sans-serif;
  }

  .unavailable {
    font-style: italic;
    margin: 0;
  }
</style>
