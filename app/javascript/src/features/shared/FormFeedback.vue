<template>
  <div
    class="form-item-feedback"
    :class="[
      `form-item-feedback--${type}`,
      testClass(`form-item-${type}`)]">
    <slot />
  </div>
</template>

<script setup>
  import { testClass } from 'music';

  const props = defineProps({
    type: {
      default: '',
      type: String,
      validator: (value) =>
        ['', 'error', 'success'].includes(value),
    },
  });
</script>

<style lang="scss" scoped>
   @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .form-item-feedback {
    margin-top: $space-sm;

    &--error { color: var(--ui-error-color, $error); }
    &--success { color: var(--ui-success-color, $success); }
  }
</style>
