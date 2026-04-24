<template>
  <BasicDialog
    v-show="showConfirmDialog"
    :isConfirmationDialog="false"
    :isModal="true"
    title="Submit Activity?"
    @close-dialog="onCancelSubmit">
    <template #body>
      <p>
        This is your final attempt. If you submit the activity now,
        you will not be able to make any changes. This is a graded activity.
      </p>

      <div v-if="showLoadingIcon" class="spinner-img">
        <img :src="spinnerImage" alt="Loading..." />
      </div>
    </template>

    <template #footer>
      <div class="confirmation-dialog__buttons">
        <StandardButton
          class="u-mar-rt-8"
          :class="testClass('cancel-btn')"
          @click="onCancelSubmit">
          Cancel
        </StandardButton>

        <StandardButton
          variant="primary"
          class="js-dialog-a11y__default-focus  js-dialog-a11y__last-focus-elm"
          :class="testClass('confirm-btn')"
          @click="onConfirmSubmit">
          Confirm Submit
        </StandardButton>
      </div>
    </template>
  </BasicDialog>
</template>

<script setup>
  import { onBeforeUnmount, onMounted, ref } from 'vue';
  import { StandardButton, testClass } from 'music';
  import BasicDialog from 'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';
  import spinnerImage from 'images/loading_32.gif';

  const showLoadingIcon = ref(false);
  const showConfirmDialog = ref(false);

  function openConfirmDialog() {
    showConfirmDialog.value = true;
  }

  /**
   * Handles the confirmation of an activity submission.
   *
   * This function is triggered when the user confirms their intent to submit
   * the activity. It performs the following steps:
   *
   * @function
   */
  function onConfirmSubmit() {
    showLoadingIcon.value = true;

    try {
      const submitBtn = document.querySelector('.js-activity-submit');
      const form = submitBtn?.closest('form');

      if (!submitBtn || !form) {
        handleSubmissionFailure();
        return;
      }

      if (typeof VHL?.Activity?.Submission?.ajax_submission === 'function') {
        VHL.Activity.Submission.ajax_submission();
      } else {
        form.submit();
      }
    } catch (error) {
      console.error('Error during form submission:', error);
      handleSubmissionFailure();
    }
  }

  /**
   * Handles submission failure by restoring the UI state and unsaved work.
   */
  function handleSubmissionFailure() {
    onCancelSubmit();
  }

  function onCancelSubmit() {
    showConfirmDialog.value = false;
    showLoadingIcon.value = false;

    document.dispatchEvent(new CustomEvent('restoreUnsavedWork', {
      detail: { reason: 'submission_cancelled' }
    }));
  }

  /**
   * Sets up a one-time event listener for the activity submit button.
   *
   * @function
   * @returns {void}
   */
  function setupSubmitButtonListener() {
    const submitBtn = document.querySelector('.js-activity-submit');
    const form = submitBtn?.closest('form');
    if (!form) return;

    const handler = (e) => {
      e.preventDefault();
      e.stopImmediatePropagation();
      openConfirmDialog();
    };

    form.addEventListener('submit', handler, { once: true });
  }

  onMounted(() => {
    document.addEventListener('unansweredDialogNotShown', setupSubmitButtonListener);
  });

  onBeforeUnmount(() => {
    document.removeEventListener('unansweredDialogNotShown', setupSubmitButtonListener);
  });
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .confirmation-dialog__buttons {
    display: block;
    text-align: center;

    @include viewport-min('md') {
      display: flex;
      justify-content: flex-end;
    }
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
