<template>
  <div>
    <div v-if="store.options.showOverallCommentPrompt">
      <span class="u-txt-bold">Prompt: </span>
      <a :href="overallComment.prompt.url">
        {{ overallComment.prompt.label }}
      </a>
    </div>
    <div>
      <span class="u-txt-bold">Comment:</span> {{ overallComment.overallComment }}
    </div>
    <div>
      <span class="u-txt-bold">Explanation:</span> {{ overallComment.explanation }}
    </div>
    <div v-if="overallComment.ratingCategory">
      <span class="u-txt-bold">Instructor Rating:</span> {{ overallComment.ratingCategory.label }}
    </div>
    <div v-if="overallComment.ratingComment">
      <span class="u-txt-bold">Instructor Comment:</span> {{ overallComment.ratingComment }}
    </div>
  </div>
</template>

<script setup>
  import useQuestionReportStore from '../models/question_report_store';

  const props = defineProps({
    /**
     * The overall comment model.
     */
    overallComment: {
      required: true,
      type: Object
    },
  });
  
  const store = useQuestionReportStore();
</script>
