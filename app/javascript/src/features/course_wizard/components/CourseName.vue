<template>
  <h2 class="course-name">
    {{ courseDataStore.store.course.name }}
  </h2>
</template>

<script setup>
  import { inject } from 'vue';

  const courseDataStore = inject('courseDataStore');
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .course-name {
    color: var(--ui-text-color, $grey-3);
    font-size: var(--font-7, 1.875rem);
    font-weight: normal;
  }
</style>
