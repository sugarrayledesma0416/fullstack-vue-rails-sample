<template>
  <div
    id="flash-banner"
    class="flash-banner"
    :class="`flash-banner--${variant}`"
    role="alert">
    {{ message }}
  </div>
</template>

<script>
  import { testClass } from 'music';

  const SUPPORTED_VARIANTS = ['error', 'notice'];

  export default {
    name: 'FlashMessages',
    props: {
      message: { default: '', type: String },
      variant: {
        default: 'notice',
        type: String,
        validator: (value) => value === '' || SUPPORTED_VARIANTS.includes(value),
      },
    },
    setup(props) {
      return { testClass };
    },
  };
</script>
<style lang="scss" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .flash-banner {
    background: #fff;
    border-radius: 0.1875rem;
    border-top: 0.25rem solid currentColor;
    box-shadow: rpx(1) rpx(4) rpx(6) 0 rgb(0 0 0 / 18%);
    max-width: 32rem;
    padding: 1rem 3rem 1rem 1rem;
    position: relative;
    text-align: left;
  }

  .flash-banner--notice {
    color: #1D873E;
  }

  .flash-banner--error {
    color: #CE0C24;
  }
</style>
