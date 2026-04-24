<template>
  <ModalComponent
    v-if="store.state.activityIdBeingEdited"
    title="Change Assignment Status"
    @close="stopEditing">
    <template #body>
      <div class="c-form-item">
        <label
          class="c-form-item__label"
          for="assignable_dropdown">
          Assign to
        </label>
        <select
          id="assignable_dropdown"
          ref="assignableMenu"
          class="c-select">
          <option
            :selected="!individuallyAssignable"
            value="false">
            Entire Section
          </option>
          <option
            :selected="individuallyAssignable"
            value="true">
            Individual Students
          </option>
        </select>
      </div>
      <p class="l-span-6  u-mar-top-24">
        Selecting <span class="u-txt-upper">Entire Section</span>
        assigns this activity to all current and future students
        who enroll in this course section.
      </p>
    </template>

    <template #footer>
      <div class="c-button-group  u-mar-0  u-txt-rt">
        <button
          class="c-button"
          type="button"
          :class="testClass('cancel-state-editing')"
          @click="stopEditing">
          Cancel
        </button>
        <button
          class="c-button  c-button--primary"
          type="button"
          :class="testClass('save-state-changes')"
          @click="saveChanges">
          Save
        </button>
      </div>
    </template>
  </ModalComponent>
</template>

<script>
  import { computed, inject, ref } from 'vue';
  import ModalComponent from 'features/modal/ModalComponent';
  import { testClass } from 'music';
  import * as ajaxUtils from 'shared/ajax_utils';

  export default {
    name: 'StateEditingModal',
    components: { ModalComponent },
    props: {
      programId: { required: true, type: String },
    },
    setup(props) {
      const assignableMenu = ref(null);
      const store = inject('store');

      const assignment = computed(
        () => {
          return store.activityEntries.find(
            (header) => {
              return header.assignable_id === store.state.activityIdBeingEdited;
            }
          );
        }
      );

      const individuallyAssignable = computed(
        () => assignment.value?.individually_assignable
      );

      /**
       * Updates the assignment state.
       */
      function saveChanges() {
        // .value.value because assignableMenu is a ref, so the first
        // .value gets the current HTMLElement the ref is pointing to,
        // and the second gets the actual form value.
        // The value from the form is a string, so need to convert it
        // to a boolean.
        const newValue = assignableMenu.value.value === 'true';
        putAssignmentState(newValue);

        /**
         * If the assignment is changing to be assigned to the whole section,
         * uncheck all of the individual assignments and null out any custom
         * due dates. This is to bring the front end in sync with the back end,
         * where the existing individual-assignment records are destroyed.
         */
        if (!newValue) {
          const activityId = assignment.value.assignable_id;

          store.uncheckAll(activityId);
        }
        stopEditing();
      }

      /**
       * Clears the current activity being edited.
       */
      function stopEditing() {
        store.state.activityIdBeingEdited = null;
      }

      /**
       * @private
       * @param {number} activityId - Activity id of current assignment.
       * @return {string} URL for ajax PUT call.
       */
      function endpointUrl(activityId) {
        return `/instructor/${props.programId}/individual_assignments/${activityId}`;
      }

      /**
       * @private
       * Updates assignment for current section and activity with the new
       * individually-assignable state based on the value of the modal
       * dropdown.
       * @param {boolean} newValue - New value for individually_assignable attr
       */
      async function putAssignmentState(newValue) {
        const activityId = assignment.value.assignable_id;

        ajaxUtils.putToEndpoint(
          endpointUrl(activityId),
          { individually_assignable: newValue },
          () => store.updateAssignableState(activityId, newValue)
        );
      }

      return {
        assignableMenu,
        individuallyAssignable,
        saveChanges,
        stopEditing,
        store,
        testClass,
      };
    },
  };
</script>
