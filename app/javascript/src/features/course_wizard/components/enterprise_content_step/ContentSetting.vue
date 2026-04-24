<template>
  <div>
    <div
      v-if="title.length > 0"
      class="title"
      :class="testClass('title')">
      {{ title }}
    </div>
    <div class="content">
      <slot />
    </div>
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  defineProps({
    title: {
      type: String,
      default: '',
    },
  });
</script>

<style lang="scss" scoped>
  @use 'MusicAssets/stylesheets/music/library/v1/base/main' as music;

  .title {
    color: music.$grey-9;
    display: block;
    font-size: 1rem;
    font-weight: lighter;
    letter-spacing: 0.05rem;
    margin-bottom: 0.25rem;
    text-transform: uppercase;
  }
</style>
