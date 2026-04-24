<template>
  <fieldset class="fieldset">
    <legend class="legend" :class="{ 'u-screen-reader-only': hideLegend }">
      {{ legend }}
    </legend>
    <div class="content" :class="{ 'content--plain': hideLegend }">
      <slot />
    </div>
  </fieldset>
</template>

<script setup>
  defineProps({
    legend: {
      type: String,
      required: true,
    },
    hideLegend: {
      type: Boolean,
      default: false,
    },
  });
</script>

<style lang="scss" scoped>
  @import 'MusicAssets/stylesheets/music/library/v1/base/main';

  .fieldset {
    border: none;
    margin: 0;
    padding: 0;
  }

  .legend {
    color: $black;
    font-size: 1rem;
    font-weight: 400;
    margin-bottom: 0.5rem;
    text-transform: uppercase;
  }

  .content {
    background-color: $grey-f5;
    border-radius: rpx(4);
    max-width: 34rem;
    padding: 1rem 2rem;

    &--plain {
      background-color: transparent;
      max-width: unset;
      padding: 0;
    }
  }
</style>
