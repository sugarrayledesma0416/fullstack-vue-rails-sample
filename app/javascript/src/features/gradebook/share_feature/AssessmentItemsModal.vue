<template>
  <ModalComponent
    :class="testClass('assessment-items-review-modal')"
    featureVariant="full-content-area"
    :hideHeader="true"
    scrollable="false"
    @close="closePreviewModal">
    <template #body>
      <div class="modal_body">
        <div class="l-line  standards-modal-header  u-center-overlay  u-pad-12">
          <div class="u-mar-bot-0  u-mar-rt-12  u-center-vertical  u-txt-bold">
            {{ standardLabel }}
          </div>
          <div class="c-button-group  u-mar-bot-0  u-mar-rt-32">
            <ButtonSecondary
              class="c-button  u-mar-rt-12"
              :class="testClass('previous-button')"
              type="button"
              :disabled="selectedItemNumberRef <= 0"
              @click="handlePreviousItemClick()">
              Previous
            </ButtonSecondary>
            <ButtonSecondary
              class="c-button"
              :class="testClass('next-button')"
              :disabled="selectedItemNumberRef + 1 >= totalItemsNumber"
              type="button"
              @click="handleNextItemClick()">
              Next
            </ButtonSecondary>
          </div>
          <div class="u-txt-gray-a">
            Item {{ selectedItemNumberRef + 1 }} of {{ totalItemsNumber }}
          </div>
        </div>
        <QuestionItem
          class="u-mar-top-12"
          :standardLabel="standardLabel"
          :mutatedModalBody="mutatedModalBodyRef"
          :errorIconPath="errorIconPath"
          :successIconPath="successIconPath" />
      </div>
    </template>
  </ModalComponent>
</template>
<script setup>
  import { nextTick, ref, watch } from 'vue';
  import { testClass } from 'music';
  import ModalComponent from 'features/modal/ModalComponent';
  /* eslint-disable-next-line max-len*/
  import ButtonSecondary from 'music/app/javascript/src/components/button_secondary/v1.1/ButtonSecondary';
  import QuestionItem from './QuestionItem';
  import {
    reInitializeRecordingV2,
    setUpCompositionEditor,
  } from '../standards/student_detail_report/utilities';

  const props = defineProps({
    assessmentItemModalConfig: { required: true, type: Object },
    reviewPath: { required: true, type: String },
    standardDetails: { required: true, type: Object },
    errorIconPath: { required: true, type: String },
    successIconPath: { required: true, type: String },
  });

  const selectedItemNumberRef = ref(0);
  const standardLabel = ref('');
  const mutatedModalBodyRef = ref('');
  const totalItemsNumber = ref(0);

  const emit = defineEmits(['toggleAssessmentItemsModalVisibility']);

  const fetchActivityPreviewHtml = async (previewPath, callback) => {
    fetch(
      previewPath,
      {
        credentials: 'include',
        headers: { 'Content-Type': 'text/html' },
        method: 'GET',
      }
    )
      .then((resp) => resp.text())
      .then(callback);
  };

  /**
   * Handles the next assessment item to show from the modal
   */
  function handleNextItemClick() {
    selectedItemNumberRef.value++;
    const itemGuid = props.assessmentItemModalConfig.itemGuids[selectedItemNumberRef.value];
    fetchActivityPreviewHtml(
      `${props.reviewPath}?assessment_item_guid=${itemGuid}`,
      (response) => {
        if (response) {
          mutatedModalBodyRef.value = response;
        }
      });
  }

  /**
   * Handles the next assessment item to show from the modal
   */
  function handlePreviousItemClick() {
    selectedItemNumberRef.value--;
    const itemGuid = props.assessmentItemModalConfig.itemGuids[selectedItemNumberRef.value];
    fetchActivityPreviewHtml(
      `${props.reviewPath}?assessment_item_guid=${itemGuid}`,
      (response) => {
        if (response) {
          mutatedModalBodyRef.value = response;
        }
      });
  }

  /**
   * handles the preview modal close
   */
  function closePreviewModal() {
    selectedItemNumberRef.value = 0;
    totalItemsNumber.value = 0;
    mutatedModalBodyRef.value = '';
    emit('toggleAssessmentItemsModalVisibility');
  }

  /**
   * Opens the items review modal
   * @param{String} assessmentSelected, the assessment from the items count that was clicked
   */
  function openReviewModal() {
    const itemGuid = props.assessmentItemModalConfig.itemGuids[selectedItemNumberRef.value];
    totalItemsNumber.value = props.assessmentItemModalConfig.itemGuids.length;
    fetchActivityPreviewHtml(
      `${props.reviewPath}?assessment_item_guid=${itemGuid}`,
      (response) => {
        if (response) {
          mutatedModalBodyRef.value = response;
        }
      }
    );
    emit('toggleAssessmentItemsModalVisibility');
  }

  watch(() => mutatedModalBodyRef.value, async () => {
    await nextTick();
    reInitializeRecordingV2();
    setUpCompositionEditor();
  });

  watch(
    ()=> props.assessmentItemModalConfig.isModalOpen,
    (newValue) => {
      if (newValue == true) {
        standardLabel.value = props.assessmentItemModalConfig.standardLabel;
        openReviewModal();
      }
    }
  );
</script>
