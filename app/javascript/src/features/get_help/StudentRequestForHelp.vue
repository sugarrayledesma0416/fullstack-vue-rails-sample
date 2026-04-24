<template>
  <div>
    <div
      v-for="request in requests"
      :key="request.id"
      class="c-help-request-container"
      :class="[request.request_type, testClass('help-request-container')]"
      data-content-type="help_request"
      :data-helpable-id="request.helpable_item_id">
      <span class="u-screen-reader-only">
        Help request container
      </span>
      <div>
        <div class="u-txt-bold" :class="testClass('student-name')">
          Me
        </div>
        <span data-content-type="request_submitted_date">
          {{ new ZonedDateTime(request.created_at).formattedDate() }}
        </span>
        <span
          class="u-mar-lt-5  u-txt-ital"
          data-content-type="request_submitted_date">
          {{ new ZonedDateTime(request.created_at).formattedTime() }}
        </span>
        <div
          class="u-pad-top-12"
          data-content-type="student_comment_text"
          :class="testClass('student-comment-text')"
          v-html="processChineseText(request.student_comment)">
        </div>
        <div class="u-txt-rt">
          <span data-content-type="request_status" class="request_status hidden_helper submitted" />
          <button
            v-if="request.instructor_comment === null"
            type="button"
            class="c-no-button  c-remove-request"
            :class="testClass('remove-request')"
            data-content-type="request_cancel_link"
            title="Cancel the request"
            @click="onRemoveClick(request)">
            Remove
          </button>
        </div>
      </div>

      <div
        v-if="request.instructor_comment !== null"
        class="c-instructor_response_container  u-pad-top-8">
        <div class="u-txt-bold">
          {{ request.instructor_name }}
        </div>
        <span data-content-type="request_responded_date">
          {{ new ZonedDateTime(request.processed_at).formattedDate() }}
        </span>
        <span class="u-mar-lt-5  u-txt-ital" data-content-type="request_responded_date">
          {{ new ZonedDateTime(request.processed_at).formattedTime() }}
        </span>
        <div 
          class="u-pad-top-12" 
          data-content-type="instructor_comment_text" 
          :class="testClass('instructor-comment-text')"
          v-html="processChineseText(request.instructor_comment)">
        </div>
      </div>
    </div>
  </div>
</template>

<script>
  import { inject, onMounted } from 'vue';
  import * as ajaxUtils from 'shared/ajax_utils';
  import { dispatchCustomEvent, processChineseText } from 'shared/utils';
  import { testClass } from 'music';
  import { filterRequestProperties } from './utils';
  import ZonedDateTime from 'shared/zoned_date_time';

  const useStudentDisclosure = (helpableItemId, metaData, requests, emit) => {
    const initializeDisclosure = () => {
      const disclosureElmContainer = document.querySelector(
        `.js-help-disclosure-${metaData.userType}-${helpableItemId}`
      );
      const disclosureElm = new VHL.Music.V1.Disclosure(disclosureElmContainer);
      if (metaData.userType === 'Student') {
        disclosureElm.toggle();
      }
    };

    const onRemoveClick = (request) => {
      const url = `/sections/${metaData.sectionId}/activities/${metaData.activityId}` +
        `/help_requests/${request.id}`;
      ajaxUtils.deleteFromEndpoint(
        url,
        (data) => {
          data.status === 200 ? onDeleteSuccess(request) : onDeleteError(request);
        }
      );
    };

    const onDeleteSuccess = (request) => {
      const requestType = request.request_type === 'request_review' ? 'Review' : 'Help';
      requests.splice(requests.indexOf(request), 1);
      if (requests.length == 0) {
        dispatchCustomEvent({
          name: 'allRequestsRemoved',
          detail: {
            request: request,
            helpableItemId: helpableItemId,
          },
        });
      }
      dispatchCustomEvent({
        name: 'showSuccessMsg',
        detail: { text: `${requestType} request successfully deleted!` },
      });
    };

    const onDeleteError = (request) => {
      dispatchCustomEvent({
        name: 'showErrorMsg',
        detail: { text: 'Note removal error! ' },
      });
    };

    const onNewRequestAdded = (evt) => {
      const rawRequest = evt.detail.request;
      if (['request_help', 'request_review'].includes(rawRequest.request_type)) {
        // Comparing new created request's helpable id with the vue app's helpableItemId.
        if (rawRequest.helpable_item_id === helpableItemId) {
          // Fetching subset of Object's(rawRequest) properties
          const newRequest = filterRequestProperties(rawRequest);

          requests.push(newRequest);
          if (requests.length === 1) {
            emit('firstReqAdded', newRequest);
          }
        }
      }
    };

    return {
      initializeDisclosure, onRemoveClick, onNewRequestAdded,
    };
  };
  export default {
    name: 'StudentRequestForHelp',
    components: {},
    props: {
      helpableItemId: {
        type: String,
        default: '',
      },
    },
    emits: ['deleted', 'firstReqAdded'],
    setup(props, { emit }) {
      const { helpableItemId } = props;
      const metaData = inject('metaData');
      const requests = inject('requests');

      const {
        initializeDisclosure, onRemoveClick, onNewRequestAdded,
      } = useStudentDisclosure(helpableItemId, metaData, requests, emit);

      onMounted(() => {
        initializeDisclosure();
        document.addEventListener('studentRequestAdded', onNewRequestAdded);
      });

      return {
        metaData, requests, onRemoveClick, testClass,
        processChineseText, ZonedDateTime,
      };
    },
  };
</script>
