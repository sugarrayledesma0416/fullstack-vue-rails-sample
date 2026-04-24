<template>
  <BasicDialog
    :isConfirmationDialog="false"
    :isModal="true"
    title="Send to Portfolio"
    @close-dialog="$emit('close')">
    <template #body>
      <div>
        <strong>Activity Successfully Submitted.</strong>
          Would you also like to send this activity to your Portfolio now? 
          If you choose not to, you can return and send it later.
      </div>

      <div v-show="showLoadingIcon" class="spinner-img">
        <img :src="spinnerImage">
      </div>
    </template>
    <template #footer>
      <div class="confirmation-dialog__buttons">
        <StandardButton
          class="u-mar-rt-8"
          :class="testClass('cancel-btn')"
          @click="$emit('close')">
          Close
        </StandardButton>
        <StandardButton
          variant="primary"
          class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
          :class="testClass('confirm-btn')"
          @click="onConfirmClick">
          Send Now
        </StandardButton>
      </div>
    </template>
  </BasicDialog>
</template>

<script setup>
  import { ref } from 'vue';
  import { StandardButton, testClass } from 'music';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import spinnerImage from 'images/loading_32.gif';

  const emit = defineEmits(['close', 'confirm']);
  const showLoadingIcon = ref(false);

  /**
   * Confirm button click handler.
   */
  function onConfirmClick() {
    showLoadingIcon.value = true;
    emit('confirm');
  }

</script>

<style lang="sass" scoped>
@import '~MusicAssets/stylesheets/music/library/v1/base/main';

.confirmation-dialog__buttons {
  display: flex;
  justify-content: flex-end;
}

.spinner-img {
  left: 0;
  margin: auto;
  position: absolute;
  right: 0;
  text-align: center;
}

:deep(.dialog-block__box) {
  width: 40%;
}
</style>
