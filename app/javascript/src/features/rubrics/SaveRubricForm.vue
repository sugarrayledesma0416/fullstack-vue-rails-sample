<template>
  <div class="js-activity-footer-wrap">
    <div
      id="activityFooter"
      class="l-inline-group  activity_action  activity_actions">
      <form ref="activitySubmitForm" :action="submitUrl" method="POST">
        <input
          type="hidden"
          name="_method"
          value="PUT">
        <input type="hidden" name="authenticity_token" :value="activity.csrfToken">
        <input
          v-once
          ref="rubricJsonField"
          type="hidden"
          name="instructor_created_activity[rubric_json]"
          value="">
        <input
          type="hidden"
          name="instructor_created_activity[draft]"
          :class="testClass('draft-field')"
          :value="activity.state.draft">
        <input
          ref="saveActionField"
          type="hidden"
          name="instructor_created_activity[save_action]"
          :class="testClass('save-action-field')"
          value="save">
        <div
          class="c-box  c-box--bubble-wrap  activity_action  activity_actions
                 u-mar-lt-12  u-pad-rt-12  u-mar-bot-0">
          <!-- eslint-disable vue/no-v-html -->
          <button
            class="c-button"
            :class="testClass('activity-save-button')"
            @click.prevent="openSaveChangesModal"
            v-html="icons.mediumSave" />
          <!-- eslint-enable vue/no-v-html -->

          <div
            v-show="localState.showSaveChangesModal"
            class="c-modal  c-modal--md"
            :class="testClass('save-changes-modal')">
            <div role="dialog" aria-label="Dialog with a panel" class="c-modal__box">
              <button
                class="c-modal__close-button  c-no-button"
                :class="testClass('close-save-changes-modal-button')"
                @click="closeSaveChangesModal">
                <span class="c-icon  c-icon--md  c-icon--close" />
                <span class="u-screen-reader-only">Close dialog</span>
              </button>
              <div role="document">
                <div class="c-panel  c-panel--padded  u-mar-80">
                  <div class="c-panel__header">
                    <h3 class="c-heading--modal">
                      Save Rubric
                    </h3>
                  </div>
                  <div class="c-panel__body">
                    <p>
                      SAVE AS DRAFT to continue working on the activity.
                      SAVE to make the activity available for the course.
                    </p>
                  </div>
                  <div class="c-panel__footer">
                    <div class="c-button-group  u-mar-0  u-txt-rt">
                      <button
                        type="button"
                        :class="testClass('cancel-save-changes-modal-button')"
                        class="c-button"
                        @click="closeSaveChangesModal">
                        Cancel
                      </button>
                      <button
                        v-if="showDraftButton"
                        class="c-button  c-button--border  u-pad-lt-4  u-pad-rt-4
                        u-txt-upper  u-txt-14"
                        :class="testClass('activity-save-draft-button')"
                        @click="attemptSaveAndSubmit($event, true, 'save')">
                        <span>Save as Draft</span>
                      </button>
                      <button
                        class="c-button  c-button--primary  u-pad-lt-4  u-pad-rt-4
                        u-txt-upper  u-txt-14"
                        :class="testClass('activity-save-and-share-button')"
                        @click="attemptSaveAndSubmit($event, false, 'save')">
                        <span>Save</span>
                      </button>
                    </div>
                  </div>
                </div>
              </div>
              <button class="u-screen-reader-only" tabindex="-1">
                Dialog end
              </button>
            </div>
          </div>
        </div>
      </form>

      <div
        class="c-box  c-box--bubble-wrap  activity_action
                   activity_actions  u-pad-rt-0  u-mar-bot-0">
        <ExitForm
          :checkUnsavedChanges="true"
          :returnUrl="returnUrl"
          :classes="testClass('exit-button')" />
        <div
          v-show="localState.showUnsavedChangesModal"
          class="c-modal  c-modal--md"
          :class="testClass('unsaved-changes-modal')">
          <div role="dialog" aria-label="Dialog with a panel" class="c-modal__box">
            <button
              class="c-modal__close-button  c-no-button"
              :class="testClass('close-unsaved-changes-modal-button')"
              @click="closeUnsavedChangesModal">
              <span class="c-icon  c-icon--md  c-icon--close" />
              <span class="u-screen-reader-only">Close dialog</span>
            </button>
            <div role="document">
              <div class="c-panel  c-panel--padded  u-mar-80">
                <div class="c-panel__header">
                  <h3 class="c-heading--modal">
                    Exit Rubric Editing
                  </h3>
                </div>
                <div class="c-panel__body">
                  <p>
                    Are you sure you want to stop editing this
                    rubric? Progress won't be saved unless you
                    choose "Save".
                  </p>
                </div>
                <div class="c-panel__footer">
                  <div class="c-button-group  u-mar-0  u-txt-rt">
                    <button
                      type="button"
                      :class="testClass('cancel-unsaved-changes-modal-button')"
                      class="c-button"
                      @click="closeUnsavedChangesModal">
                      Cancel
                    </button>
                    <button
                      v-show="showDraftButton"
                      class="c-button  c-button--border u-pad-lt-4  u-pad-rt-4
                             u-txt-upper  u-txt-14"
                      :class="testClass('activity-save-draft-and-exit-button')"
                      @click="attemptSaveAndSubmit($event, true, 'exit')">
                      <span>Save as Draft</span>
                    </button>
                    <button
                      class="c-button  c-button--border u-pad-lt-4  u-pad-rt-4
                             u-txt-upper  u-txt-14"
                      :class="testClass('activity-save-and-exit-button')"
                      @click="attemptSaveAndSubmit($event, false, 'exit')">
                      <span>Save</span>
                    </button>
                    <ExitForm :returnUrl="returnUrl" classes="c-button--primary  u-pad-8" />
                  </div>
                </div>
              </div>
            </div>
            <button class="u-screen-reader-only" tabindex="-1">
              Dialog end
            </button>
          </div>
        </div> <!-- c-modal -->
      </div>
    </div>
  </div> <!-- js-activity-footer-wrap  -->
</template>

<script>
  import { computed, inject, nextTick, provide, reactive, ref } from 'vue';
  import { testClass } from 'music';
  import ExitForm from './ExitForm';

  export default {
    name: 'SaveActivityForm',
    components: { ExitForm },
    props: {
      activityId: { default: '', type: String },
      returnUrl: { type: String, required: true },
      submitUrl: { type: String, required: true },
    },
    setup(props) {
      const rubricJsonField = ref(null);
      const saveActionField = ref(null);
      const activitySubmitForm = ref(null);
      const activity = inject('activity');
      const rubric = inject('rubric');
      const icons = inject('icons');

      const localState = reactive(
        {
          showUnsavedChangesModal: false,
          showSaveChangesModal: false,
        }
      );

      /**
       * Close the unsaved changes modal
       */
      function closeUnsavedChangesModal() {
        localState.showUnsavedChangesModal = false;
      }

      /**
       * Detect if there are unsaved changes. If so, prevent the default
       * action (submitting the form) and show the unsaved changes warning.
       * @param {Event} event - click event from Exit button.
       */
      function exitUnlessUnsavedChanges(event) {
        if (rubric.hasChanges) {
          localState.showUnsavedChangesModal = true;
          event.preventDefault();
        }
      }

      provide('exitUnlessUnsavedChanges', exitUnlessUnsavedChanges);

      /**
       * Set the value of the field referenced by a Vue.js ref.
       * @param {Object} fieldRef - Vue.js ref pointing to hidden field.
       * @param {string} value
       */
      function setFieldValue(fieldRef, value) {
        // Calling .value.value because the first .value gets the value of
        // the ref. The second, the value attribute of the hidden field.
        fieldRef.value.value = value;
      }

      /**
       * If validations pass, set the contents of the rubricJson hidden field
       * to the JSON string of the current rubric content.
       * Set the value of the hidden saveActionField to 'save'
       * @param {Event} event - click event from the Save button
       * @return {boolean} False if not valid, otherwise true.
       */
      function saveIfValid(event) {
        if (!rubric.isValid()) {
          event.preventDefault();
          return false;
        }
        setFieldValue(saveActionField, 'save');
        setFieldValue(rubricJsonField, JSON.stringify(rubric.content));
        return true;
      }

      /**
       * If validations pass, set the contents of the rubricJson hidden field
       * to the JSON string of the current rubric content.
       * Set the value of the hidden draft field to the passed value.
       * Set the value of the hidden saveActionField to the passed value.
       * @param {Event} event - click event from the Save and Exit button
       * @param {boolean} draft - Whether to mark the assessment as a draft
       * @param {string} saveAction - 'save' or 'exit'
       */
      async function attemptSaveAndSubmit(event, draft, saveAction) {
        const saveSuccessful = saveIfValid(event);
        if (saveSuccessful) {
          activity.state.draft = draft;
          // The value of a hidden form field is bound to activity.state.draft.
          // Without this nextTick, the form gets submitted before the value
          // of the hidden field gets updated, and the wrong value is submitted.
          setFieldValue(saveActionField, saveAction);
          await nextTick();
          activitySubmitForm.value.submit();
        }
      }

      /**
       * If assessment is new or is a draft, we want to show the "Save As Draft"
       * button. If assessment is not a draft, aka already shared, then
       * we do not allow the instructor to save as draft again.
       * @return {boolean} true if draft is true or is nil, otherwise false
       */
      const showDraftButton = computed(
        () => activity.state.draft !== false
      );

      /**
       * Open the save changes modal
       */
      function openSaveChangesModal() {
        localState.showSaveChangesModal = true;
      }

      /**
       * Close the save changes modal
       */
      function closeSaveChangesModal() {
        localState.showSaveChangesModal = false;
      }

      return {
        activity,
        activitySubmitForm,
        attemptSaveAndSubmit,
        closeSaveChangesModal,
        closeUnsavedChangesModal,
        rubricJsonField,
        icons,
        localState,
        openSaveChangesModal,
        saveActionField,
        saveIfValid,
        showDraftButton,
        testClass,
      };
    },
  };
</script>

