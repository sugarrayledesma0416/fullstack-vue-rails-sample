<template>
  <div>
    <p class="u-mar-bot-4">
      <b>Incorrect text:</b> {{ props.gradingSuggestion.incorrectText }}
    </p>
    <p>
      <b>Comment:</b> {{ props.gradingSuggestion.errorExplanation }}
    </p>
    <p>
      <Rating
        :rating="props.gradingSuggestion.rating"
        :accept="acceptSuggestion"
        :reject="rejectSuggestion"
       />
    </p>
  </div>
</template>

<script setup>
  import Rating from './Rating';
  import useQuestionRatingStore from '../models/question_rating_store';

  const props = defineProps({
    /**
     * The grading suggestion model.
     */
    gradingSuggestion: {
      required: true,
      type: Object
    },
  });
  
  const store = useQuestionRatingStore();

  function acceptSuggestion(rating) {
    store.acceptSuggestion(props.gradingSuggestion, rating);
  }
  
  function rejectSuggestion(rating, comment) {
    store.rejectSuggestion(props.gradingSuggestion, rating, comment);
  }
</script>
