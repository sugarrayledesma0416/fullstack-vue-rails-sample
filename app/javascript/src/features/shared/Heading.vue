<template>
  <component
    :is="element"
    class="heading"
    :class="variantClasses">
    <slot />
  </component>
</template>

<script setup>
  import { computed } from 'vue';

  const props = defineProps({
    level: {
      default: '3',
      type: String,
      validator: (value) => ['1', '2', '3', '4', '5', '6'].includes(value),
    },
    variant: {
      default: '',
      type: String,
      validator: (value) => ['', 'page-title', 'category'].includes(value),
    },
  });

  const element = computed(() => `h${props.level}`);

  const variantClasses = computed(() => {
    return (props.variant.length) ? `heading--${props.variant}` : '';
  });

</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .heading {
    --heading-text-color: #{$lightest-text};
    --heading-font-size: var(--font-3, #{$font-size-16});

    font-size: var(--heading-font-size);
    font-weight: bold;
    color: var(--heading-text-color);
  }

  .heading--page-title {
    font-size: var(--font-7, rpx(30));
    font-weight: normal;
  }

  .heading--category {
    color: $category-color;
    font-size: var(--font-2, $font-size-14);
    text-transform: uppercase;
    letter-spacing: 0.035em;
  }
</style>
