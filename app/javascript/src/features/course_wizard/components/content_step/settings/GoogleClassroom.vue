<template>
  <ContentSetting :class="testClass('google-classroom')">
    <!-- eslint-disable vue/no-v-model-argument -->
    <VhlCheckbox
      id="share-to-google-classroom"
      v-model:checked="courseDataStore.store.course.shareToGoogleClassroom"
      name="share-to-google-classroom"
      testSelectorInput="google-classroom-input"
      testSelectorLabel="google-classroom-input-label">
      Enable the Google Share button for individual content items for use with
      Google Classroom.  Disabling this option will not remove any previously
      created Google Share links.
    </VhlCheckbox>
    <!-- eslint-enable vue/no-v-model-argument -->
  </ContentSetting>
</template>

<script setup>
  import { inject } from 'vue';
  import { testClass } from 'music';
  import ContentSetting from '../ContentSetting';
  import VhlCheckbox from 'features/course_wizard/components/VhlCheckbox';

  const courseDataStore = inject('courseDataStore');
</script>
