<template>
  <div class="c-rubric-scores">
    <label
      :for="`criteria-${props.index}`"
      :title="props.criteria.title"
      class="c-rubric-scores__label">
      {{ props.criteria.title }}
    </label>
    <input
      :id="`criteria-${props.index}-${props.userId}`"
      :value="formatDecimal(score.criteria[props.criteria.title].earned)"
      :class="testClass(`criteria-input-${props.criteria.title}`)"
      class="c-rubric-scores__input  u-txt-rt  js-rubric-criteria-score  u-pad-rt-8"
      :name="`criteria[${score.attemptId}][${criteria.title}]`"
      min="0"
      :max="props.criteria.max_score"
      step="0.1"
      type="number"
      @change="updateScore"
      @focus="updateFocusedCriteriaIndex">
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { inject } from 'vue';

  const props = defineProps({
    criteria: { required: true, type: Object },
    index: { required: true, type: Number },
    userId: { required: true, type: Number },
  });

  const useStore = inject('useStore');
  const store = useStore();

  const score = store.earnedPoints.find((score) => score.userId === props.userId);
  /**
   * Updates the criteria that is selected in the store.
   */
  function updateFocusedCriteriaIndex() {
    store.focusedCriteriaIndex = props.index;
    store.focusedUserId = props.userId;
    document.body.style.marginBottom = '80px';
  }

  /**
   * Updates the criteria score.
   * @param {Object} - input change event object.
   */
  function updateScore(event) {
    score.criteria[props.criteria.title].earned = parseFloat(event.target.value) ? parseFloat(event.target.value) : null;
    store.updateTotalPoints();
  }

  /**
   * Formats the given score with on decimal point.
   * @param {Integer} scoreToFormat - earned score
   * @return {Float} scoreToFormat with one decimal point.
   */
  function formatDecimal(scoreToFormat) {
    return Number(scoreToFormat).toFixed(1);
  }
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-rubric-scores {
    display: flex;
    align-items: center;
    justify-content: space-between;
    grid-template-columns: 60% 35%;
    column-gap: 5%;
    margin-bottom: .25rem;
  }

  .c-rubric-scores__label {
    font-weight: normal;
    margin: 0;
    padding: 0;
    overflow: hidden;
    text-overflow: ellipsis;
    white-space: nowrap;
  }

  .c-rubric-scores__input {
    border: rpx(1) solid $grey-b;
  }

  // Do not show the arrows on number inputs
  input[type=number]::-webkit-inner-spin-button {
    -webkit-appearance: none;
  }

  input[type=number] {
   -moz-appearance: textfield;
   appearance: textfield;
   margin: 0;
   width: 20%;
   flex-shrink: 0;
   padding-right: 4px !important;
 }

</style>
