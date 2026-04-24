<template>
  <div class="c-live-flash-container  u-z-flash">
    <!-- flash-error -->
    <sl-alert class="sl-error-alert  test-bulk-upload-flash-error" variant="danger"  v-if="showEmit.status && showEmit.payload.type == 'error'"  open closable>
      <sl-icon slot="icon" name="x-circle"></sl-icon>
      <strong>Error</strong><br />
      {{ showEmit.payload.message }}
    </sl-alert>

    <!-- flash-notice -->
    <sl-alert class="test-bulk-upload-flash-notice" v-if="showEmit.status && showEmit.payload.type == 'notice'"  variant="notice" open closable>
      <sl-icon slot="icon" name="check"></sl-icon>
        <strong>Notice</strong><br />
        {{ showEmit.payload.message }}
    </sl-alert>
    <!-- flash-success -->
    <sl-alert class="test-bulk-upload-flash-success" v-if="showEmit.status && showEmit.payload.type == 'success'"  variant="success" open closable>
      <sl-icon slot="icon" name="check"></sl-icon>
        <strong>Success</strong><br />
        {{ showEmit.payload.message }}
    </sl-alert>
  </div>
</template>

<script setup>
const props = defineProps({
  showEmit: {
    type: Object,
    default: {},
  }
});
</script>

<style scoped>
.c-live-flash-container {
  position: absolute; /* o absolute, fixed, sticky */
}
</style>
