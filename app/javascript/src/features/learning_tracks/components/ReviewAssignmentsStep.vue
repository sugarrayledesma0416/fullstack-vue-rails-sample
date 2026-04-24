<template>
  <ReviewAssignments :key="reviewComponentKey" :loadingIconPath="loadingIconPath" />
  <ModalComponent
    v-if="localStore.showWarnAboutChangesModal"
    ref="refWarnAboutChangesModal"
    title="Attention"
    :class="testClass('warn-about-changes-modal')"
    @close="hideWarnAboutChangesModal">
    <template #body>
      <p>
        Further changes to Steps 1-3 will undo the edits made to
        assignment distribution in Step 4.
      </p>
    </template>
  </ModalComponent>
  <ModalComponent
    v-if="localStore.showGroupMenuModal"
    ref="refGroupMenuModal"
    :title="localStore.groupMenuModalTitle"
    :class="testClass('group-menu-modal')"
    @close="hideGroupMenuModal">
    <template #body>
      <GroupMenu @close="hideGroupMenuModal" />
    </template>
  </ModalComponent>
</template>

<script>
  import { inject, onMounted, reactive } from 'vue';
  import { testClass } from 'music';
  import GroupMenu from './GroupMenu';
  import ModalComponent from 'features/modal/ModalComponent';
  import ReviewAssignments from './ReviewAssignments';
  export default {
    name: 'ReviewAssignmentsStep',
    components: { GroupMenu, ModalComponent, ReviewAssignments },
    props: {
      loadingIconPath: { required: true, type: String },
    },
    setup() {
      const localStore = reactive({
        groupMenuModalTitle: '',
        pendingWarnAboutChanges: false,
        showGroupMenuModal: false,
        showWarnAboutChangesModal: false,
      });
      const learningTrackData = inject('learningTrackData');
      const reviewComponentKey = inject('reviewComponentKey');

      /**
       * Hide hideGroupMenu Modal and show WarnAboutChanges Modal if required
       */
      function hideGroupMenuModal() {
        localStore.showGroupMenuModal = false;
        localStore.groupMenuModalTitle = '';
        showChangesWarning();
      }

      /**
       * Hide warning about changes
       */
      function hideWarnAboutChangesModal() {
        localStore.showWarnAboutChangesModal = false;
      }

      /**
       * Show WarnAboutChanges Modal after
       * closing GroupMenu Modal if some changes are done.
       */
      function showChangesWarning() {
        if (localStore.pendingWarnAboutChanges) {
          localStore.pendingWarnAboutChanges = false;
          localStore.showWarnAboutChangesModal = true;
        }
      }

      /**
       * Calculate and update calendar workload information in the model.
       */
      function updateCalendarWorkload() {
        const workLoad = learningTrackData.parentModel.assignmentCalendar.calculateWorkLoad(
          learningTrackData.parentDataStore.calendar.calendar
        );
        learningTrackData.parentDataStore.calendar.workLoad = workLoad;
      }

      onMounted(() => {
        /**
         * Build data and open GroupMenu modal on event 'openGroupMenu'
         */
        document.addEventListener(
          'openGroupMenu',
          (event) => {
            const calendar = learningTrackData.parentDataStore.calendar.calendar;
            learningTrackData.groupMenu.buildDataToOpenGroupMenu(calendar, event);
            localStore.groupMenuModalTitle = learningTrackData.groupMenu.getGroupMenuDialogTitle();
            localStore.showGroupMenuModal = true;
          }
        );

        /**
         * On 'assignmentShifted' event, set flag to show WarnABoutChanges modal
         */
        document.addEventListener(
          'assignmentShifted',
          () => {
            localStore.pendingWarnAboutChanges = true;
            updateCalendarWorkload();
            // Change counter to refresh graphs
            reviewComponentKey.value += 1;
          }
        );
      });

      return {
        hideGroupMenuModal,
        hideWarnAboutChangesModal,
        learningTrackData,
        localStore,
        reviewComponentKey,
        testClass,
      };
    },
  };
</script>
