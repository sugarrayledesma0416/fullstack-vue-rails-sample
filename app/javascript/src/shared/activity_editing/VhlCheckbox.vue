<template>
  <span class="checkbox-container" :class="localstore.featureVariantClass">
    <input
      :id="id"
      :name="name"
      class="checkbox-input"
      :class="testClass(testSelectorInput)"
      type="checkbox"
      :disabled="disabled"
      :checked="checked"
      :title="title"
      @input="$emit('update:checked', $event.target.checked)">
    <label class="checkbox-label" :class="testClass(testSelectorLabel)" :for="id">
      <slot />
    </label>
  </span>
</template>

<script>
  import { isEmpty } from '../utils';
  import { testClass } from 'music';

  const SUPPORTED_FEATURE_VARIANTS = [
    'created-activity-multiple-answer',
    'learning-track-due-dates',
  ];

  export default {
    name: 'VhlCheckbox',
    props: {
      checked: { default: false, type: Boolean },
      disabled: { default: false, type: Boolean },
      featureVariant: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_FEATURE_VARIANTS.includes(value),
      },
      id: { default: '', type: String },
      name: { default: '', type: String },
      title: { default: '', type: String },
      testSelectorInput: { default: '', type: String },
      testSelectorLabel: { default: '', type: String },
    },
    emits: ['update:checked'],
    setup(props) {
      /**
       * creates a class based on the variant passed.
       * @param {string} variant - variant name passed. It can be variant or
       * feature variant.
       * @return {string} variant class.
       */
      function variantClass(variant) {
        return isEmpty(variant) ? '' : `checkbox-container--${variant}`;
      }

      const localstore = {
        featureVariantClass: variantClass(props.featureVariant),
      };

      return { localstore, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .checkbox-container {
    --border-width-sm: 0.0625rem;
    --checkbox-margin: 0.125rem;
    --checkbox-size: 1.125rem;
    --font-size-sm:  0.875rem;

    .checkbox-input {
      border: 0;
      clip: rect(0 0 0 0);
      height: 0.0625rem;
      margin: -0.0625rem;
      overflow: hidden;
      padding: 0;
      position: absolute;
      width: 0.0625rem;
    }

    .checkbox-input,
    .checkbox-label {
      display: inline-block;
      font-weight: normal;
      line-height: var(--checkbox-size);
      vertical-align: middle;
    }

    .checkbox-label {
      font-size: var(--font-size-sm);
      min-height: 0.0625rem;
      min-width: 0.0625rem;
      outline: 0.125rem solid transparent;
      outline-offset: 0.125rem;
      padding: 0 0 0 1.5rem;
      position: relative;

      &::before {
        background: $white;
        border: var(--border-width-sm) solid $gray-c;
        content: '';
        display: inline-block;
        height: var(--checkbox-size);
        left: 0;
        margin-right: var(--checkbox-margin);
        position: absolute;
        top: 0;
        vertical-align: middle;
        width: var(--checkbox-size);
      }

      &::after {
        background-size: 100% 100%;
        content: ' ';
        height: calc(var(--checkbox-size) - 0.0625rem);
        display: block;
        left: rpx(1);
        opacity: 0.7;
        position: absolute;
        top: 0.125rem;
        width: calc(var(--checkbox-size) - 0.0625rem);
      }
    }

    .checkbox-input:checked + .checkbox-label::after {
      background-image: url('/images/custom_assessment/checkmark-black.svg');
    }

    .checkbox-input:disabled + .checkbox-label {
      opacity: 0.35;
    }

    .checkbox-input:focus + .checkbox-label::before {
      outline: 0.125rem solid #0091eb;
      outline-offset: 0.125rem;
    }

    .checkbox-input-container--learning-track-due-dates {
      .checkbox-label  {
        color: $gray-6;
        font-size: 0.75rem;
      }
    }

    &.checkbox-container--created-activity-multiple-answer {
      --checkbox-size: 1.5rem;

      .checkbox-label::before {
        border: 0.0625rem solid $lightest-graphic;
        height: var(--checkbox-size);
        width: var(--checkbox-size);
      }

      .checkbox-label::after {
        height: var(--checkbox-size);
        opacity: 1;
        width: var(--checkbox-size);
      }

      .checkbox-input:focus + .checkbox-label::before,
      .checkbox-input:hover + .checkbox-label::before {
        border-color: $gray-3;
      }

      .checkbox-input:checked + .checkbox-label::after {
        background-image: url('/images/custom_assessment/checkmark-created-activities.svg');
      }
    }
  }
</style>
