<template>
  <div>
    <div class="flash-msg-contaner">
      <FlashBannerComponent :message="flashMsg" @reset="resetMessage" />
    </div>
    <StandardButton
      variant="border"
      :class="[
        { 'u-hidden': bPortfolioOnSubmitFeature },
        'js-export-portfolio-btn',
        testClass('export-portfolio-btn')
      ]"
      :title="isExportDisabled ? 'Activity already exported to your portfolio.' : ''"
      :disabled="isExportDisabled"
      @click="showConfirmationModal(true)">
      <MusicIcon variant="reference" />
      Export To Portfolio
    </StandardButton>
    <input
      type="hidden"
      name="auto_export_portfolio"
      class="js-auto-export-portfolio"
      :value="bAutoExport">
    <input type="hidden" class="js-export-with-submit-feature" :value="bPortfolioOnSubmitFeature">

    <ConfirmExportDialog
      v-if="showConfirmDialog"
      @close="onCancelExport"
      @confirm="onConfirmExport" />
  </div>
</template>

<script setup>
  import { postToEndpoint, StandardButton, testClass } from 'music';
  import { nextTick, onMounted, ref, reactive } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import ConfirmExportDialog from './ConfirmExportDialog';
  import FlashBannerComponent from 'features/flash_banner/FlashBannerComponent';
  import MusicIcon from 'shared/vue/MusicIcon';

  const props = defineProps({
    artifactShared: { default: '', type: String },
    portfolioOnSubmitFeature: { default: '', type: String },
  });

  const showConfirmDialog = ref(false);
  const flashMsg = reactive({
    shown: false,
    text: '',
    className: '',
  });

  const isExportDisabled = ref(
    ['in_progress', 'success'].includes(props.artifactShared)
  );
  const bAutoExport = ref(false);
  const bModalByPortfolioButton = ref(false);

  /**
   * Portfolio export with submit should not used after submission
   * before page refresh in chat activities. So allowing this feature only once.
   */
  const bPortfolioOnSubmitFeature = props.portfolioOnSubmitFeature == 'true';

  /**
   * Show confirmation modal.
   * @param {boolean} byPortfolioButton - Whether Confirmation modal is open
   * by Export To Portfolio button
   */
  function showConfirmationModal(byPortfolioButton) {
    showConfirmDialog.value = true;
    bModalByPortfolioButton.value = byPortfolioButton === true;
  }

  /**
   * Store click handler on submit button and
   * change button type to avoid form submission.
   */
  function storeOnclick() {
    const submitBtn = document.querySelector('.js-activity-submit');
    if (submitBtn) {
      window.submitOnclickFn = submitBtn.onclick;
      submitBtn.onclick = showConfirmationModal;
      submitBtn.setAttribute('type', 'button');
    }
  }

  /**
   * Restore click handler on submit button and
   * change button type to enable form submission.
   */
  function restoreOnclick() {
    const submitBtn = document.querySelector('.js-activity-submit');
    if (submitBtn) {
      submitBtn.onclick = window.submitOnclickFn;
      submitBtn.setAttribute('type', 'submit');
    }
  }

  /**
   * Trigger event to signal chat handler to avoid binding of overriding click handlers.
   */
  function triggerExportOnSubmitEvent() {
    const exportOnSubmitSelectedEvt = new CustomEvent('export-on-submit-selected');
    document.dispatchEvent(exportOnSubmitSelectedEvt);
  }

  /**
   * Restore onclick event handler on submit button and then click the
   * submit button to submit the activity with portfolio auto export preference.
   * Hide the confirmation dialog.
   * @async
   * @param {boolean} shouldExportWithSubmit
   */
  async function submit(shouldExportWithSubmit) {
    bAutoExport.value = shouldExportWithSubmit;
    restoreOnclick();
    triggerExportOnSubmitEvent();
    await nextTick();
    const submitBtn = document.querySelector('.js-activity-submit');
    submitBtn.click();
    showConfirmDialog.value = false;
    preventAutoExportInFurtherSubmitClicks();
  }

  /**
   * Avoid auto-export feature on submit button if pressed again, because now
   * Portfolio Export confirmation dialog would not be shown.
   * Eg. use case is when user cancels submission via Blank Submission Confirmation moda
   * after click on submit button.
   */
  async function preventAutoExportInFurtherSubmitClicks() {
    await nextTick();
    bAutoExport.value = false;
  }

  /**
   * If prop portfolioOnSubmitFeature is true then submit
   * the activity with portfolio export on.
   * Hide the confirmation dialog.
   *
   * It will not submit if modal was open by
   * Export To Portfolio button instead of submit button.
   * This is needed so that after pchat submission, when portfolio button is visible
   * by client side code, Portfolio Confirmation Modal handlers dont submit again.
   * @async
   */
  async function onConfirmExport() {
    if (bPortfolioOnSubmitFeature && !bModalByPortfolioButton.value) {
      await submit(true);
    } else {
      exportToPortfolio();
    }
  }

  /**
   * If prop portfolioOnSubmitFeature is true then submit
   * the activity with portfolio export off.
   * Hide the confirmation dialog.
   *
   * It will not submit if modal was open by
   * Export To Portfolio button instead of submit button.
   * This is needed so that after pchat submission, when portfolio button is visible
   * by client side code, Portfolio Confirmation Modal handlers dont submit again.
   * @async
   */
  async function onCancelExport() {
    if (bPortfolioOnSubmitFeature && !bModalByPortfolioButton.value) {
      await submit(false);
    } else {
      showConfirmDialog.value = false;
    }
  }

  /**
   * Reset the flash message.
   */
  const resetMessage = () => {
    flashMsg.shown = false;
    flashMsg.text = '';
    flashMsg.className = '';
  };

  /**
   * Export activity to portfolio application.
   */
  function exportToPortfolio() {
    const sectionId = metaTagContent('VHL.section_id');
    const activityId = metaTagContent('VHL.activity_id');
    postToEndpoint(
      `/sections/${sectionId}/activities/${activityId}/export_portfolio`,
      { },
      (data) => {
        showConfirmDialog.value = false;
        flashMsg.shown = true;
        if (data.success) {
          flashMsg.text = 'Activity successfully sent to Portfolio.';
          flashMsg.className = 'success';
          isExportDisabled.value = true;
        } else if (data.status == 'prev_export_in_progress') {
          flashMsg.text = 'Activity could not be sent to Portfolio because ' +
            'previous export is in progress.';
          flashMsg.className = 'error';
        } else if (data.status == 'prev_export_is_success') {
          flashMsg.text = 'Activity could not be sent to Portfolio because ' +
            'it is already exported.';
          flashMsg.className = 'error';
        } else {
          flashMsg.text = 'Activity could not be sent to Portfolio.';
          flashMsg.className = 'error';
        }
      }
    );
  }

  onMounted(() => {
    if (bPortfolioOnSubmitFeature) {
      storeOnclick();
    }
  });
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .flash-msg-contaner {
    position: fixed;
    right: 0;
    top: rpx(8);
    width: 100%
  }
</style>

