<template>
  <div>
    <div class="standards-category">
      <ul class="standards-category__container">
      <li
        v-for="(standardCategoryValue, standardCategoryKey) in props.standardCategoryList"
        :key="standardCategoryKey"
        :class="[
          `standards-category__wrapper
          standards-category__${ standardCategoryKey }
          js-standard-${ standardCategoryKey }
          ${testClass('standard-category')}`,
          {'is-active' : activeState.active[standardCategoryKey]}]"
        @click="
          $emit('getStandardsRange', {
            'lower': getLowerRange(standardCategoryKey),
            'upper': getUpperRange(standardCategoryKey),
            'unit_id': props.unitId,
          }),
          setActiveStatus(standardCategoryKey)">
        <div class="standards-category__info">
          <label for="">{{ standardCategoryKey.replaceAll('_',' ') }}</label>
          <span v-if="standardCategoryKey !== 'total_standards_assessed'">
            {{ `${getLowerRange(standardCategoryKey)}-${getUpperRange(standardCategoryKey)}%` }}
          </span>
        </div>
        <span class="standards-category__badge">{{ standardCategoryValue }}</span>
      </li>
    </ul>
    </div>
  </div>
</template>
<script setup>
  import { testClass } from 'music';
  import { onMounted, reactive, watch } from 'vue';

  const props = defineProps({
    standardCategoryList: { required: true, type: Object },
    unitId: { required: true, type: Number },
  });

  const activeState = reactive({ active: {}});

  const standarCategoryRanges = {
    meeting: {
      lower: 90,
      upper: 100,
    },
    progressing: {
      lower: 80,
      upper: 89,
    },
    needs_some_support: {
      lower: 70,
      upper: 79,
    },
    needs_moderate_support: {
      lower: 60,
      upper: 69,
    },
    needs_high_support: {
      lower: 0,
      upper: 59,
    },
    total_standards_assessed: {
      lower: 0,
      upper: 100,
    },
  };

  const emit = defineEmits(['getStandardsRange']);

  watch(() => props.standardCategoryList, () => { setActiveStatus('total_standards_assessed') });

  onMounted(function() {
    setActiveStatus('total_standards_assessed');
  });

  /**
   * Reset the active state for category list.
   */
  function resetIsActiveState() {
    activeState.active = Object.keys(props.standardCategoryList).reduce((element, key) => {
      element[key] = false;
      return element;
    }, {});
  }

  /**
   * Return the lower range from standarCategoryRanges for the set category.
   * @param {string} category
   * @return {number}
   */
  function getLowerRange(category) {
    return standarCategoryRanges[category]?.lower;
  }

  /**
   * Return the upper range from standarCategoryRanges for the set category.
   * @param {string} category
   * @return {number}
   */
  function getUpperRange(category) {
    return standarCategoryRanges[category]?.upper;
  }


  /**
   * Set active status to clicked category.
   * @param {string} key
   */
  function setActiveStatus(key) {
    resetIsActiveState();
    activeState.active[key] = true;
  }
</script>
<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $meeting-color: #72B88E;
  $progressing-color: #B1C781;
  $needs-some-support-color: #F8D778;
  $needs-moderate-support-color: #E7AB77;
  $needs-high-support-color: #D88177;
  $is-active-background-color: #f5f8ff;

  @mixin badge-background-color($bgColor) {
    .standards-category__badge {
      background-color: rgba($bgColor, 0.5);
    }
  }

  .standards-category {
    border-radius: 0.5rem;
    box-shadow: rpx(2) rpx(3) rpx(7) 0 rgba($black, 0.3);
    overflow: hidden;
    width: 100%;
    margin-top: 2rem;


    &__container {
      list-style: none;
      padding: 0;
      margin: 0;

      * {
        cursor: pointer;
      }
    }

    &__wrapper {
      align-items: center;
      border-left-style: solid;
      border-left-width: rpx(6);
      border-top: solid  rpx(1) $gray-e;
      color: $gray-3;
      display: flex;
      justify-content: space-between;
      min-height: rpx(85);
      padding: 1rem;
    }

    &__wrapper:hover {
      background-color: $is-active-background-color;
    }

    &__wrapper:nth-of-type(1) {
      border-top: 0;
    }

    &__info {
      display: flex;
      flex-direction: column;
      font-size: $font-size-16;
      margin-right: 1rem;
      text-align: left;

      label {
        text-transform: capitalize;
        font-weight: bold;
      }

      span {
        color: $gray-6;
      }
    }

    &__badge {
      font-weight: bold;
      height: 2rem;
      width: 2rem;
      border-radius: mod(2);
      text-align: center;
      line-height: 2rem;
    }

    &__meeting {
      border-left-color: $meeting-color;
      @include badge-background-color($meeting-color);
    }

    &__progressing {
      border-left-color: $progressing-color;
      @include badge-background-color($progressing-color);
    }

    &__needs_some_support {
      border-left-color: $needs-some-support-color;
      @include badge-background-color($needs-some-support-color);
    }

    &__needs_moderate_support {
      border-left-color: $needs-moderate-support-color;
      @include badge-background-color($needs-moderate-support-color);
    }

    &__needs_high_support {
      border-left-color: $needs-high-support-color;
      @include badge-background-color($needs-high-support-color);
    }

    &__total_standards_assessed {
      border-left-color: $gray-c;
      @include badge-background-color($gray-c);
    }
  }

  .is-active {
    background-color: $is-active-background-color;
  }
</style>
