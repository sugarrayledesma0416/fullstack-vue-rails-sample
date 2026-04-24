<template>
  <div>
    <sl-breadcrumb>
      <sl-breadcrumb-item
        class="breadcrumb-item"
        :class="testClass('breadcrumb-item')"
        @click="$emit('reset-from-breadcrumb')">
        <sl-tooltip
          :class="testClass('breadcrumb-standard-set-tooltip')"
          :content="store.selectedStandardSet?.value"
          placement="top">
          <span
            class="u-txt-16"
            :class="testClass('breadcrumb-standard-set-txt')">
            {{ shortStandardSetText }}
          </span>
        </sl-tooltip>
      </sl-breadcrumb-item>

      <sl-breadcrumb-item
        class="breadcrumb-subitem"
        :class="testClass('breadcrumb-subitem')">
        <span
          :class="testClass('breadcrumb-grade-level-txt')"
          class="subitem-label">{{ displayGradeLevels }}</span>
      </sl-breadcrumb-item>
    </sl-breadcrumb>
  </div>
</template>

<script setup>
  import { computed } from 'vue';
  import { testClass } from 'music';
  import useStandardsAssigningStore from './../models/use_standards_assigning_store.js';

  const props = defineProps({
    availableGradeLevels: { required: true, type: Array },
  });

  defineEmits(['reset-from-breadcrumb']);
  const store = useStandardsAssigningStore();

  const shortStandardSetText = computed(() => {
    return store.selectedStandardSet?.key;
  });

  const displayGradeLevels = computed(() => {
    const gradeLevels = props.availableGradeLevels;
    if (!gradeLevels || gradeLevels.length === 0) return '';

    const minGradeLevel = gradeLevels[0].grade;
    const maxGradeLevel = gradeLevels[gradeLevels.length - 1].grade;
    
    return minGradeLevel === maxGradeLevel
      ? gradeLevels[0].display_grade
      : `Grades ${minGradeLevel} - ${maxGradeLevel}`;
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .breadcrumb-item {
    margin-top: rpx(13);
    padding-left: rpx(50);
  }

  .breadcrumb-subitem {
    margin-top: rpx(13);
  }

  .subitem-label {
    cursor: default;
    font-size: rpx(16);
  }
</style>
