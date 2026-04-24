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
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $border-width-sm: rpx(1);
  $checkbox-size: rpx(18);
  $checkbox-margin: rpx(2);

  .checkbox-input {
    border: 0;
    clip: rect(0 0 0 0);
    height: rpx(1);
    margin: -rpx(1);
    overflow: hidden;
    padding: 0;
    position: absolute;
    width: rpx(1);
  }

  .checkbox-input,
  .checkbox-label {
    display: inline-block;
    font-weight: normal;
    line-height: $checkbox-size;
    vertical-align: middle;
  }

  .checkbox-label {
    font-size: $font-size-12;
    outline: rpx(2) solid transparent;
    outline-offset: rpx(2);
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
      height: $checkbox-size - rpx(1);
      display: block;
      left: rpx(2);
      opacity: 0.7;
      position: absolute;
      top: rpx(2);
      width: $checkbox-size - rpx(1);
    }
  }

  .checkbox-input:checked + .checkbox-label::after {
    background-image: url('/images/checkmark-black.svg');
  }

  .checkbox-input:disabled + .checkbox-label {
    opacity: 0.35;
  }

  .checkbox-input:focus + .checkbox-label::before {
    @include focus();
  }

  .checkbox-input-container--learning-track-due-dates {
    .checkbox-label  {
      color: $gray-6;
      font-size: 0.75rem;
    }
  }
</style>
