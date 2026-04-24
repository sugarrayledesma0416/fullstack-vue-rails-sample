<template>
  <div>
    <input
      id="share_to_google_classroom"
      v-model="courseDataStore.store.course.shareToGoogleClassroom"
      class="c-form-item__checkbox"
      type="checkbox">
    <label
      class="c-form-item__label  u-txt-16  u-txt-gray-3"
      for="share_to_google_classroom">
      Enable the Google Share button for individual content items for use with
      Google Classroom.  Disabling this option will not remove any previously
      created Google Share links.
    </label>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>
