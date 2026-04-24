<template>
  <ContentSetting :class="testClass('score-reviews')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="allow-review-requests"
      v-model:checked="courseDataStore.store.course.allowsReviewRequests"
      name="allow-review-requests"
      testSelectorInput="allow-review-requests">
      Allow students to submit to you assignment score review requests, after their final attempt.
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
