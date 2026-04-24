<template>
  <component :is="tagName" class="title">
    <slot />
  </component>
</template>

<script setup>
  defineProps({
    tagName: {
      type: String,
      required: true,
    },
  });
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .title {
    color: $dark-blue;
    font-size: 1rem;
    font-weight: bold;
    line-height: 1;
    text-transform: uppercase;
  }
</style>
