<template>
  <div class="category-weight-graph">
    <div class="graph-frame">
      <div
        v-show="isOverWeight"
        class="over-percent"
        :class="testClass('over-percent')">
        <div
          class="percentage  dynamic-overweight-style"
          :style="overweightStyle" />
      </div>
      <div class="full-percent">
        <div
          v-show="isUnderWeight"
          class="under-percent"
          :class="testClass('under-percent')">
          <div
            class="percentage  dynamic-underweight-style"
            :style="underweightStyle" />
        </div>
        <div
          class="allocated-percent"
          :class="testClass('allocated-percent')">
          <div
            class="percentage  dynamic-weight-style"
            :style="weightStyle" />
          <span
            v-show="isMaxWeight"
            class="full-height-text"
            :class="testClass('full-weight-msg')">
            Category weighting at 100%
          </span>
        </div>
      </div>
      <div
        v-show="isOverWeight"
        :class="testClass('overweight-alert-msg')">
        <div class="u-dis-flex  flex-align-start  u-mar-lt-10">
          <img
            :src="weightingAlertImage"
            alt="Alert"
            class="weighting-alert-mage">
          <div>
            <div>Category weighting </div>
            <div>{{ overWeight }}% Over</div>
          </div>
        </div>
      </div>
      <div
        v-show="isUnderWeight"
        :class="testClass('underweight-alert-msg')">
        <div class="u-dis-flex  flex-align-start  u-mar-lt-10">
          <img
            :src="weightingAlertImage"
            alt="Alert"
            class="weighting-alert-mage">
          <div>
            <div>Category weighting </div>
            <div>{{ underWeight }}% Under</div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { computed, inject } from 'vue';
  import { testClass } from 'music';
  import weightingAlertImage from 'images/category_wizard/weighting_alert.png';

  export default {
    name: 'CategoryWeightGraph',
    setup(props, { emit }) {
      const courseDataStore = inject('courseDataStore');

      const BAR_GRAPH_SCALE = 2;
      const FULL_WEIGHT = 100;

      /**
       * This returns combined weight for all the categories
       * @return {number}
       */
      const totalWeight = computed(() => {
        return courseDataStore.store.course.categories.reduce(function(memo, category) {
          return memo + (category.weightingPercent || 0);
        }, 0);
      });

      /**
       * This returns clamp weight for totalWeight
       * used for the graph to limit the graph height
       * @return {number}
       */
      const clampWeight = computed(() => {
        return Math.min(totalWeight.value, FULL_WEIGHT);
      });

      /**
       * This returns whether combined weight of all categories is less than full weight
       * @return {boolean}
       */
      const isUnderWeight = computed(() => {
        return totalWeight.value < FULL_WEIGHT;
      });

      /**
       * This returns whether combined weight of all categories is same as full weight
       * @return {boolean}
       */
      const isMaxWeight = computed(() => {
        return totalWeight.value === FULL_WEIGHT;
      });

      /**
       * This returns whether combined weight of all categories is greater than full weight
       * @return {boolean}
       */
      const isOverWeight = computed(() => {
        return totalWeight.value > FULL_WEIGHT;
      });

      /**
       * This returns over weight value
       * @return {number}
       */
      const overWeight = computed(() => {
        return totalWeight.value - FULL_WEIGHT;
      });

      /**
       * This returns under weight value
       * @return {number}
       */
      const underWeight = computed(() => {
        return FULL_WEIGHT - clampWeight.value;
      });

      /**
       * This returns style object with '--height-from-js' property
       * to set height of the overweight graph based on categories weight
       * This will be used to update value of css variable '--height-from-js'
       * @return {Object.<string, string>}
       */
      const overweightStyle = computed(() => {
        const height = Math.min(overWeight.value, 100) * BAR_GRAPH_SCALE;
        return {
          '--height-from-js': `${height}px`,
        };
      });

      /**
       * This returns style object with '--height-from-js' property
       * to set height of the underweight graph based on categories weight
       * This will be used to update value of css variable '--height-from-js'
       * @return {Object.<string, string>}
       */
      const underweightStyle = computed(() => {
        const height = underWeight.value * BAR_GRAPH_SCALE;
        return {
          '--height-from-js': `${height}px`,
        };
      });

      /**
       * This returns style object with '--height-from-js' property
       * to set height of the weight graph based on categories weight
       * This will be used to update value of css variable '--height-from-js'
       * @return {Object.<string, string>}
       */
      const weightStyle = computed(() => {
        const height = clampWeight.value * BAR_GRAPH_SCALE;
        return {
          '--height-from-js': `${height}px`,
        };
      });

      return {
        courseDataStore,
        isMaxWeight,
        isOverWeight,
        isUnderWeight,
        overWeight,
        overweightStyle,
        testClass,
        underWeight,
        underweightStyle,
        weightingAlertImage,
        weightStyle,
      };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .dynamic-overweight-style {
    height: var(--height-from-js);
  }
  .dynamic-underweight-style {
    height: var(--height-from-js);
  }
  .dynamic-weight-style {
    height: var(--height-from-js);
  }
  .category-weight-graph {
    font-size: rpx(12);
    width: mod(6);
  }
  .graph-frame {
    margin-top: rpx(27);
    position: relative;
  }
  .weighting-alert-mage {
    margin: 0 rpx(5) 0 0;
    vertical-align: middle;
  }
  .weighting-alert-mage.alert {
    margin: 0;
  }
  .over-percent {
    padding-left: rpx(10);
    width: rpx(30);
  }
  .full-percent {
    background: #fff url('/images/category_100perc.png') 50px 0 no-repeat;
    margin-bottom: rpx(5);
    padding-left: rpx(10);
    padding-right: rpx(20);
  }
  .over-percent .percentage,
  .under-percent .percentage {
    background-color: #FD9332;
    margin-bottom: rpx(3);
    width: rpx(30);
  }
  .allocated-percent .percentage {
    background-color: #1D3E6A;
    display: block;
    width: rpx(30);
  }
  .allocated-percent .full-height-text {
    font-size: rpx(10);
    line-height: rpx(13);
    padding-top: rpx(5);
    position: relative;
    text-align: center;
    width: rpx(53);
  }
</style>
