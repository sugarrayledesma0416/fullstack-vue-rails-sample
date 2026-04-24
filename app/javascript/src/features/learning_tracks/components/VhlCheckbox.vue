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
      @input="$emit('update:checked', $event.target.checked)">
    <label class="checkbox-label" :class="testClass(testSelectorLabel)" :for="id">
      <slot />
    </label>
  </span>
</template>

<script>
  import { isEmpty } from 'shared/utils';
  import { testClass } from 'music';

  export default {
    name: 'VhlCheckbox',
    props: {
      checked: { default: false, type: Boolean },
      disabled: { default: false, type: Boolean },
      featureVariant: { default: '', type: String },
      id: { default: '', type: String },
      name: { default: '', type: String },
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
  $border-width-sm: 0.0625rem;
  $checkbox-size: 1.125rem;
  $checkbox-margin: 0.125rem;
  $dark:#333;
  $font-size-sm:  0.875rem;
  $gray-c:#ccc;
  $white:#fff;

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
    line-height: $checkbox-size;
    vertical-align: middle;
  }

  .checkbox-label {
    font-size: $font-size-sm;
    outline: 0.125rem solid transparent;
    outline-offset: 0.125rem;
    padding: 0 0 0 1.5rem;
    position: relative;

    &::before {
      background: $white;
      border: $border-width-sm solid $gray-c;
      content: '';
      display: inline-block;
      height: $checkbox-size;
      left: 0;
      margin-right: $checkbox-margin;
      position: absolute;
      top: 0;
      vertical-align: middle;
      width: $checkbox-size;
    }

    &::after {
      background-size: 100% 100%;
      content: ' ';
      height: $checkbox-size - 0.0625rem;
      display: block;
      left: 0.125rem;
      opacity: 0.7;
      position: absolute;
      top: 0.125rem;
      width: $checkbox-size - 0.0625rem;
    }
  }

  .checkbox-input:checked + .checkbox-label::after {
    background-image: url('/images/checkmark-black.svg');
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
      color: #666;
      font-size: 0.75rem;
    }
  }
</style>
