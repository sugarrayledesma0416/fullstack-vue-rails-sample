<template>
  <ContentSetting :class="testClass('help-requests')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="allow-help-requests"
      v-model:checked="courseDataStore.store.course.allowsHelpRequests"
      name="allow-help-requests"
      testSelectorInput="allow-help-requests"
      testSelectorLabel="allow-help-requests-label">
      Allow students to submit to you assignment help requests, before their final attempt.
    </VhlCheckbox>
    <!-- eslint-enable vue/no-v-model-argument -->
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlCheckbox from '../../VhlCheckbox';

  const courseDataStore = inject('courseDataStore');
</script>
