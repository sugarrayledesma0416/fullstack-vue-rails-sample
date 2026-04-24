<template>
  <div>
    <input
      id="estimated_times"
      v-model="courseDataStore.store.course.showEstimatedTimes"
      class="c-form-item__checkbox"
      type="checkbox">
    <label
      class="c-form-item__label  u-txt-16  u-txt-gray-3"
      for="estimated_times">
      Allow students to see the estimated time necessary to complete assignments.
    </label>
  </div>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>
