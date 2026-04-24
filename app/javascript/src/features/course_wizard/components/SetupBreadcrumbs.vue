<template>
  <div
    class="breadcrumbs"
    :class="{
      'breadcrumbs--custom-setup': pathType === setupTypes.CUSTOM,
      'breadcrumbs--vol': isVol,
    }">
    <ul
      v-if="showSteps"
      class="steps"
      :class="testClass('steps')">
      <li
        v-for="(step, stepIndex) in stepsData"
        :key="stepIndex"
        class="step"
        :class="testClass('step')">
        <span
          class="title"
          :aria-current="currentStepId === step.stepId ? 'step' : null"
          :class="[
            {'title--is-current': currentStepId === step.stepId},
            testClass('breadcrumb-title')
          ]">
          {{ step.stepTitle }}
        </span>
        <span
          v-if="stepIndex < stepsData.length - 1"
          class="arrow"
          role="presentation">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            class="arrow-svg">
            <polygon
              fill-rule="evenodd"
              points="15.367 6 10 11.257 4.633 6 3 7.6 10 14.457 17 7.6"
              transform="rotate(-90 10 10)"
              class="arrow-polygon" />
          </svg>
        </span>
      </li>
    </ul>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import { testClass } from 'music';

  /**
   * @typeDef RouterDataType
   * @property {string} stepId
   * @property {string} stepTitle
   */

  const props = defineProps({
    currentStepId: {
      type: String,
      default: '',
    },
    isVol: {
      type: Boolean,
      default: false,
    },
    pathType: {
      type: String,
      default: '',
    },
  });

  const expressStepsData = [
    { stepId: 'path-selector-step', stepTitle: 'Setup' },
    { stepId: 'express-course-step', stepTitle: 'Details' },
    { stepId: 'learning-tracks-step', stepTitle: 'Assignments' },
  ];

  const baseCustomStepsData = [
    { stepId: 'advanced-course-step', stepTitle: 'Course' },
    { stepId: 'content-step', stepTitle: 'Content' },
    { stepId: 'gradebook-step', stepTitle: 'Gradebook' },
    { stepId: 'summary-step', stepTitle: 'Summary' },
  ];

  const pathStep = {
    stepId: 'path-selector-step',
    stepTitle: 'Setup',
  };

  const setupTypes = {
    EXPRESS: 'express',
    CUSTOM: 'custom',
  };

  /**
   * Get routes data for custom course flow.
   * Path selector Step would only appear when vista online learning is enabled.
   * @return {Array.<RouterDataType>}
   */
  function getCustomStepsData() {
    let customStepsData;
    if (props.isVol) {
      customStepsData = [pathStep].concat(baseCustomStepsData);
    } else {
      customStepsData = baseCustomStepsData;
    }
    return customStepsData;
  }

  /**
   * Get whether steps link/ texts are visible
   * @return {boolean}
   */
  const showSteps = computed(() => {
    return props.currentStepId !== 'path-selector-step' &&
      (props.pathType === setupTypes.EXPRESS || props.pathType === setupTypes.CUSTOM);
  });

  /**
   * Get routes data for progress bar.
   * @return {Array.<RouterDataType>}
   */
  const stepsData = computed(() => {
    return props.pathType == setupTypes.EXPRESS ?
      expressStepsData : getCustomStepsData();
  });
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .steps {
    list-style-type: none;
    padding: 0;
    vertical-align: top;
  }

  .step {
    align-items: flex-start;
    display: inline-flex;
    font-size: 1rem;
  }

  .title {
    color: $grey-9;
    display: inline-block;

    &--is-current {
      border-bottom: rpx(1) solid $black;
      color: $black;
    }
  }

  .arrow {
    display: inline-block;
    padding: 0 1rem;
  }

  .arrow-svg {
    width: 1.5rem;
  }

  .arrow-polygon {
    fill: $grey-9;
  }
</style>
