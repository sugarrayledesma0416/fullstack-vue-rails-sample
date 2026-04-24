<template>
  <a
    :href="href"
    class="c-link"
    :class="[
      testClass(testSelector),
      variantClass(variant),
      variantClass(featureVariant),
      { 'is-disabled': isDisabled }
    ]"
    :target="target"
    :title="title"
    @click="$emit('click')"
    @mouseover="$emit('mouseover')"
    @mouseleave="$emit('mouseleave')">
    <!--
      Supporting dynamic html here.
      If htmlText prop value is present then use v-html else use slot.
    -->
    <!-- eslint-disable vue/no-v-html -->
    <span
      v-if="htmlText"
      class="html-text"
      :class="testClass('html-text')"
      v-html="htmlText" />
    <!-- eslint-enable vue/no-v-html -->
    <slot v-else />
  </a>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'VhlLink',
    props: {
      featureVariant: { default: '', type: String },
      href: { required: true, type: String },
      // htmlText is used to render dynamic link text having html tags
      htmlText: { default: '', type: String },
      isDisabled: { default: false, type: Boolean },
      target: { default: null, type: String },
      testSelector: { default: 'a-tag', type: String },
      title: { default: '', type: String },
      variant: { default: '', type: String },
    },
    emits: ['click', 'mouseleave', 'mouseover'],
    setup() {
      /**
       * creates a class based on the variant passed.
       * @param {string} variant - variant name passed. It can be variant and
       * feature variant.
       * @return {string} variant class.
       */
      function variantClass(variant) {
        return variant === '' ? variant : `c-link--${variant}`;
      }

      return { testClass, variantClass };
    },
  };
</script>

<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  $font-size-xs: 12px;
  $link-color: #006bae;
  $link-disabled-color: #ccc;
  $link-hover-color: shade-saturate($link-color, 30);
  $link-light-blue: #005285;
  $button-fade: 0.2s ease-in-out;

  .c-link {
    color: $link-color;
    text-decoration: none;
    transition: color 0.3s;

    &:hover {
      color: $link-hover-color;
      text-decoration: underline;
    }

    &.is-disabled,
    &.is-disabled:hover,
    &.is-disabled:active {
      color: $link-disabled-color;
      cursor: not-allowed;
      text-decoration: none;
    }
  }

  .c-link--button {
    color: #006bae;
    background: #fff;
    border: 0.0625rem solid #ddd;
    border-radius: 0.1875rem;
    box-sizing: border-box;
    cursor: pointer;
    font-size: 0.875rem;
    letter-spacing: 0.0625rem;
    line-height: 1.5rem;
    min-width: 8rem;
    padding: 0.5rem 1.5rem;
    text-transform: uppercase;
    transition: color $button-fade,
                border-color $button-fade,
                background-color $button-fade,
                box-shadow $button-fade;
  }

  .c-link--learning-tracks {
    color: $link-color;
    font-size: $font-size-xs;
    text-decoration: none;
    text-transform: uppercase;
    transition: color 0.3s, text-decoration 0.3s;

    &:hover {
      color: $link-light-blue;
      text-decoration: underline;
    }
  }

  .c-link--learning-tracks {
    &.c-link--button {
      background: #fff;
      border: rpx(1) solid #006bae;
      border-radius: rpx(3);
      box-shadow: 0 rpx(2) rpx(4) rgb(0 0 0 / 24%);
      box-sizing: border-box;
      color: #006bae;
      display: inline-block;
      font-size: 0.75rem;
      line-height: 2rem;
      min-width: rpx(100);
      padding: 0 0.75rem;
      text-align: center;
      text-decoration: none;
      text-transform: inherit;
      transition: color 0.2s ease-in-out,
        border-color 0.2s ease-in-out,
        box-shadow 0.2s ease-in-out;

      &:hover {
        background: #fff;
        border-color: #005285;
        box-shadow: 0 rpx(10) rpx(20) rgb(0 0 0 / 19%),
          0 rpx(6) rpx(6) rgb(0 0 0 / 23%);
        outline: 0;
        text-decoration: none;
      }

      &[disabled] {
        background: #fff;
        border: rpx(1) solid #ccc;
        box-shadow: none;
        color: #ccc;
        cursor: default;

        &:hover {
          border-color: #ccc;
          box-shadow: none;
          color: #ccc;
          outline: 0;
        }
      }
    }
  }

  .c-link--learning-tracks[disabled] {
    color: $gray-c;
    cursor: default;

    &:hover {
      color: $gray-c;
      outline: 0;
      text-decoration: none;
    }
  }
</style>
