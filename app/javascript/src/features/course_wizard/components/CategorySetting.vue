<template>
  <div class="category-setting">
    <h4 class="title" :class="testClass('title')">
      {{ title }}:
    </h4>
    <div class="info">
      <slot />
    </div>
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  defineProps({
    title: {
      type: String,
      required: true,
    },
  });
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .title {
    color: $grey-9;
    font-size: 1rem;
    margin-bottom: 0.5rem;
    text-transform: uppercase;
  }
</style>
