<template>
  <div class="inclusively-hidden">
    <div v-for="suggestion in app.suggestions" :key="suggestion.id">
      <input
        v-if="suggestion.ratingCategoryId"
        type="hidden"
        :name="`${suggestionInputName}[${suggestion.id}][rating_category_id]`"
        :value="suggestion.ratingCategoryId">
      <input
        v-if="suggestion.ratingComment"
        type="hidden"
        :name="`${suggestionInputName}[${suggestion.id}][rating_comment]`"
        :value="suggestion.ratingComment">
      <input
        v-if="suggestion.accepted"
        type="hidden"
        :name="`${suggestionInputName}[${suggestion.id}][accepted]`"
        :value="suggestion.accepted">
      <input
        v-if="suggestion.rejected"
        type="hidden"
        :name="`${suggestionInputName}[${suggestion.id}][rejected]`"
        :value="suggestion.rejected">
      <input
        v-if="suggestion.edited"
        type="hidden"
        :name="`${suggestionInputName}[${suggestion.id}][edited]`"
        :value="suggestion.edited">
    </div>
    <div v-if="overallComment">
      <input
        v-if="overallComment.ratingCategoryId"
        type="hidden"
        :name="`${overallCommentInputName}[${overallComment.id}][rating_category_id]`"
        :value="overallComment.ratingCategoryId">
      <input
        v-if="overallComment.ratingComment"
        type="hidden"
        :name="`${overallCommentInputName}[${overallComment.id}][rating_comment]`"
        :value="overallComment.ratingComment">
      <input
        v-if="overallComment.accepted"
        type="hidden"
        :name="`${overallCommentInputName}[${overallComment.id}][accepted]`"
        :value="overallComment.accepted">
      <input
        v-if="overallComment.rejected"
        type="hidden"
        :name="`${overallCommentInputName}[${overallComment.id}][rejected]`"
        :value="overallComment.rejected">
      <input
        v-if="overallComment.edited"
        type="hidden"
        :name="`${overallCommentInputName}[${overallComment.id}][edited]`"
        :value="overallComment.edited">
    </div>
    <div>
      <input
        type="hidden"
        :name="`${ratingDetailsInputName}[comment]`"
        :value="app.ratingDetails.comment">
    </div>
  </div>
</template>

<script setup>
  import { useGradingSuggestionsStore } from '../stores/grading_suggestions_store';

  const props = defineProps({
    appId: {
      type: String,
      required: true,
    },
    suggestionInputName: {
      type: String,
      required: true,
    },
    overallCommentInputName: {
      type: String,
      required: true,
    },
    ratingDetailsInputName: {
      type: String,
      required: true,
    },
  });

  const store = useGradingSuggestionsStore();
  const app = store.getApp(props.appId);
  const overallComment = app.overallComment;
</script>

<style lang="scss" scoped>
  .inclusively-hidden {
    clip: rect(0 0 0 0);
    clip-path: inset(50%);
    height: 1px;
    overflow: hidden;
    position: absolute;
    white-space: nowrap;
    width: 1px;
  }
</style>
