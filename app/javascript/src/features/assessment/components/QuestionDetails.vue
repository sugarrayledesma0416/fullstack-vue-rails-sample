<template>
  <div>
    <p
      class="total-question-info"
      :class="testClass('total-question-info')">
      This assessment has {{ totalQuestions }} Questions:
    </p>
    <div
      class="detail-questions-info"
      :class="testClass('detail-questions-info')">
      <div
        v-for="(count, type) in parsedSummary"
        :key="type"
        :class="testClass('question-info-text')">
        {{ count }} {{ humanizeActivityType(type) }}
      </div>
    </div>
    <hr>
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  const props = defineProps({
    questionSummary: { default: '', type: String },
  });
  const parsedSummary = JSON.parse(props.questionSummary);
  const totalQuestions = Object.values(parsedSummary).reduce((acc, curr) => acc + curr, 0);

  /**
   * Converts a string representing an activity type to a human-readable format.
   *
   * This function removes postfixes '_v2' and '_same' from the input string and
   * then maps the cleaned string to a corresponding human-readable activity type.
   *
   * @param {string} str - The string representing the activity type.
   * @return {string} The human-readable format of the activity type.
   */
  function humanizeActivityType(str) {
    const oldType = str.toString().replace(/_same$|_v2$/i, '');

    switch (oldType) {
    case 'audio_hotspots':
      return 'Talking picture';
    case 'solo_video_recording':
      return 'Video Recording';
    case 'tutorial_vocab':
      return 'Tutorial vocabulary';
    case 'tutorial_vocab_html5':
      return 'Tutorial vocabulary';
    default:
      return humanize(oldType);
    }
  }

  /**
   * Capitalizes the first letter of a string and replaces underscores with spaces.
   *
   * @param {string} str - The input string to be humanized.
   * @return {string} The humanized string with the first letter capitalized
   * and underscores replaced by spaces.
   */
  function humanize(str) {
    const result = str.charAt(0).toUpperCase() + str.slice(1);
    return result.replace(/_/g, ' ');
  }

</script>

<style scoped>
.total-question-info {
  font-weight: bold;
}

.detail-questions-info {
  padding-left: 1rem;
}
</style>

