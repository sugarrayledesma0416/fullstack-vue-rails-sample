<template>
  <div class="new-course-app">
    <FlashMessages
      :flashError="courseDataStore.store.errorMessage"
      :flashNotice="courseDataStore.store.flashNotice"
      :showError="courseDataStore.flashMessageState.showError"
      :showNotice="courseDataStore.flashMessageState.showNotice" />
    <form novalidate name="course_form">
      <img
        v-if="courseDataStore.store.loadingOptions"
        :src="loadingIconPath"
        alt="Content loading">
      <!-- router-vue to host step specific components -->
      <router-view v-else :loadingIconPath="loadingIconPath" />
    </form>
  </div>
</template>

<script>
  import { provide } from 'vue';
  import { metaTagContent } from 'shared/utils';
  import { testClass } from 'music';
  import NewCourseDataStore from './models/new_course_data_store';
  import Course from './models/course';
  import FlashMessages from './components/FlashMessages';

  const setupTypes = {
    EXPRESS: 'express',
    CUSTOM: 'custom',
  };
  const WARNING_MSG = 'You have unsaved changes. Are you sure you want to leave?';

  export default {
    name: 'NewCourseWizardApp',
    components: { FlashMessages },
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
        isEnterprise: false,
        isVol: props.isVol,
        languageCode: props.languageCode,
        programHasAudioTranscripts: props.programHasAudioTranscripts,
        programId: metaTagContent('VHL.program_id'),
        schoolId: metaTagContent('VHL.course_school_id'),
      };
      const course = new Course();
      const courseDataStore = new NewCourseDataStore(
        course,
        config.instAdmin,
        config.isEnterprise,
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

      // Express Course setup is not available if vista online learning is not enabled.
      if (!props.isVol) {
        courseDataStore.setPathAndGo(setupTypes.CUSTOM);
      }
      provide('courseDataStore', courseDataStore);
      provide('config', config);

      return { config, courseDataStore, testClass };
    },
  };
</script>

<style scoped>
  .new-course-app { position: relative; }
</style>
