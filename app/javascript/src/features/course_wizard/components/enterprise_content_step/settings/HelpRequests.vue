<template>
  <div>
    <input
      id="allow_help_requests"
      v-model="courseDataStore.store.course.allowsHelpRequests"
      class="c-form-item__checkbox"
      type="checkbox">
    <label
      class="c-form-item__label  u-txt-16  u-txt-gray-3"
      for="allow_help_requests">
      Allow students to submit to you assignment help requests, before their final attempt.
    </label>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>
