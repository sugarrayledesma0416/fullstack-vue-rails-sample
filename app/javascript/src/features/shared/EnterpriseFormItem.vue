<template>
  <div>
    <div>
      <label
        class="u-mar-bot-8  u-txt-body-1"
        :class="{ 'u-screen-reader-only': hideLabel }"
        :for="inputId">
        {{ label }}
      </label>
    </div>

    <slot />
  </div>
</template>

<script setup>
  const props = defineProps({
    inputId: { required: true, type: String },
    label: { required: true, type: String },
    hint: { default: '', type: String },
    hideLabel: { default: false, type: Boolean },
    type: {
      default: 'text',
      type: String,
      validator: (value) => ['', 'checkbox', 'radio', 'select', 'text', 'textarea'].includes(value),
    },
  });
</script>

<style lang="scss" scoped="module">
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  @import '~MusicAssets/stylesheets/music/library/v1/parts/utilities';

  /*
    Vertical orientation by default (input with label above),
    horizontal for radio buttons and checkboxes (label to right of input).
  */
  .form-item {
    display: block;

    &--checkbox,
    &--radio {
      display: flex;
      gap: 0.25rem;
    }
  }

  .form-item__label {
    color: $gray-6;
    display: block;
    font-size: var(--font-2, #{$font-size-14});
    text-transform: uppercase;
    letter-spacing: 0.035em;

    &--radio {
      color: $gray-3;
      letter-spacing: 0;
      text-transform: none;
      display: inline;
    }
  }

  .form-item__hint {
    font-size: var(--font-2, $font-size-14);
    color: $lightest-text;
    line-height: 1;
  }
</style>
