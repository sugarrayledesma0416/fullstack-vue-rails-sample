<template>
  <div>
    <h1 v-if="assignmentWizard.store.courseInfo" :class="testClass('course-name')">
      {{ assignmentWizard.store.courseInfo.name }}
    </h1>
    <LearningTrackApp
      :loadingIconPath="loadingIconPath"
      :parentModel="assignmentWizard" />
    <div class="course-setup-controls">
      <div class="next">
        <VhlButton
          variant="primary"
          :class="testClass('assignment-wizard-save')"
          :disabled="!assignmentWizard.store.allDueDates ||
            assignmentWizard.store.allDueDates.length === 0 ||
            assignmentWizard.store.loadingLearningTracks"
          @click="openCategoryMapping">
          Save
        </VhlButton>
      </div>
      <div class="cancel-link-container">
        <VhlLink
          href="javascript://"
          :class="testClass('assignment-wizard-cancel')"
          @click="assignmentWizard.returnToDashboard()">
          Cancel
        </VhlLink>
      </div>
    </div>
    <CategoryMapping
      v-if="assignmentWizard.store.categoryMappingList && localstore.showCategoryMapping"
      :categories="assignmentWizard.store.categories"
      :categoryMappingList="assignmentWizard.store.categoryMappingList"
      :courseInfoCategories="assignmentWizard.store.courseInfo.categories"
      :usingPredefinedTrack="assignmentWizard.store.usingPredefinedTrack"
      @close="closeCategoryMapping"
      @save="saveCourseHandler" />
    <SaveCourseModal
      v-if="assignmentWizard.jobProgress.shouldShow"
      :parentModel="assignmentWizard" />
  </div>
</template>

<script>
  import { provide, reactive } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import { testClass } from 'music';
  import AssignmentCalendar from 'features/learning_tracks/models/assignment_calendar';
  import CategoryMapping from './components/CategoryMapping';
  import SaveCourseModal from './components/SaveCourseModal';
  import LearningTrackApp from 'features/learning_tracks/LearningTrackApp';
  import AssignmentWizard from './models/assignment_wizard';
  import VhlButton from 'features/learning_tracks/components/VhlButton';
  import VhlLink from 'features/learning_tracks/components/VhlLink';

  /**
   * @typeDef {LocalstoreObject}
   * @type {Object}
   * @property {boolean} showCategoryMapping - whether to show category mapping
   * modal.
   */

  /**
   * @typeDef {AssignmentWizardObject}
   * @type {Object}
   * @property {Function} create - function to create assignments.
   */

  /**
   * This composable has methods for Assignment Wizard App.
   * @param {LocalstoreObject} localstore - Vue js reactive object to store app state.
   * @param {AssignmentWizardObject} assignmentWizard - Vue js reactive object to store
   * assignmentWizard model state.
   * @return {Object}
   */
  function useAssignmentWizardApp(localstore, assignmentWizard) {
    /**
     * Handler to close category mapping modal.
     */
    function closeCategoryMapping() {
      localstore.showCategoryMapping = false;
    }

    /**
     * Handler to open category mapping modal.
     */
    function openCategoryMapping() {
      localstore.showCategoryMapping = true;
    }

    /**
     * Handler to save course data.
     */
    function saveCourseHandler() {
      closeCategoryMapping();
      assignmentWizard.create();
    }

    return { closeCategoryMapping, openCategoryMapping, saveCourseHandler };
  }

  export default {
    name: 'AssignmentWizardApp',
    components: { CategoryMapping, LearningTrackApp, SaveCourseModal, VhlButton, VhlLink },
    props: {
      loadingIconPath: { required: true, type: String },
    },
    setup(props) {
      const config = {
        instAdmin: metaTagContent('VHL.in_institution_admin') === 'true',
        programId: metaTagContent('VHL.program_id'),
      };
      const assignmentCalendar = new AssignmentCalendar();
      const assignmentWizard = new AssignmentWizard(assignmentCalendar);
      const localstore = reactive({
        showCategoryMapping: false,
      });

      const {
        closeCategoryMapping, openCategoryMapping, saveCourseHandler,
      } = useAssignmentWizardApp(localstore, assignmentWizard);

      provide('assignmentCalendar', assignmentCalendar);
      provide('config', config);

      return {
        closeCategoryMapping,
        config,
        localstore,
        assignmentWizard,
        openCategoryMapping,
        testClass,
        saveCourseHandler,
      };
    },
  };
</script>

<style scoped>
  .course-setup-controls {
    border-top: 0.1875rem solid #ccc;
    clear: both;
    margin-top: 2rem;
    overflow: hidden;
    padding: 0.25rem;
  }

  .course-setup-controls .next {
    margin-bottom: 0.5rem;
    margin-top: 0.5rem;
    float: right;
  }

  .cancel-link-container {
    margin-top: 0.9375rem;
  }

</style>
