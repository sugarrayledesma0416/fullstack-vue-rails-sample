<template>
  <div class="edit-course-app">
    <FlashMessages
      :flashError="courseDataStore.store.errorMessage"
      :flashNotice="courseDataStore.store.flashNotice"
      :showError="courseDataStore.flashMessageState.showError"
      :showNotice="courseDataStore.flashMessageState.showNotice" />

    <div class="edit-course__tabs">
      <EditCourseTabs />
    </div>

    <div
      v-if="courseDataStore.hasFailedValidations"
      class="u-mar-bot-24">
      <FormFeedback />
    </div>

    <form novalidate name="course_form">
      <div v-if="courseDataStore.store.loadingOptions" class="loader-img-wrap">
        <img
          :src="loadingIconPath"
          alt="Content loading"
          class="loader-img">
      </div>
      <!-- router-vue to host step specific components -->
      <router-view v-else :loadingIconPath="loadingIconPath" />
    </form>
  </div>
</template>

<script>
  import { provide } from 'vue';
  import { testClass } from 'music';
  import { metaTagContent } from 'shared/utils';
  import EditCourseTabs from './components/EditCourseTabs';
  import EditCourseDataStore from './models/edit_course_data_store';
  import Course from './models/course';
  import FlashMessages from './components/FlashMessages';
  import FormFeedback from './components/FormFeedback';

  const WARNING_MSG = 'You have unsaved changes. Are you sure you want to leave?';

  export default {
    name: 'EditCourseWizardApp',
    components: { FlashMessages, FormFeedback, EditCourseTabs },
    props: {
      canShareToGoogleClassroomForSchool: { default: false, type: Boolean },
      currentUser: { required: true, type: Object },
      gradebookCategories: { required: true, type: String },
      hasAiVirtualChatActivities: { default: false, type: Boolean },
      hasVocabTutorials: { default: false, type: Boolean },
      institutionSupportsChat: { default: true, type: Boolean },
      isCurrentProgramSupersiteJunior: { default: false, type: Boolean },
      isVol: { default: false, type: Boolean },
      languageCode: { default: '', type: String },
      loadingIconPath: { required: true, type: String },
      potentialInstructors: { required: true, type: String },
      programHasAudioTranscripts: { default: false, type: Boolean },
    },
    setup(props) {
      const config = {
        canShareToGoogleClassroomForSchool: props.canShareToGoogleClassroomForSchool,
        currentUser: props.currentUser,
        gradebookCategories: props.gradebookCategories,
        hasAiVirtualChatActivities: props.hasAiVirtualChatActivities,
        hasVocabTutorials: props.hasVocabTutorials,
        instAdmin: metaTagContent('VHL.in_institution_admin') === 'true',
        institutionSupportsChat: props.institutionSupportsChat,
        isCurrentProgramSupersiteJunior: props.isCurrentProgramSupersiteJunior,
        isVol: props.isVol,
        languageCode: props.languageCode,
        programHasAudioTranscripts: props.programHasAudioTranscripts,
        programId: metaTagContent('VHL.program_id'),
        schoolId: metaTagContent('VHL.course_school_id'),
      };

      const course = new Course();
      const courseDataStore = new EditCourseDataStore(
        course,
        config.instAdmin,
        config.programId,
        config.schoolId,
        config.languageCode
      );

      /**
       * Bind 'beforeunload' event to warn the user before leaving the page if the form is dirty.
       * If generatingPdf was true it is because this method was called when generating
       * a course summary pdf. In order to re-enable the unsaved changes warning, it
       * is set back to false.
       */
      function bindBeforeUnload() {
        window.addEventListener('beforeunload', function(e) {
          if (courseDataStore.courseFormState.isChanged &&
            !courseDataStore.store.generatingPdf &&
            !courseDataStore.store.courseSaved &&
            !VHL.Common.shouldPreventWarningsAfterTimeout()) {
            e.returnValue = WARNING_MSG;
          }
          if (courseDataStore.store.generatingPdf) {
            courseDataStore.store.generatingPdf = false;
          }
        });
      }

      bindBeforeUnload();

      provide('config', config);
      provide('courseDataStore', courseDataStore);

      return { config, courseDataStore, testClass };
    },
  };
</script>

<style lang="scss" scoped>
  .edit-course-app {
    margin-top: 1.25rem;
    margin-bottom: 14rem;
    position: relative;
  }

  .edit-course__tabs {
    display: flex;
  }

  .loader-img-wrap {
    text-align: center;
  }

  .loader-img {
    margin-top: 20vh;
  }
</style>
