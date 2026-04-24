<template>
  <div>
    <p class="u-mar-bot-4">
      <b>Comment:</b> {{ props.overallComment.overallComment }}
    </p>
    <p class="u-mar-bot-4">
      <b>Explanation:</b> {{ props.overallComment.explanation }}
    </p>
    <Rating
      :rating="props.overallComment.rating"
      :accept="acceptOverallComment"
      :reject="rejectOverallComment"
     />
  </div>
</template>

<script setup>
  import Rating from './Rating';
  import useQuestionRatingStore from '../models/question_rating_store';

  const props = defineProps({
    /**
     * The overall comment model.
     */
    overallComment: {
      required: true,
      type: Object
    },
  });
  
  const store = useQuestionRatingStore();

  function acceptOverallComment(rating) {
    store.acceptOverallComment(props.overallComment, rating);
  }
  
  function rejectOverallComment(rating, comment) {
    store.rejectOverallComment(props.overallComment, rating, comment);
  }
</script>
