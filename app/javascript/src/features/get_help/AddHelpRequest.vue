<template>
  <div v-if="addMode" ref="refModalContainerElm" class="ns-music-v1">
    <ModalComponent
      :title="requestDialogModel.title"
      @close="onCloseClick">
      <template #body>
        <div
          v-if="requestDialogModel.directionsVisible"
          class="u-mar-bot-20  u-txt-lt"
          :class="testClass('help-request-direction')"
          v-html="requestDialogModel.directionsText" />
        <div
          v-if="requestDialogModel.requestTextareaVisible">
          <label for="student_comment"> Comment (Required) </label>
          <textarea
            id="student_comment"
            ref="refTextareaElm"
            v-model="requestDialogModel.commentValue"
            name="student_comment"
            placeholder="Type here..."
            rows="4"
            cols="50"
            class="u-width-full  js-modal-a11y__default-focus"
            :class="testClass('help-request-comment-input')" />
        </div>
        <div
          v-if="requestDialogModel.requestSeverityLevelVisible"
          class="u-width-full">
          <label for="severity_level">How serious is the issue?</label>
          <select
            id="severity_level"
            v-model="requestDialogModel.severityLevelValue"
            class="u-width-full"
            :class="testClass('help-request-severity-levels')">
            <option
              v-for="(severityLevel, index) in formattedRequestSeverityLevels"
              :key="index"
              :value="severityLevel.value">
              {{ severityLevel.text }}
            </option>
          </select>
        </div>
        <div
          v-if="requestDialogModel.instructorTextareaVisible"
          :class="testClass('help-request-instructor-text')">
          {{ requestDialogModel.instructorText }}
        </div>
      </template>

      <template #footer>
        <div class="c-button-group  u-mar-0  u-txt-rt">
          <button
            type="button"
            class="c-button  js-modal-a11y__last-focus-element"
            :class="testClass('cancel-help-request')"
            @click.stop="onCloseClick">
            Cancel
          </button>
          <button
            type="button"
            class="c-button  c-button--primary  js-modal-a11y__last-focus-element"
            :class="[
              { 'disabled-button': !requestDialogModel.commentValue },
              testClass('submit-help-request')
            ]"
            :disabled="!requestDialogModel.commentValue"
            @click.stop="onSubmitClick">
            Submit
          </button>
        </div>
      </template>
    </ModalComponent>
  </div>
</template>

<script>
  import { dispatchCustomEvent } from 'shared/utils';
  import { testClass } from 'music';
  import * as ajaxUtils from 'shared/ajax_utils';
  import { nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue';
  import ModalComponent from 'features/modal/ModalComponent';
  import useHelpRequestModalHelper from './use_help_request_modal_helper';
  import accentBarHelper from 'shared/accent_bar_helper';

  const useAddModal = (
    activityId,
    accentBarComponent,
    addMode,
    currentRequest,
    payloadFromRails,
    refModalContainerElm,
    refTextareaElm,
    requestDialogModel,
    sectionId,
    userType,
  ) => {
    const {
      getDefaultModalData,
      getModalData,
      getSubmitFailureMessage,
      getSubmitSuccessMessage,
    } = useHelpRequestModalHelper();

    const {
      attachToAccentBarEvents,
      detachFromAccentBarEvents,
      moveAccentBarBackToActivity,
      moveAccentBarToRequestModal,
    } = accentBarHelper(
      accentBarComponent,
      refModalContainerElm,
      refTextareaElm,
    );

    const showDialog = ({ activityFormData, helpableItemId, helpableItemType, requestMode }) => {
      currentRequest.activityFormData = activityFormData;
      currentRequest.helpableItemId = helpableItemId;
      currentRequest.helpableItemType = helpableItemType;
      currentRequest.requestMode = requestMode;
      const requestDialogData = getModalData(userType, requestMode);
      Object.assign(requestDialogModel, requestDialogData);
      addMode.value = true;

      // When DOM is updated to show comment textbox then register comment text box with
      // accent bar component, bind accent bar events and append accent bar html in modal container
      nextTick(() => {
        if (refTextareaElm.value) {
          moveAccentBarToRequestModal();
          attachToAccentBarEvents(refTextareaElm.value, requestDialogModel, 'commentValue');
        }
      });
    };

    const hideDialog = () => {
      if (refTextareaElm.value) {
        moveAccentBarBackToActivity();
        detachFromAccentBarEvents(refTextareaElm.value);
      }

      addMode.value = false;
      const requestItemElm = document.querySelector(`#${currentRequest.helpableItemId}`);
      dispatchCustomEvent({
        name: 'requestEnded',
        detail: { requestItemElm, requestMode: currentRequest.requestMode },
      });
    };

    const onCloseClick = () => {
      hideDialog();
      setDefaultRequestValues();
    };

    const getSaveRequestParams = () => ({
      activity_form_contents: currentRequest.activityFormData,
      help_request_data: payloadFromRails,
      helpable_item_id: currentRequest.helpableItemId,
      helpable_item_type: currentRequest.helpableItemType,
      request_type: currentRequest.requestMode,
      severity_level: requestDialogModel.severityLevelValue,
      student_comment: requestDialogModel.commentValue,
    });

    const setDefaultRequestValues = () => {
      currentRequest.activityFormData = '';
      currentRequest.helpableItemId = '';
      currentRequest.helpableItemType = '';
      currentRequest.requestMode = 'default';

      Object.assign(requestDialogModel, getDefaultModalData());
    };

    const onSuccess = (data) => {
      hideDialog();
      dispatchCustomEvent({
        name: 'studentRequestAdded',
        detail: { request: data, requestMode: currentRequest.requestMode },
      });
      const successMessage = getSubmitSuccessMessage(currentRequest.requestMode);
      dispatchCustomEvent({
        name: 'showSuccessMsg',
        detail: { text: successMessage },
      });
      setDefaultRequestValues();
    };

    const onError = (data) => {
      const failureMessage = getSubmitFailureMessage(currentRequest.requestMode);
      dispatchCustomEvent({
        name: 'showErrorMsg',
        detail: { text: failureMessage },
      });
    };

    const onSubmitClick = () => {
      const params = getSaveRequestParams();
      const url = `/sections/${sectionId}/activities/${activityId}/help_requests`;
      ajaxUtils.postToEndpoint(
        url,
        params,
        (data) => {
          data.id ? onSuccess(data) : onError(data);
        }
      );
    };

    return {
      onCloseClick,
      onSubmitClick,
      setDefaultRequestValues,
      showDialog,
    };
  };

  export default {
    name: 'AddHelpRequest',
    components: { ModalComponent },
    props: {
      activityId: { required: true, type: Number },

      /** payloadFromRails is json object returned via
      * method format_help_request_data in activities_helper.rb & question_id key
      * It is included in payload when submitting request and as per observation has following keys
      * activity_id: Number
      * activity_state: String
      * cms_activity_id: Number
      * cms_revision_id: Number
      * http_referer: String
      * program_id: Number
      * request_params: { controller: String, action: String, section_id: String, id: String }
      * question_id: String
      * section_id: Number
      * user_id: Array<Number>
      * user_type: String
      */
      payloadFromRails: { required: true, type: Object },
      /**
      * requestSeverityLevels is array used to render severity level options
      * for Reporting Technical problem.
      * It is returned by ruby method severity_levels_array_for_dropdown
      */
      requestSeverityLevels: {
        default: () => [],
        required: false,
        type: Array,
      },
      sectionId: { required: true, type: Number },
      userType: { required: true, type: String },
    },
    // events: triggers following custom events on dom for other vue apps:
    // requestEnded, showErrorMsg, showSuccessMsg, studentRequestAdded
    setup(props) {
      const addMode = ref(false);
      const { activityId, sectionId, requestSeverityLevels, userType, payloadFromRails } = props;
      const refModalContainerElm = ref(null);
      const refTextareaElm = ref(null);
      const accentBarComponent = ref(null);
      const currentRequest = reactive({
        activityFormData: '',
        helpableItemId: '',
        helpableItemType: '',
        requestMode: 'default',
      });
      const requestDialogModel = reactive({
        commentValue: '',
        directionsText: '',
        directionsVisible: true,
        instructorText: '',
        instructorTextareaVisible: false,
        requestSeverityLevelVisible: false,
        requestTextareaVisible: true,
        severityLevelValue: 2,
        submitButtonEnabled: false,
        title: '',
      });

      // convert requestSeverityLevels items from array to meaningful object format
      const formatSeverityLevels = (severityLevels) => {
        return severityLevels?.map((item) => {
          if (item && item.length == 2) {
            return { value: item[1], text: item[0] };
          }
        });
      };
      const formattedRequestSeverityLevels = formatSeverityLevels(requestSeverityLevels);

      const {
        onCloseClick,
        onSubmitClick,
        showDialog,
      } = useAddModal(
        activityId,
        accentBarComponent,
        addMode,
        currentRequest,
        payloadFromRails,
        refModalContainerElm,
        refTextareaElm,
        requestDialogModel,
        sectionId,
        userType
      );

      const onHelpableClick = (event) => {
        if (event) {
          const { activityFormData, helpableItemId, helpableItemType, requestMode } = event.detail;
          showDialog({ activityFormData, helpableItemId, helpableItemType, requestMode });
        }
      };

      onMounted(() => {
        // The modal is shown when helpable_was_chosen event is received
        document.addEventListener('helpable_was_chosen', onHelpableClick);
      });

      onBeforeUnmount(() => {
        document.removeEventListener('helpable_was_chosen', onHelpableClick);
      });

      return {
        addMode,
        currentRequest,
        formattedRequestSeverityLevels,
        onCloseClick,
        onSubmitClick,
        refModalContainerElm,
        refTextareaElm,
        requestDialogModel,
        showDialog,
        testClass,
      };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  ::v-deep .c-modal__box {
    // for l-span-6
    width: 30rem;
  }
  ::v-deep .c-modal__box {
    text-align: left;
  }
  ::v-deep .c-panel__header {
    background-color: $white;
  }
</style>
