<template>
  <div
    class="expander"
    :class="testClass('vhl-expander')">
    <button
      type="button"
      class="expander__button"
      :class="[
        {'is-expanded': localStore.expand},
        testClass('expander-button')
      ]"
      :aria-expanded="localStore.expand"
      @click="localStore.expand = !localStore.expand">
      <div class="expander__button-content">
        <span
          class="expander__image"
          :class="testClass('expander-image')">
          <Icon :svg="arrowSvg" />
        </span>
        <span
          class="expander__header-text"
          :class="testClass('expander-header-text')">
          {{ headerText }}
        </span>
      </div>
    </button>

    <Expandable :expand="localStore.expand">
      <div
        class="expander__body"
        :class="testClass('expander-body')">
        <slot />
      </div>
    </Expandable>
  </div>
</template>

<script>
  import { reactive } from 'vue';
  import { testClass } from 'music';
  import Expandable from 'features/learning_tracks/components/Expandable';
  import Icon from 'features/shared/Icon';
  import arrowSvg from '!!raw-loader!MusicAssets/images/music/icons/arrow.svg';

  export default {
    name: 'VhlExpander',
    components: { Expandable, Icon },
    props: {
      headerText: { type: String, default: '' },
    },
    setup(props) {
      const localStore = reactive({
        expand: false,
      });
      return { arrowSvg, localStore, testClass };
    },
  };
</script>
<style lang="sass" scoped>
  /*
    START - Redefined common variables and functions etc. (for music v1)
  */

  $mod: 1rem;

  @function mod($size) {
    @return $mod * $size;
  }

  $default-font-stack: Open Sans, Helvetica Neue, Helvetica, Arial, Sans-serif;
  $font-size-md: 1rem;
  $font-size-sm:  0.875rem;
  $gray-3: #333;
  $gray-4: #444;
  $body-text: #666;
  $gray-e: #eee;
  /*
    END - Redefined common variables and functions etc. (for music v1)
  */

  $panel-side-padding: 0.5rem;
  $panel-header-padding: $panel-side-padding;

  .expander {
    border-width: 0rem;
    color: $body-text;
    line-height: 1.5;
    font-family: $default-font-stack; /* Open Sans, etc. */
    font-size: $font-size-sm;
    position: relative;
  }

  .expander__button {
    background-color: $gray-e;
    border: 0;
    color: $gray-4;
    cursor: pointer;
    font-size: $font-size-md;
    padding: $panel-header-padding;
    width: 100%;
  }

  .expander__button-content {
    display:flex;
    justify-content: flex-start;
    align-items: center;
  }

  .expander__image {
    background-size: 100% 100%;
    display: inline-block;
    height: 1.5rem;
    margin-bottom: 0;
    margin-right: mod(1);
    transform: rotate(90deg);
    transition: transform 0.2s;
    vertical-align: middle;
    width: 1.5rem;
  }

  .expander__button.is-expanded .expander__image{
    transform: rotate(180deg);
  }

  .expander__header-text {
    font-size: $font-size-md;
    font-weight: normal;
    margin-bottom: 0;
    margin-right: 0;
    text-transform: uppercase;
  }

  .expander__body {
    padding: 0;
  }

</style>
