<template>
  <button
    :class="[
      variantClasses,
      featureVariantClasses,
      stateClasses,
      testClass('vhl-button'),
    ]"
    :disabled="disabled"
    :title="title"
    :type="type"
    @click="$emit('click')">
    <slot />
  </button>
</template>

<script>
  import { testClass } from 'music';

  const SUPPORTED_VARIANTS = ['border', 'circle', 'link', 'primary'];
  const SUPPORTED_FEATURE_VARIANTS = ['learning-tracks'];
  const FEATURE_VARIANT_CLASSES_MAP = {
    'learning-tracks': 'button--learning-tracks',
  };
  const STATE_CLASSES_MAP = { 'default': 'is-navigable' };
  const SUPPORTED_BUTTON_TYPES = ['button', 'submit'];

  export default {
    name: 'VhlButton',
    props: {
      disabled: { default: false, type: Boolean },
      // Feature variants which override specific things in standard variants
      featureVariant: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_FEATURE_VARIANTS.includes(value),
      },
      state: { default: '', type: String },
      title: { default: '', type: String },
      type: {
        default: 'button',
        type: String,
        validator: (value) => SUPPORTED_BUTTON_TYPES.includes(value),
      },
      // Standard button variants
      variant: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_VARIANTS.includes(value),
      },
    },
    emits: ['click'],
    setup(props) {
      /**
       * @private
       * Return feature variant specific css classes for the button
       * @return {string}
       */
      function getFeatureVariantClasses() {
        return FEATURE_VARIANT_CLASSES_MAP[props.featureVariant] ?? '';
      }

      /**
       * @private
       * Return state specific css classes for the button
       * @return {string}
       */
      function getStateClasses() {
        return STATE_CLASSES_MAP[props.state] ?? '';
      }

      /**
       * @private
       * Return variant specific css classes for the button
       * @return {string}
       */
      function getVariantClasses() {
        let variantClasses = '';
        if (props.variant === 'link') {
          variantClasses = 'no-button';
        } else if (props.variant === 'secondary' || props.variant === '') {
          variantClasses = 'button';
        } else {
          variantClasses = `button  button--${props.variant}`;
        }
        return variantClasses;
      }

      const featureVariantClasses = getFeatureVariantClasses();
      const stateClasses = getStateClasses();
      const variantClasses = getVariantClasses();

      return { featureVariantClasses, stateClasses, variantClasses, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  // Variables specific to button
  $button-border-radius: rpx(3);
  $button-border-width: rpx(1);
  $button-fade: 0.2s ease-in-out;
  $button-height: mod(1.5);
  $button-padding: mod(0.5) mod(1.5);

  @mixin button-base() {
    background: $white;
    border: 0;
    border-radius: $button-border-radius;
    color: $link-color;
    cursor: pointer;
    font-size: $font-size-14;
    letter-spacing: rpx(1);
    line-height: $button-height;
    padding: $button-padding;
    text-transform: uppercase;
    transition: color $button-fade,
                border-color $button-fade,
                background-color $button-fade,
                box-shadow $button-fade;

    &[disabled],
    &.is-disabled {
      color: $gray-c;
      cursor: not-allowed;
    }

    &:hover {
      background: $gray-f8;
    }
  }


  button {
    outline: 0.125rem solid transparent;
    outline-offset: 0.125rem;
  }

  /*
    Default button
  */
  .button {
    @include button-base();

    &[disabled] {
      background: transparent;
    }
  }

  .button--primary {
    background: $link-color;
    border: 0;
    box-shadow: $box-shadow-1;
    color: $white;
    min-width: mod(8);

    &:hover {
      background: $dark-blue;
      box-shadow: none;
      color: $white;
    }

    &[disabled],
    &.is-disabled {
      background: $gray-c;
      box-shadow: none;
      color: $white;
    }
  }

  .button--border {
    border: rpx(1) solid $gray-d;
    min-width: mod(8);
  }

  /*
    This class is used instead of `button` to remove all styling
    from a `<button>`.
  */
  .no-button {
    @include plain-button();
    color: $link-color;
    transition: color $button-fade, box-shadow $button-fade;

    &:hover:not([disabled]) {
      color: $link-hover-color;
      text-decoration: underline;
    }

    &[disabled],
    .is-disabled {
      color: $link-disabled-color;
      cursor: not-allowed;

      &:hover {
        outline: 0;
      }
    }
  }

  $focus-ring-color: lighten($link-color, 12%);

  button:focus {
    @include focus();
  }

  button:active {
    outline: 0;
  }

  /*
    START - Redefined common variables and functions etc. (for music alpha)
  */
  $border-width-sm: rpx(1);
  $box-shadow-1: 0 rpx(2) rpx(4) rgba(0,0,0,0.24);
  $box-shadow-3: 0 rpx(10) rpx(20) rgba(0,0,0,0.19), 0 rpx(6) rpx(6) rgba(0,0,0,0.23);
  $font-size-md: 1rem;
  $font-size-xs: 0.75rem;
  $link-blue: #006bae;
  $link-light-blue: #005285;
  /*
    END - Redefined common variables and functions etc. (for music alpha)
  */

  // Variables specific to button
  $button-border-radius: rpx(3);
  $button-border-width: rpx(1);
  $button-fade: 0.2s ease-in-out;
  $button-height: mod(2);
  $button-min-width: rpx(100);
  $button-padding: 0 mod(0.75);

  /* Css related to learning-tracks feature variants */
  .button--learning-tracks {
    /* Default button */
    &.button {
      background: $white;
      border: $button-border-width solid $link-blue;
      border-radius: $button-border-radius;
      box-shadow: $box-shadow-1;
      box-sizing: border-box;
      color: $link-blue;
      font-size: $font-size-xs;
      line-height: $button-height;
      min-width: $button-min-width;
      padding: $button-padding;
      text-align: center;
      text-decoration: none;
      text-transform: inherit;
      transition: color $button-fade,
                  border-color $button-fade,
                  box-shadow $button-fade;

      &:hover {
        background: $white;
        border-color: $link-light-blue;
        box-shadow: $box-shadow-3;
        outline: 0;
        text-decoration: none;
      }

      &[disabled] {
        background: $white;
        border: $border-width-sm solid $gray-c;
        box-shadow: none;
        color: $gray-c;
        cursor: default;

        &:hover {
          border-color: $gray-c;
          box-shadow: none;
          color: $gray-c;
          outline: 0;
        }
      }
    }

    &.button--primary {
      background: $link-blue;
      border: 0;
      color: $white;
      text-transform: uppercase;

      &:hover {
        background: $link-light-blue;
      }

      &[disabled] {
        background: $gray-c;
        box-shadow: none;
        color: $white;
        cursor: default;

        &:hover {
          background: $gray-c;
          box-shadow: none;
          color: $white;
        }
      }
    }

    /*
      Small button for single icon or character label.
    */
    &.button--circle {
      border-radius: 50%;
      font-size: $font-size-md;
      height: mod(1.5);
      line-height: 1;
      min-width: 0;
      padding: 0;
      text-align: center;
      width: mod(1.5);
    }

    &.no-button {
      background: transparent;
      border: 0;
      padding: 0;
    }
  }
</style>
