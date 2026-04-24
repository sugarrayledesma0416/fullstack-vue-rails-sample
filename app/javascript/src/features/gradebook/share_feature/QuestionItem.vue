<template>
  <div>
    <div
      ref="body"
      class="c-review-modal"
      v-html="mutatedModalBody" />
  </div>
</template>
<script setup>

  defineProps({
    mutatedModalBody: { required: true, type: String },
    errorIconPath: { required: true, type: String },
    successIconPath: { required: true, type: String },
  });

  const errorIconPath = `url(${errorIconPath})`;
  const successIconPath = `url(${successIconPath})`;
</script>
<style lang="scss" scoped>
  .c-review-modal {
    --answer-blank-color: #CCC;
    --answer-correct-color: #01AA4D;
    --answer-incorrect-border-color: #BE1A24;
    --answer-incorrect-color: #FFECEC;
    --error-icon-path: v-bind(`${errorIconPath}`);
    --success-icon-path: v-bind(`${successIconPath}`);
  }

  .c-review-modal :deep(.c-standard-details-reference) {
    max-height: 37rem;
    overflow-y: auto;
  }

  .c-review-modal :deep(.c-standard-details-question) {
    min-height: 30rem;
    display: flex;
    flex-direction: column;
    align-content: center;
    align-items: center;
    max-height: 37rem;
    overflow-y: auto;
    padding: 1rem;
  }

  .c-review-modal :deep(.c-standard-details-question .ns-recording-v2 > div div) {
    display: flex;
    flex-direction: column;
    align-content: center;
    text-align: center;
  }

  .c-review-modal :deep(.u-no-visual) {
    display: none;
  }

  .c-review-modal :deep(.student_response_file_size) {
    display: none;
  }

  .c-review-modal :deep(.sample_answer_toggle) {
    display: none;
  }

  .c-review-modal :deep(.hidden_helper) {
    display: none;
  }

  .c-review-modal :deep(.item_score) {
    display: none;
  }

  .c-review-modal :deep(.answer_choices li) {
    margin-bottom: 1rem;
    padding: 1rem;
    text-align: center;
    background-repeat: no-repeat;
    background-size: 3.25rem 1.25rem;
    background-position: left;
    border-radius: 0.3rem;
  }

  .c-review-modal :deep(.answer_choices li text) {
    padding: 2rem;
  }

  .c-review-modal :deep(.answer_choices) {
    list-style-type: none;
  }

  .c-review-modal :deep(div.answer_incorrect span) {
    visibility: hidden;
  }

  .c-review-modal :deep(div.answer_incorrect) {
    order: -1;
  }

  .c-review-modal :deep(div.answer_incorrect:after) {
    content: 'The student submitted a blank answer';
    text-align: center;
    font-style: italic;
    margin-right: -1rem;
    color: red;
    display: block;
    margin-bottom: 2rem;
  }

  .c-review-modal :deep(.review_question_wrapper) {
    display: flex;
    align-items: center;
    flex-direction: column;
  }

  .c-review-modal :deep(li.answer_incorrect) {
    background-color: var(--answer-incorrect-color);
    border-left: 0.2rem solid var(--answer-incorrect-border-color);
    background-image: var(--error-icon-path);
  };

  .c-review-modal :deep(.answer_correction) {
    border: 0.1rem solid var(--answer-correct-color);
  }

  .c-review-modal :deep(.answer_correct) {
    border: 0.1rem solid var(--answer-correct-color);
    border-left: 0.3rem solid var(--answer-correct-color);
    background-image: var(--success-icon-path);
  }

  .c-review-modal :deep(.answer_blank) {
    border: 1px solid var(--answer-blank-color);
  }
</style>
