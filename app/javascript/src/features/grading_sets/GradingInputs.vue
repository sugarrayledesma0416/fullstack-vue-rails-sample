<template>
  <div
    class="js-grading-group"
    :class="[testClass(`user-inputs-${userId}`), { 'c-multi-user-question__user': isChatType}]">
    <slot name="studentname" :score="score" />
    <div
      v-if="score.isInstructor"
      class="cannot_grade_explanation">
      Instructors cannot be graded.
    </div>
    <div
      v-else-if="!score.isGradable"
      class="cannot_grade_explanation">
      You cannot grade this student because they are not in your section.
    </div>
    <div
      v-else-if="score.isPracticing"
      class="cannot_grade_explanation">
      This student completed the activity as 'practice', and therefore cannot be graded.
      <input type="hidden" :name="`practice_mode[${score.userId}]`" value="true">
    </div>
    <div
      v-if="isRubricGradable"
      class="l-container-fluid">
      <div class="l-grid">
        <div :class="`l-col-${displayRubricsInTwoColumns() ? 6 : 12}`">
          <RubricCriteriaInput
            v-for="(criteria, index) in rubricsForColumn(1)"
            :key="criteria.title"
            :criteria="criteria"
            :index="index"
            :userId="props.userId" />
        </div>
        <div
          v-if="displayRubricsInTwoColumns()"
          class="l-col-6">
          <RubricCriteriaInput
            v-for="(criteria, index) in rubricsForColumn(2)"
            :key="criteria.title"
            :criteria="criteria"
            :index="index + rubricPerColumn()"
            :userId="props.userId" />
        </div>
      </div>
    </div>
    <div
      v-show="isManuallyGradable"
      :class="gradingMethodClass">
      <div class="c-grading-scores__label">
        <label :for="`manual-grading-score-user-${score.userId}`" class="u-screen-reader-only" />
      </div>
      <input
        :id="`manual-grading-score-user-${score.userId}`"
        v-model="totalPointsRounded"
        :name="score.inputName"
        class="c-grading-scores__input--manual  u-txt-rt  js-score-field  u-pad-rt-8"
        :class="testClass('manual-input')"
        min="0"
        :max="pointsPossible"
        step="any"
        type="number">
      <span class="u-mar-lt-5">/{{ props.pointsPossible }}</span>
    </div>
    <QuickGradeControls
      v-if="isQuickGradable"
      :score="score">
      <span
        class="c-earned-vs-total-points"
        :class="testClass('earned-vs-total-points')">
        {{ totalPointsRounded }}/{{ props.pointsPossible }}
      </span>
    </QuickGradeControls>
    <div
      v-if="isCommentable"
      ref="commentElm" />
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { computed, inject, onMounted, ref } from 'vue';
  import RubricCriteriaInput from './RubricCriteriaInput';
  import QuickGradeControls from './QuickGradeControls';

  const props = defineProps({
    pointsPossible: { required: true, default: '', type: String },
    userId: { required: true, type: Number },
    isChatType: { required: true, type: Boolean },
  });
  const commentElm = ref(null);
  const useStore = inject('useStore');
  const store = useStore();

  const score = store.earnedPoints.find((item) => item.userId === props.userId);
  // TODO manual input name.

  const gradingMethodClass = computed(() => {
    return {
      'c-grading-scores--rubric': store.isRubricGraded,
      'c-grading-scores--manual': !store.isRubricGraded,
    };
  });

  const isRubricGradable = computed(() => {
    return store.isRubricGraded && score.isGradable && !score.isInstructor && !score.isPracticing;
  });

  const isManuallyGradable = computed(() => {
    return !store.isRubricGraded && score.isGradable && !score.isInstructor && !score.isPracticing;
  });

  const isQuickGradable = computed(() => {
    return score.isGradable && !score.isInstructor && !score.isPracticing;
  });

  const isCommentable = computed(() => {
    return score.isGradable && !score.isInstructor && !score.isPracticing;
  });

  const totalPointsRounded = computed(() => {
    return score.totalPoints ? parseFloat(score.totalPoints).toFixed(1) : '0.0';
  });

  /**
   * Return an array of rubrics to be displayed in a grid column.
   * @param {Integer} columnNumber - Column number on which the rubrics will be displayed.
   * @return {Array} Rubrics to be displayed.
   */
  function rubricsForColumn(columnNumber) {
    const numberOfRubrics = store.rubricCriterias.length;
    let rubricsArray = [];
    if (numberOfRubrics <= 6 && columnNumber == 1) {
      rubricsArray = store.rubricCriterias;
    } else if (numberOfRubrics > 6) {
      const rubricsPerColumn = rubricPerColumn();
      if (columnNumber == 1) {
        rubricsArray = store.rubricCriterias.slice(0, rubricsPerColumn);
      } else {
        rubricsArray = store.rubricCriterias.slice(rubricsPerColumn, numberOfRubrics);
      }
    }

    return rubricsArray;
  }

  /**
   * Returns number of rubrics per column.
   * @return {Integer} Rubric count per column.
   */
  function rubricPerColumn() {
    const numberOfRubrics = store.rubricCriterias.length;
    return Math.ceil( numberOfRubrics/2 );
  }

  /**
   * Checks if there are more than 6 rubrics.
   * @return {boolean} True if there are more than 6 rubrics, False otherwise.
   */
  function displayRubricsInTwoColumns() {
    return store.rubricCriterias.length > 6;
  }

  onMounted(() => {
    // Comment boxes are rendered via rails & js bootstrapped outside of this app.
    // Move them to within this component for layout purposes.
    if (score.commentBoxSelector) {
      const commentBox = document.querySelector(score.commentBoxSelector);
      commentElm.value.append(commentBox);
    }
  });
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-grading-scores--manual {
    display: grid;
    grid-template-columns: 60% 30% 5%;
  }

  .c-grading-scores--rubric {
    display: grid;
    grid-template-columns: 60% 35%;
    column-gap: 5%;
  }

  .c-grading-scores__input {
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
  }
</style>
