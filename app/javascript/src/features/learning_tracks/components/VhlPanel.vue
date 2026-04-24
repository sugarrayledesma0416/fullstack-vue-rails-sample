<template>
  <div
    :class="[
      variantClasses,
      featureVariantClasses,
      getStateClasses(),
      testClass('vhl-panel'),
    ]">
    <div v-if="!hideHeader" class="panel__header" :class="testClass('panel-header')">
      <slot name="header" />
    </div>

    <div
      class="panel__body"
      :class="[
        { 'hide-padding' : hideBodyPadding },
        testClass('panel-body'),
      ]">
      <slot name="body" />
    </div>

    <div v-if="!hideFooter" class="panel__footer" :class="testClass('panel-footer')">
      <slot name="footer" />
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';
  const SUPPORTED_VARIANTS = ['default', 'padded'];
  const SUPPORTED_FEATURE_VARIANTS = ['learning-tracks'];

  /**
   * Panel states beside default:
   * active - visible, in focus
   * finished - any panel before the active one
   * upcoming - any panel after the active one
   */
  const SUPPORTED_STATES = ['active', 'finished', 'upcoming'];
  const FEATURE_VARIANT_CLASSES_MAP = {
    'learning-tracks': 'panel--learning-tracks',
  };
  const STATE_CLASSES_MAP = {
    'active': 'is-active',
    'finished': 'is-finished',
    'upcoming': 'is-upcoming',
  };

  export default {
    name: 'VhlPanel',
    props: {
      // Feature variants which override specific things in standard variants
      featureVariant: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_FEATURE_VARIANTS.includes(value),
      },
      // Hide body padding.
      // This is to remove extra space when content in body slot is not displayed
      hideBodyPadding: { type: Boolean, default: false },
      hideHeader: { type: Boolean, default: false },
      hideFooter: { type: Boolean, default: false },
      state: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_STATES.includes(value),
      },
      variant: {
        default: '',
        type: String,
        validator: (value) => value === '' || SUPPORTED_VARIANTS.includes(value),
      },
    },
    setup(props) {
      /**
       * Return panel state specific css classes
       * @return {string}
       */
      function getStateClasses() {
        return STATE_CLASSES_MAP[props.state] ?? '';
      }

      /**
       * @private
       * Return variant specific css classes for the panel
       * @return {string}
       */
      function getVariantClasses() {
        return props.variant ? `panel  panel--${props.variant}` : 'panel';
      }

      const featureVariantClasses = FEATURE_VARIANT_CLASSES_MAP[props.featureVariant] ?? '';
      const variantClasses = getVariantClasses();

      return { featureVariantClasses, getStateClasses, testClass, variantClasses };
    },
  };
</script>
<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  /*
    NOTE: Some inner element css classes (eg. c-panel__section, c-panel__flush-content) are
    excluded while porting css for panel (c-panel). This is because component exposes slots for
    header (c-panel__header ) and body (c-panel__body) and above excluded classes usually used in
    the content of these slots, so scoped css defined here won't apply to them.
  */

  // Variables specific to panel
  $panel-border-radius: 3px;
  $panel-default-bg-color: $gray-f5;
  $panel-padding: mod(0.5);
  $panel-padding-horizontal-lg: mod(2);
  $panel-padding-vertical-lg: mod(1);

  /* base */
  .panel {
    border-radius: $panel-border-radius;
  }

  /* Child elements */
  .panel > .panel__header {
    background-color: $panel-default-bg-color;
    padding: $panel-padding;
  }

  .panel > .panel__body,
  .panel > .panel__footer {
    padding: $panel-padding;
  }

  /*
    A panel with more padding than the default panel.
    `.panel--padded` - MODIFIER. Extends `panel`.
  */
  .panel--padded {
    /* Child elements */
    > .panel__header,
    > .panel__body,
    > .panel__footer {
      padding: $panel-padding-vertical-lg $panel-padding-horizontal-lg;
    }
  }

  /*
    START - Redefined common variables and functions etc. (for music alpha)
  */

  $border-width-sm: 1px;
  $current: #f69322;
  $font-size-md: 1rem;
  $gray-4: #444;
  $gray-6: #666;
  $gray-c: #ccc;
  $gray-e: #eee;
  $white: #fff;

  /*
    END - Redefined common variables and functions etc. (for music alpha)
  */

  // Variables specific to panel
  $panel-side-padding: 0.5rem;
  $panel-header-padding: $panel-side-padding;
  $panel-body-padding: 1rem $panel-side-padding;
  $panel-footer-padding: $panel-side-padding;

  /*
    Css related to learning tracks feature variants
  */
  .panel--learning-tracks {
    /* base */
    &.panel {
      position: relative;
    }

    > .panel__header {
      color: $gray-4;
      font-size: $font-size-md;
      padding: $panel-header-padding;
    }

    > .panel__body {
      padding: $panel-body-padding;
    }

    > .panel--footer {
      padding: $panel-footer-padding;
    }

    /*
      Variants
    */
    &.panel--default {
      border: $border-width-sm solid $gray-e;

      > .panel__header {
        background-color: $gray-e;
      }
    }

    /*
      Panel States

      is-active -- visible, in focus
      is-upcoming -- any panel _after_ the active one.
      is-finished -- any panel _before_ the active one.
    */
    &.panel {
      &.is-active {
        border: $border-width-sm solid $current;

        > .panel__header {
          background-color: $current;
          color: $gray-3;
        }
      }

      &.is-upcoming {
        border: 0;

        > .panel__header {
          background-color: $gray-c;
          border-color: $gray-c;
          color: $white;
        }
      }

      &.is-finished {
        border: 0;

        > .panel__header {
          background-color: $gray-6;
          color: $white;
        }

        > .panel__body {
          padding-bottom: 0;
        }
      }

      /*
        Hide panel border for panel types that are collapsed:
      */
      &.is-upcoming,
      &.is-finished {
        border: $border-width-sm solid transparent;
      }
    }
  }

  .panel > .panel__body.hide-padding {
    padding: 0;
  }
</style>
