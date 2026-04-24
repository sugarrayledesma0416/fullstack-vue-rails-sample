<template>
  <div>
    <input
      id="allow_review_requests"
      v-model="courseDataStore.store.course.allowsReviewRequests"
      class="c-form-item__checkbox"
      type="checkbox">
    <label
      class="c-form-item__label  u-txt-16  u-txt-gray-3"
      for="allow_review_requests">
      Allow students to submit to you assignment score review requests, after their final attempt.
    </label>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>
