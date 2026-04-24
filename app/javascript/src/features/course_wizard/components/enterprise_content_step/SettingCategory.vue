<template>
  <div class="category">
    <CategoryTitle
      v-if="title.length"
      tagName="h2"
      class="title">
      {{ title }}
    </CategoryTitle>
    <div class="content">
      <slot />
    </div>
  </div>
</template>

<script setup>
  import CategoryTitle from '../CategoryTitle';

  defineProps({
    title: {
      type: String,
      default: '',
    },
  });
</script>

<style lang="scss" scoped>
  .category {
    margin: 0;
    padding: 0 1rem 2rem 1rem;
  }

  .title {
    margin-bottom: 1rem;
  }
</style>
