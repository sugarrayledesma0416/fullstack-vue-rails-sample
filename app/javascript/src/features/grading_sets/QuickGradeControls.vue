<template>
  <div class="ns-music-v1">
    <div
      class="c-rubric-scores__quick_points"
      :class="{ 'manual-grading': !store.isRubricGraded }">
      <span class="u-txt-bold  u-pad-rt-24">
        Total
      </span>
      <button
        class="u-pad-0  u-bg-white  quick-grade-button  rubric-no-points"
        :class="testClass('quick-grade-no-points')"
        :disabled="score.isNoPointsDisabled"
        @click="setNoPoints">
        0%
      </button> |
      <button
        class="u-pad-0  u-bg-white  quick-grade-button  rubric-full-points"
        :class="testClass('quick-grade-full-points')"
        :disabled="score.isFullPointsDisabled"
        @click="setFullPoints">
        100%
      </button>
      <slot v-if="store.isRubricGraded" />
    </div>
  </div>
</template>

<script setup>
  import { testClass } from 'music';
  import { inject } from 'vue';

  const props = defineProps({
    score: { required: true, type: Object },
  });

  const useStore = inject('useStore');
  const store = useStore();

  /**
   * Sets points earned to the value of points possible.
   */
  function setFullPoints() {
    store.setFullPoints(props.score);
    store.updateTotalPoints();
    // eslint-disable-next-line vue/no-mutating-props
    props.score.isFullPointsDisabled = true;
    // eslint-disable-next-line vue/no-mutating-props
    props.score.isNoPointsDisabled = false;
  }

  /**
   * Sets points earned to 0.
   */
  function setNoPoints() {
    store.setNoPoints(props.score);
    store.updateTotalPoints();
    // eslint-disable-next-line vue/no-mutating-props
    props.score.isFullPointsDisabled = false;
    // eslint-disable-next-line vue/no-mutating-props
    props.score.isNoPointsDisabled = true;
  }
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .c-rubric-scores__quick_points.manual-grading {
    margin-top: rpx(-23);
  }

  .quick-grade-button {
    border: none;
    /*input has OS specific font-family*/
    color: #069;
    text-decoration: underline;
    cursor: pointer;
  }

  .quick-grade-button:disabled {
    color: currentColor;
    cursor: not-allowed;
    opacity: 0.5;
    text-decoration: none;
  }
</style>
