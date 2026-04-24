<template>
  <div
    class="tooltip"
    :class="[
      `mode--${mode}`,
      getCategoryCls(props.categoryName)
    ]"
    :style="styleObject">
    <div class="tooltip-arrow" />
    <div class="tooltip-content">
      <div class="tooltip-header">
        <span
          class="header-text"
          :class="testClass('header-text')">
          {{ title }}
        </span>
      </div>
      <div
        class="tooltip-body"
        :class="testClass('tooltip-body')">
        <span
          v-if="mode === 'show-activity-info'"
          class="assessment-counts-icon"
          :class="testClass('assessment-counts-icon')">
          <vhl-assessment-count-icon-white
            class="u-dis-inline-flex"
            size="sm" />
        </span>
        {{ description }}
      </div>
    </div>
  </div>
</template>

<script setup>
  import { ref, watchEffect } from 'vue';
  import { testClass } from 'music';

  const props = defineProps({
    categoryName: { default: '', type: String },
    description: { default: '', type: String },
    mode: {
      required: true,
      type: String,
      validator: (value) => [
        'show-activity-info',
        'show-standard',
        'show-standard-desc',
        'standard',
      ].includes(value),
    },
    position: { default: () => {}, type: Object },
    title: { default: '', type: String },
  });

  const styleObject = ref({});

  watchEffect(() => {
    if (props.position) {
      styleObject.value = {
        left: `${props.position.left}px`,
        top: `${props.position.top - props.position.topOffset}px`,
      };
    }
  });

  /**
   * Get catagory specific css class for each data row
   * @param {string} categoryName
   * @return {string}
   */
  function getCategoryCls() {
    const categoryCls = {
      'Quizzes': 'category--quizzes',
      'Unit Test': 'category--unit_test',
      'Speaking and Writing Tests': 'category--speaking_and_writing_tests',
    };
    return categoryCls[props.categoryName] ?? '';
  }
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .tooltip {
    background-color: $gray-3;
    border-radius: rpx(5);
    color: white;
    display: flex;
    flex-direction: column;
    padding: rpx(10);
    position: absolute;
    text-align: center;
    transform: translateX(-50%) translateY(-100%);
    width: rpx(300);
    z-index: 1000;
  }

  .tooltip-header {
    font-size: rpx(16);
    font-weight: bold;
  }

  .tooltip-body {
    font-size: rpx(14);
  }

  .tooltip.mode--show-activity-info {
    .tooltip-content {
      align-items: center;
      display: inline-flex;
      flex-direction: column;
    }
    .tooltip-header {
      font-weight: normal;
    }
    .tooltip-header .header-text {
      padding-left: rpx(8);
      padding-right: rpx(8);
    }
    &.category--quizzes .tooltip-header .header-text {
      border-left: rpx(2) solid #EF2121;
    }
    &.category--unit_test .tooltip-header .header-text {
      border-left: rpx(2) solid #5570FE;
    }
    &.category--speaking_and_writing_tests .tooltip-header .header-text {
      border-left: rpx(2) solid #FEE355;
    }

    .tooltip-body {
      margin-top: rpx(4);
    }
  }

  .tooltip.mode--show-standard-desc {
    .tooltip-header {
      display: none;
    }
  }

  .tooltip-arrow {
    border-left: rpx(8) solid transparent;
    border-right: rpx(8) solid transparent;
    border-top: rpx(8) solid $gray-3;
    height: 0;
    left: 50%;
    position: absolute;
    top: 100%;
    transform: translateX(-50%);
    width: 0;
  }
</style>
