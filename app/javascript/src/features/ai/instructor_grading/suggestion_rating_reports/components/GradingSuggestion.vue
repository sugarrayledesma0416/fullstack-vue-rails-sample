<template>
  <div class="u-mar-bot-4">
    <div v-if="store.options.showGradingSuggestionPrompt">
      <span class="u-txt-bold">Prompt: </span>
      <a :href="gradingSuggestion.prompt.url">
        {{ gradingSuggestion.prompt.label }}
      </a>
    </div>
    <div>
      <span class="u-txt-bold">Incorrect text:</span> {{ gradingSuggestion.incorrectText }}
    </div>
    <div>
      <span class="u-txt-bold">Comment:</span> {{ gradingSuggestion.errorExplanation }}
    </div>
    <div v-if="gradingSuggestion.ratingCategory">
      <span class="u-txt-bold">Instructor Rating:</span> {{ gradingSuggestion.ratingCategory.label }}
    </div>
    <div v-if="gradingSuggestion.ratingComment">
      <span class="u-txt-bold">Instructor Comment:</span> {{ gradingSuggestion.ratingComment }}
    </div>
  </div>
</template>

<script setup>
  import useQuestionReportStore from '../models/question_report_store';

  const props = defineProps({
    /**
     * The grading suggestion model.
     */
    gradingSuggestion: {
      required: true,
      type: Object
    },
  });
  
  const store = useQuestionReportStore();
</script>
