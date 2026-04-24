<template>
  <div>
    <div
      v-for="request in requests"
      :key="request.id"
      class="c-help-request-container  js-help-request-container"
      :class="[request.request_type, testClass('help-request-container')]"
      data-content-type="help_request"
      :data-helpable-id="request.helpable_item_id">
      <span class="u-screen-reader-only">Help request container</span>
      <div>
        <div class="u-txt-bold" aria-labelledby="a11y-audio-note">
          <span aria-hidden="true" :class="testClass('student-name')">
            {{ request.student_name }}
          </span>
          <span id="a11y-audio-note" class="u-screen-reader-only">
            {{ request.student_name }} commented on
          </span>
        </div>
        <span data-content-type="request_submitted_date">
          {{ new ZonedDateTime(request.created_at).formattedDate() }}
        </span>
        <span class="u-mar-lt-5  u-txt-ital" data-content-type="request_submitted_date">
          {{ new ZonedDateTime(request.created_at).formattedTime() }}
        </span>
        <div
          class="u-pad-top-10  u-pad-bot-10"
          :class="testClass('student-comment-text')"
          data-content-type="student_comment_text"
          v-html="processChineseText(request.student_comment)">
        </div>
      </div>
      <div
        v-if="request.request_type !== 'report_technical_problem'"
        class="c-instructor_response_container">
        <div
          v-show="!requestsBeingEdited[request.id]"
          :class="`js-edit-section-${request.id}`">
          <div class="u-txt-bold" aria-labelledby="a11y-instructor-name">
            <span aria-hidden="true" :class="testClass('instructor-name')">
              {{ request.instructor_name }}
            </span>
            <span id="a11y-instructor-name" class="u-screen-reader-only">
              {{ request.instructor_name }} commented on
            </span>
          </div>
          <span data-content-type="request_responded_date">
            {{ new ZonedDateTime(request.processed_at).formattedDate() }}
          </span>
          <span class="u-mar-lt-5  u-txt-ital" data-content-type="request_responded_date">
            {{ new ZonedDateTime(request.processed_at).formattedTime() }}
          </span>
          <div
            class="u-pad-top-10  u-pad-bot-10"
            data-content-type="instructor_comment_text"
            :class="testClass('instructor-comment-text')"
            v-html="processChineseText(request.instructor_comment)">
          </div>

          <div class="u-txt-rt">
            <button
              type="button"
              class="c-no-button  c-edit-request"
              :class="`js-edit-request-${request.id}`"
              @click="onEditClick(request)">
              EDIT
            </button>
          </div>
        </div>
        <div
          v-show="requestsBeingEdited[request.id]"
          class="c-instructor-comment-area"
          :class="`js-instructor-comment-area-${request.id}`">
          <label for="instructor_comment">Comment</label>
          <div id="a11y-error-button" class="u-txt-red  js-error-message" />
          <textarea
            :ref="el => { respondTexts[request.id] = el }"
            name="instructor_comment"
            rows="4"
            cols="50"
            class="u-width-full  u-pad-2"
            aria-label="Textbox to edit comment"
            @input="onCommentChange(request)" />
          <div class="u-txt-rt">
            <input
              :ref="el => { respondBtns[request.id] = el }"
              class="c-button  c-button--primary  u-mar-top-6"
              name="commit"
              type="button"
              value="Respond"
              disabled="true"
              @click="onRespondClick(request)">
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { reactive, inject, onMounted, ref } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import { dispatchCustomEvent, processChineseText } from 'shared/utils';
  import { testClass } from 'music';
  import ZonedDateTime from 'shared/zoned_date_time';

  const useInstructorDisclosure = (
    helpableItemId, metaData, requests, requestsBeingEdited, respondBtns, respondTexts
  ) => {
    const initializeDisclosure = () => {
      editAndCommentVisibility();
      const disclosureElmContainer = document.querySelector(
        `.js-help-disclosure-${metaData.userType}-${helpableItemId}`
      );
      const disclosureElm = new VHL.Music.V1.Disclosure(disclosureElmContainer);
      if (metaData.userType === 'Student') {
        disclosureElm.toggle();
        disclosureElm.$header.toggleClass('is-collapsed');
      }
    };

    const onCommentChange = (request) => {
      if (event.target.value === '') {
        respondBtns.value[request.id].disabled = true;
      } else {
        respondBtns.value[request.id].disabled = false;
      }
    };

    const onEditClick = (request) => {
      requestsBeingEdited[request.id] = true;
    };

    const onRespondClick = (request) => {
      request.instructor_comment = respondTexts.value[request.id].value;
      request.status = 'responded';
      const url = `/instructor/${metaData.programId}/activity/` +
        `${metaData.activityId}/activity_help_requests/${request.id}`;
      ajaxUtils.putToEndpoint(
        url,
        request,
        (data) => {
          if (data.status === 'submitted' || data.status === 'responded') {
            requests[requests.indexOf(request)] = data;
            onRespondSuccess(request);
          } else {
            onDeleteError(request);
          }
        }
      );
    };

    const onRespondSuccess = (request) => {
      let message = "";
      switch(request.request_type){
        case 'request_review':
              message = 'Review request';
              break;
        default: // apply to request_help as well.
              message = 'Help request';
      }
      requestsBeingEdited[request.id] = false;
      dispatchCustomEvent({
        name: 'showSuccessMsg',
        detail: { text: `${message} successfully ${request.status}!` },
      });
    };

    const onDeleteError = (request) => {
      dispatchCustomEvent({
        name: 'showErrorMsg',
        detail: { text: 'Instructor Response Failed!.' },
      });
    };

    const editAndCommentVisibility = () => {
      for (const request of requests) {
        if (!request.instructor_comment) {
          requestsBeingEdited[request.id] = true;
        } else {
          requestsBeingEdited[request.id] = false;
        }
      }
    };

    return {
      initializeDisclosure, onCommentChange, onRespondClick, onEditClick,
    };
  };
  export default {
    name: 'InstructorHelpResponse',
    components: {},
    props: {
      helpableItemId: {
        type: String,
        default: '',
      },
    },
    setup(props) {
      const { helpableItemId } = props;
      const metaData = inject('metaData');
      const requestsBeingEdited = reactive({});
      let requests = inject('requests');
      const respondBtns = ref([]);
      const respondTexts = ref([]);

      const {
        initializeDisclosure, onCommentChange, onRespondClick, onEditClick,
      } = useInstructorDisclosure(
        helpableItemId, metaData, requests, requestsBeingEdited, respondBtns, respondTexts
      );

      onMounted(initializeDisclosure);

      return {
        metaData, requests, testClass, onCommentChange, onRespondClick,
        onEditClick, requestsBeingEdited, respondBtns, respondTexts,
        processChineseText, ZonedDateTime,
      };
    },
  };
</script>
