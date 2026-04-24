<template>
  <div
    class="stack"
    :class="variantClasses">
    <slot />
  </div>
</template>

<script setup>
  import { computed } from 'vue';

  const props = defineProps({
    spacing: {
      default: '',
      type: String,
      validator: (value) => ['', 'xxs', 'xs', 'sm', 'md', 'lg', 'xl'].includes(value),
    },
    align: {
      default: '',
      type: String,
      validator: (value) => 
        ['', 'start', 'center', 'end', 'space-between', 'space-around'].includes(value),
    },
  });

  const variantClasses = computed(() => {
    let classes = '';
    if (props.spacing.length) classes += `  stack--${props.spacing}`;
    if (props.align.length) classes += `  stack--${props.align}`;
    return classes;
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .stack {
    $default-space: $space-md;

    display: flex;
    flex-direction: column;
    gap: $default-space;
    align-items: flex-start;

    /* Modifiers for space between child elements: */
    &--flush { gap: 0; }
    &--xs { gap: $space-xs; }
    &--sm { gap: $space-sm; }
    &--md { gap: $space-md; }
    &--lg { gap: $space-lg; }
    &--xl { gap: $space-xl; }
    &--xxl { gap: $space-xxl; }
    &--xxxl { gap: $space-xxxl; }

    /* Alignment modifiers */
    &--start { align-items: flex-start; }
    &--center { align-items: center; }
    &--end { align-items: flex-end; }
    &--space-between { align-items: space-between; }
    &--space-around { align-items: space-around; }

    /*
      Child element: Splitter.
      Push all subsequent children down to the bottom
      (only works if there is leftover space in the stack):
    */
    > ::deep(.stack__splitter) { margin-bottom: auto; }
  }
</style>
