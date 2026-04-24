<template>
  <fieldset class="fieldset">
    <legend
      v-if="legend.length"
      class="fieldset__legend"
      :class="legendClasses">
      {{ legend }}
    </legend>
    <VStack :spacing="spacing">
      <slot />
    </VStack>
  </fieldset>
</template>

<script setup>
  import VStack from 'features/shared/VStack';

  const props = defineProps({
    legend: { default: '', type: String },
    spacing: { default: '', type: String },
    legendClasses: { default: '', type: String },
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .fieldset {
    /* Normalize: */
    padding: 0;
    border: 0;
  }

  .fieldset__legend {
    color: $gray-6;
    font-size: var(--font-2, $font-size-14);
    letter-spacing: 0.06em;
    margin: 0 0 mod(1);
    padding: 0;
    text-transform: uppercase;
  }
</style>
