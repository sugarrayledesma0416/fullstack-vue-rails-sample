
<template>
  <div
    class="progress-bar"
    :class="{
      'progress-bar--custom-setup': pathType === setupTypes.CUSTOM,
      'progress-bar--vol': isVol,
    }">
    <div class="progress-bar__title" :class="testClass('progress-bar-title')">
      <span class="txt-bold">add</span>course
    </div>
    <ul
      v-if="showSteps"
      class="progress-bar__progress-steps"
      :class="testClass('progress-bar-steps')">
      <li
        v-for="(step, stepIndex) in stepsData"
        :key="stepIndex"
        class="progress-step-list-item"
        :class="[
          { 'is-current': currentStepId === step.stepId},
          testClass('progress-step-list-item')
        ]">
        <span
          class="progress-step-name"
          :class="testClass('progress-step-name')">
          {{ step.stepTitle }}
        </span>
      </li>
    </ul>
  </div>
</template>

<script>
  import { computed } from 'vue';
  import { testClass } from 'music';

  /**
   * @typeDef RouterDataType
   * @property {string} stepId
   * @property {string} stepTitle
   */

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

  export default {
    name: 'ProgressBar',
    props: {
      currentStepId: { default: '', type: String },
      isVol: { default: false, type: Boolean },
      pathType: { default: '', type: String },
    },
    setup(props) {
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

      return { setupTypes, showSteps, stepsData, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .progress-bar {
    position: absolute;
    right: rpx(40);
    top: rpx(-39);
    z-index: z(bump);

    .progress-bar__title {
      display: inline-block;
      font-size: rpx(22);
      vertical-align: bottom;
    }

    .progress-step-list-item {
      background: url('/images/course-setup-step.png') no-repeat 0 22px;
      display: inline-block;
      height: rpx(30);
      text-align: center;
      width: rpx(95);

      &.is-current {
        background-position: rpx(-155) rpx(22);
      }

      &.is-current:last-child {
        background-position: rpx(-281) rpx(22);
      }
    }

    .progress-bar__progress-steps {
      display: inline-block;
      margin-left: rpx(20);
      vertical-align: top;
    }
  }

  .progress-bar.progress-bar--custom-setup {
    .progress-step-list-item {
      width: rpx(75);

      &.is-current {
        background-position: rpx(-175) rpx(22);
      }

      &.is-current:last-child {
        background-position: rpx(-300) rpx(22);
      }
    }
  }

  .progress-bar.progress-bar--vol {
    .progress-bar__title {
      color: #FFF;
    }

    .progress-step-list-item {
      color:#8C8C8C;

      &.is-current {
        color:#FFF;
      }
    }
  }

  .txt-bold {
    font-weight: 700;
  }
</style>
