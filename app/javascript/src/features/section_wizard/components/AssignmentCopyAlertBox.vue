<template>
  <!-- Referred html structure from layouts/flash_layout.html.erb -->
  <div
    v-if="localStore.showFlashBanner"
    class="c-flash-banner  c-flash-banner--warning  due-dates-message  u-z-1  l-span-5  u-pos-abs"
    :class="testClass('flash-warning')"
    role="alert">
    <a
      class="c-flash-banner__close-link"
      :class="testClass('flash-banner-close-link')"
      href="javascript://"
      @click="closeFlashBanner">
      <span class="u-screen-reader-only">Close</span>
      <span aria-hidden="true">&times;</span>
    </a>

    <div class="l-media">
      <div class="l-media__img">
        <span class="c-flash-banner__icon  c-flash-banner__icon--warning" />
        <span class="u-screen-reader-only">warning</span>
      </div>

      <div class="l-media__body">
        <span class="u-txt-gray-3">
          All assignments, due dates and assessment details will be copied from section
          <span class="from-section-name  u-txt-bold">
            {{ localStore.dueDatesSectionName }}
          </span>.
          <span
            v-if="localStore.showPastDueCount"
            class="from-section-past-due-count"
            :class="testClass('due-dates-message')">
            {{ localStore.dueDatesMessage }}
          </span>
        </span>
      </div>
    </div> <!-- / l-media -->
  </div> <!-- / c-flash-banner -->
</template>

<script>
  import { computed, inject, reactive, watch } from 'vue';
  import { testClass } from 'music';

  /**
   * This composable has methods for AssignmentCopyAlertBox.
   * @param {Object} datastore - Vue js reactive object to store app state
   * @param {Object} localStore - Vue js reactive object to store app state for this component
   * @return {Object} - An object wrapping following methods
   * closeFlashBanner,
   * showFlashBannerForAssignmentCopySectionId,
   */
  const useAssignmentCopyAlertBox = (datastore, localStore) => {
    /**
     * Close the flash banner
     */
    function closeFlashBanner() {
      localStore.showFlashBanner = false;
    }

    /**
     * Display AssignmentCopyAlertBox and due dates message
     * if assignments have due dates already in the past.
     * @param {number} newValue - New value of section.assignmentCopySectionId in datastore
     */
    function showFlashBannerForAssignmentCopySectionId(newValue) {
      if (newValue !== undefined) {
        // Get previous section corresponding to new value of assignmentCopySectionId
        const prevSection = datastore.section?.previousSections?.find(
          (previousSection) => previousSection.id === newValue
        );
        if (prevSection) {
          showFlashBannerForPreviousSection(prevSection);
          // Update flag in datastore
          datastore.section.copySectionHasExternalAssignments = prevSection.hasExternalAssignments;
        } else {
          localStore.showFlashBanner = false;
          // Update flag in datastore
          datastore.section.copySectionHasExternalAssignments = false;
        }
      }
    }

    /**
     * @private
     * Display AssignmentCopyAlertBox and due dates message
     * if assignments have due dates already in the past.
     * @param {Section} previousSection - Previous section corresponding to
     * new value of assignmentCopySectionId
     */
    function showFlashBannerForPreviousSection(previousSection) {
      localStore.showFlashBanner = true;
      localStore.dueDatesSectionName = previousSection.name;
      if (previousSection.assignmentPastDueCount > 0) {
        localStore.showPastDueCount = true;
        localStore.dueDatesMessage = `${previousSection.assignmentPastDueCount}` +
          ' assignments have due dates already in the past.';
      } else {
        localStore.showPastDueCount = false;
      }
    }

    return { closeFlashBanner, showFlashBannerForAssignmentCopySectionId };
  };

  export default {
    name: 'AssignmentCopyAlertBox',
    setup(props) {
      const localStore = reactive({
        dueDatesMessage: '',
        dueDatesSectionName: '',
        showFlashBanner: false,
        showPastDueCount: false,
      });
      const datastore = inject('datastore');

      /**
       * Computed reactive property for assignmentCopySectionId in datastore
       */
      const assignmentCopySectionId = computed(() => datastore.section?.assignmentCopySectionId);

      const {
        closeFlashBanner,
        showFlashBannerForAssignmentCopySectionId,
      } = useAssignmentCopyAlertBox(datastore, localStore);

      watch(assignmentCopySectionId, showFlashBannerForAssignmentCopySectionId);

      return { closeFlashBanner, localStore, testClass };
    },
  };
</script>
