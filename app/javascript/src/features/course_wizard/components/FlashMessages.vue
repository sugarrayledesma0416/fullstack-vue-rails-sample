<template>
  <div class="flash-banner-container">
    <FlashBanner
      v-if="showError"
      variant="error"
      :message="flashError"
      :class="testClass('course-wizard-flash-error')" />
    <FlashBanner
      v-if="showNotice"
      variant="notice"
      :message="flashNotice"
      :class="testClass('course-wizard-flash-notice')" />
  </div>
</template>

<script>
  import { testClass } from 'music';
  import FlashBanner from './FlashBanner';

  export default {
    name: 'FlashMessages',
    components: { FlashBanner },
    props: {
      flashError: { default: '', type: String },
      flashNotice: { default: '', type: String },
      showError: { default: false, type: Boolean },
      showNotice: { default: false, type: Boolean },
    },
    setup(props) {
      return { testClass };
    },
  };
</script>
<style lang="scss" scoped>
  .flash-banner-container {
    align-items: flex-end;
    display: flex;
    flex-direction: column;
    position: absolute;
    right: 0.5rem;
    top: 4.5rem;
    width: 20rem;
    z-index: 1;
  }
</style>
