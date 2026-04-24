<template>
  <div class="settings-section">
    <h3
      v-if="title.length"
      class="settings-section-title">
      {{ title }}
    </h3>
    <div class="content">
      <slot />
    </div>
  </div>
</template>

<script setup>
  defineProps({
    title: {
      type: String,
      default: '',
    },
  });
</script>

<style lang="scss" scoped>
  .settings-section {
    margin: 0;
    padding: 0 1rem 2rem 1rem;
  }

  .settings-section-title {
    color: #000000;
    font-size: 28px;
    font-weight: 300;
    line-height: 34px;
    padding-top: 2rem;
    margin-bottom: 1rem;
  }
</style>
