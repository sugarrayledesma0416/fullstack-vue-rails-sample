<template>
  <div
    class="expander"
    :class="[
      testClass('vhl-expander'),
      `expander--${variant}`,
    ]">
    <button
      type="button"
      class="expander__button"
      :class="[
        {'is-expanded': expanded},
        testClass('expander-button')
      ]"
      :aria-expanded="expanded"
      @click="$emit('expanderClick')">
      <div class="expander__button-content">
        <span
          v-if="variant == 'start'"
          class="expander__image"
          :class="testClass('expander-image')">
          <span class="embedded-icon">
            <ArrowIcon />
          </span>
        </span>
        <span
          class="expander__header-text"
          :class="[
            testClass(headerClass),
            headerClass]">
          {{ headerLabel }}
        </span>
        <span
          v-if="variant == 'end'"
          class="expander__image"
          :class="testClass('expander-image')">
          <span class="embedded-icon">
            <CaretIcon />
          </span>
        </span>
      </div>
    </button>

    <Expandable :expand="expanded">
      <div
        class="expander__body"
        :class="testClass('expander-body')">
        <slot />
      </div>
    </Expandable>
  </div>
</template>

<script setup>
  /* Component copied and *modified* from features/learning_tracks/Expander.vue */
  import { reactive, computed } from 'vue';
  import { testClass } from 'music';
  import Expandable from './Expandable';
  import ArrowIcon from './ArrowIcon';
  import CaretIcon from './CaretIcon';

  const props = defineProps({
    variant: {
      type: String,
      default: 'start',
      validator: (value) => ['start', 'end'].includes(value),
    },
    expanded: { type: Boolean, default: false },
    headerTextOpen: { type: String, default: '', required: true },
    headerTextClosed: { type: String, default: '', required: true },
    headerClass: { type: String, default: 'expander-header-text' },
  });

  const headerLabel = computed(() => {
    return props.expanded ? props.headerTextOpen : props.headerTextClosed;
  });
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';
  @import 'features/shared/icon_styles';

  .expander {
    --expander-header-fill-color: transparent;
    --expander-header-text-color: #{$link-color};
    --expander-header-text-size: var(--font-2, #{$font-size-14});
    --expander-header-text-case: uppercase;
    --expander-header-text-weight: regular;
    --expander-header-text-style: normal;
    --expander-header-padding: #{mod(0.5)};
    --expander-body-fill-color: transparent;
    --expander-body-text-color: #{$gray-6};
    --expander-body-text-size: inherit;
    --expander-body-padding: #{mod(0.5)};

    border-width: 0;
    line-height: 1.5;
    position: relative;
  }

  .expander__button {
    background-color: var(--expander-header-fill-color);
    border: 0;
    cursor: pointer;
    padding: var(--expander-header-padding);
    padding-left: 0;
    width: 100%;
  }

  .expander__button-content {
    display: flex;
    justify-content: flex-start;
    align-items: center;
  }

  .expander__image {
    display: inline-block;
    margin-bottom: 0;
    position: relative;
    transform-origin: 50%;
    transition: transform 0.2s;
    vertical-align: middle;

    @include theme-opt-in('supersites-junior') {
      height: 2rem;
      width: 2rem;
      margin-right: 1.25rem;
    }
  }

  .expander--start {
    .expander__image { transform: rotate(90deg) }
    .is-expanded .expander__image { transform: rotate(180deg) }
  }

  .expander--end {
    .expander__image { transform: rotate(90deg) }
    .is-expanded .expander__image { transform: rotate(-90deg) }
  }

  .expander__header-text {
    color: var(--expander-header-text-color);
    font-size: var(--expander-header-text-size);
    font-style: var(--expander-header-text-style);
    font-weight: var(--expander-header-text-weight);
    margin-bottom: 0;
    margin: 0 mod(0.5) 0 0;
    text-transform: var(--expander-header-text-case, none);
    letter-spacing: 0.02em;

    .expander--start & {
      margin: 0 0 0 mod(0.25);
    }
  }
  .expander__body {
    background-color: var(--expander-body-fill-color);
    color: var(--expander-body-text-color);
    font-size: var(--expander-body-text-size);
    padding: 0;
  }
</style>
