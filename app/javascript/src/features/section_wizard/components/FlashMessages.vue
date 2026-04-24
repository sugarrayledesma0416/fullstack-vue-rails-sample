<template>
  <div class="c-live-flash-container">
    <!-- flash-error -->
    <div
      v-if="showError"
      id="flash_error"
      class="c-flash-banner  c-flash-banner--error  flash-error  u-mar-bot-16"
      :class="testClass('section-wizard-flash-error')"
      role="alert">
      An error occured. Please review the fields and try again.
    </div>
    <!-- flash-notice -->
    <div
      v-if="showNotice"
      id="flash_notice"
      class="c-flash-banner  c-flash-banner--notice  flash-notice  u-mar-bot-16"
      :class="testClass('section-wizard-flash-notice')"
      role="alert">
      Section has been successfully updated.
    </div>
  </div>
</template>

<script>
  import { testClass } from 'music';

  export default {
    name: 'FlashMessages',
    props: {
      showError: { default: false, type: Boolean },
      showNotice: { default: false, type: Boolean },
    },
    setup(props) {
      return { testClass };
    },
  };
</script>
