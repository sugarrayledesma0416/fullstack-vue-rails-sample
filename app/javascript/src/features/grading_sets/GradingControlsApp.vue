<template>
  <div class="ns-music-v1">
    <div
      class="c-grading-method-controls
             u-dis-flex
             flex-align-baseline
             flex-justify-between
             u-mar-bot-10">
      <div>
        <label class="u-txt-bold  u-mar-rt-6" for="grading-method-toggle">
          Grading Method
        </label>
        <select
          id="grading-method-toggle"
          class="c-select  u-txt-upper"
          :class="testClass('change-grading-method')"
          :value="selectedGradingMethodName"
          @change="changeGradingMethod($event)">
          <option
            value="rubric">
            rubric
          </option>
          <option
            value="manual">
            manual
          </option>
        </select>
      </div>
      <!-- eslint-disable vue/no-v-html -->
      <div
        v-if="store.isRubricGraded"
        class="c-view-rubric  js-rubric-view"
        v-html="viewRubricLink" />
      <!-- eslint-enable vue/no-v-html -->
    </div>
    <div :class="{ 'c-multi-user-question': isChatType }">
      <GradingInputs
        v-for="score in store.earnedPoints"
        :key="score.userId"
        :pointsPossible="pointsPossible"
        :userId="score.userId"
        :isChatType="isChatType">
        <template #studentname>
          <div class="u-mar-bot-6">
            <span class="u-txt-bold  student_name">{{ score.studentName }}</span>
            <span class="u-txt-bold  student_number"> {{ score.userId }}</span>
          </div>
        </template>
      </GradingInputs>
    </div>
    <ClearScoresModal
      v-if="showClearScoresModal"
      @close-clear-scores-modal="closeClearScoresModal"
      @toggle-grading-method="toggleGradingMethod" />
    <input v-model="store.isRubricGraded" type="hidden" name="rubric_graded">
    <input :value="gradePending" type="hidden" name="grade_pending">
    <RubricToolbar />
  </div>
</template>

<script setup>
  /* This app is loaded only when the activity has an associated rubric.
   * See elements with class 'js-grading-controls-app' in grading partials
   * for details.
   */
  import { testClass } from 'music';
  import ClearScoresModal from './ClearScoresModal';
  import GradingInputs from './GradingInputs';
  import RubricToolbar from './RubricToolbar';
  import useGradingSetStore from 'features/grading_sets/models/use_grading_set_store.js';

  import { onMounted, provide, ref, computed } from 'vue';

  const props = defineProps({
    rubricColumnHeaders: { required: true, default: '', type: String },
    rubricCriterias: { required: true, default: '', type: String },
    viewRubricLink: { required: true, default: '', type: String },
    rubricGraded: {
      required: true,
      type: String,
      validator(value) {
        return ['true', 'false'].includes(value);
      },
    },
    gradePending: { required: true, default: '', type: String },
    pointsPossible: { required: true, default: '', type: String },
    userScores: { required: true, default: '', type: String },
    chatType: { require: false, default: 'false', type: String },
  });

  /*
   * Grading method initialization: Rubric vs Manual Grading:
   *   Previously graded activities:
   *     Grading UI defaults to the grading method used to record the score.
   *    Ungraded activities:
   *      When the user interacts with the Grading Method selector,
   *      sessionStorage's gradingMethod key is assigned 'rubric' or 'manual',
   *      persisting across students in the grading set.
   *      Use the sessionStorage value, if set. Otherwise, default to 'rubric'.
   */

  let isInitRubricGraded;
  if (props.gradePending === 'true') {
    // activity is not yet graded. Init as rubric unless 'manual' is set in session storage.
    isInitRubricGraded = sessionStorage.getItem('gradingMethod') === 'manual' ? false : true;
  } else {
    // activity is already graded. Init with grading method used to record score.
    isInitRubricGraded = props.rubricGraded === 'true';
  }

  const gradingSetStoreConfig = {
    rubricColumnHeaders: JSON.parse(props.rubricColumnHeaders),
    rubricCriterias: JSON.parse(props.rubricCriterias),
    isInitRubricGraded,
    scores: JSON.parse(props.userScores),
    pointsPossible: parseFloat(props.pointsPossible),
  };

  const useStore = useGradingSetStore(gradingSetStoreConfig);
  const store = useStore();

  provide('useStore', useStore);

  const isChatType = props.chatType === 'true';

  const viewRubricLink = JSON.parse(props.viewRubricLink);
  const showClearScoresModal = ref(false);
  const suppressClearScoresModal = ref(null);

  /**
   * Displays Clear Scores warning modal if applicable.
   */
  function changeGradingMethod() {
    if (!suppressClearScoresModal.value) {
      showClearScoresModal.value = true;
    } else {
      toggleGradingMethod();
    }
  }

  /**
   * @param { Boolean } isSuppressModalChecked - whether or not the
   *   "don't show me this again" box is checked on the clearScores modal.
   * Hides the Clear Scores Modal.
   * Updates the flags that indicate whether or not the modal will
   * show next time the grading method is changed.
   */
  function closeClearScoresModal(isSuppressModalChecked) {
    showClearScoresModal.value = false;
    suppressClearScoresModal.value = isSuppressModalChecked;
    sessionStorage.setItem('showGradingMethodModal', !isSuppressModalChecked);
  }

  /**
   * Clear earnedPoints in the store.
   * Toggle the grading controls between rubric/manual.
   */
  function toggleGradingMethod() {
    store.$patch((state) => {
      state.earnedPoints.forEach((item) => {
        item.criteria = store.makeCriteriaScoresTemplate();
        item.totalPoints = undefined;
      });
    });
    store.isRubricGraded = !store.isRubricGraded;
    store.focusedCriteriaIndex = store.isRubricGraded == false ? null : store.focusedCriteriaIndex;
    sessionStorage.setItem('gradingMethod', store.isRubricGraded ? 'rubric' : 'manual');
  }

  const selectedGradingMethodName = computed(() => {
    return store.isRubricGraded ? 'rubric' : 'manual';
  });

  onMounted(() => {
    /**
     * Check session storage to see if the
     * Clear Scores warning modal should show when
     * changing grading method & set suppressClearScoresModal accordingly.
     */
    const sessionShowModal = sessionStorage.getItem('showGradingMethodModal');
    if (sessionShowModal === null) {
      sessionStorage.setItem(
        'showGradingMethodModal',
        'true'
      );
    }
    if (sessionShowModal === 'false') {
      suppressClearScoresModal.value = true;
    } else {
      suppressClearScoresModal.value = false;
    }
  });
</script>
<style scoped>
  .c-multi-user-question {
    position: relative;
  }
</style>
