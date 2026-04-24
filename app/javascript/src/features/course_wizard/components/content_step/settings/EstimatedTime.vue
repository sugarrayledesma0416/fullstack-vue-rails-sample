<template>
  <ContentSetting
    title="Estimated Time"
    :class="testClass('estimated-time')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="estimated_times"
      v-model:checked="courseDataStore.store.course.showEstimatedTimes"
      testSelectorInput="estimated-times"
      testSelectorLabel="estimated-times-label">
      Allow students to see the estimated time necessary to complete assignments.
    </VhlCheckbox>
    <!-- eslint-enable vue/no-v-model-argument -->
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import VhlCheckbox from '../../VhlCheckbox';
  import ContentSetting from '../ContentSetting';

  const courseDataStore = inject('courseDataStore');
</script>
