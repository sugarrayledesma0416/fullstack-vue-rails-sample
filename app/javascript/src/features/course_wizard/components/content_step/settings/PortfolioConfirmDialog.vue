<template>
  <BasicDialog
    :isConfirmationDialog="false"
    :isModal="true"
    title="Include Partner & Group Chats"
    @close-dialog="$emit('close')">
    <template #body>
      <div class="warning-msg  u-mar-bot-24">
        <img src="../../../icons/warning_icon.svg" class="u-mar-rt-8">
        This will allow students to include video chats <br>
        involving other students.
      </div>
      <div>
        Are you sure? Allowing students to add Partner and Group <br>
        Chats to their Portfolios implies consent on behalf of all <br>
        parties in the video recordings.
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
          cancel
        </StandardButton>
        <StandardButton
          variant="primary"
          class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
          :class="testClass('confirm-btn')"
          @click="onConfirmClick">
          confirm
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

.warning-msg {
  background-color: #fef4e4;
  display: flex;
  padding: rpx(16);
}
</style>
