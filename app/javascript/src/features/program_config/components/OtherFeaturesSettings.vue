<template>
  <div class="c-panel  u-bord-2  u-bord-gray-e">
    <div class="c-panel__header">
      <h3 class="c-heading--panel">
        Enable/Disable other features
      </h3>
    </div>
    <div class="c-panel__body">
      <template v-if="languageCode === 'en'">
        <div class="c-form-item" :class="testClass('hide-translation')">
          <input
            id="datastore_hide_translation"
            type="checkbox"
            name="datastore[hide_translation]"
            value=""
            class="c-form-item__checkbox"
            :checked="hideTranslation"
            :class="testClass('datastore-hide-translation')"
            @change="updateVocabDefinition($event.target.checked)">
          <label
            for="datastore_hide_translation"
            class="c-form-item__label">
            Hide Translation Column in Vocab Tools
          </label>
        </div>
      </template>
      <div class="c-form-item" :class="testClass('vocab-definition')">
        <input
          id="datastore_vocab_definition"
          type="checkbox"
          name="datastore[vocab_definition]"
          value=""
          class="c-form-item__checkbox"
          :checked="dataStore.vocabDefinition"
          :disabled="dataStore.disableVocabDefinition"
          :class="testClass('datastore-vocab-definition')">
        <label
          for="datastore_vocab_definition"
          class="c-form-item__label"
          :class="{ 'u-txt-gray-b' : dataStore.grayVocabDefinition }">
          Show Definition Column in Vocabulary Tools
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_vocab_words"
          type="checkbox"
          name="datastore[vocab_words]"
          value=""
          class="c-form-item__checkbox"
          :checked="vocabWords"
          :class="testClass('datastore-vocabulary-feature')">
        <label
          for="datastore_vocab_words"
          class="c-form-item__label">
          Previous Vocabulary feature
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_speech_rec"
          type="checkbox"
          name="datastore[speech_rec]"
          value=""
          class="c-form-item__checkbox"
          :checked="speechRec"
          :class="testClass('datastore-speech-rec')">
        <label
          for="datastore_speech_rec"
          class="c-form-item__label">
          Enable Speech Recognition
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_hide_activities"
          type="checkbox"
          name="datastore[hide_activities]"
          value=""
          class="c-form-item__checkbox"
          :checked="hideActivities"
          :class="testClass('datastore-hide-activities')">
        <label
          for="datastore_hide_activities"
          class="c-form-item__label">
          Hide Activities in Content Menu
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_hide_assessment"
          type="checkbox"
          name="datastore[hide_assessment]"
          value=""
          class="c-form-item__checkbox"
          :checked="hideAssessment"
          :class="testClass('datastore-hide-assessment')">
        <label
          for="datastore_hide_assessment"
          class="c-form-item__label">
          Hide Assessment in Content Menu
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_hide_my_content"
          type="checkbox"
          name="datastore[hide_my_content]"
          value=""
          class="c-form-item__checkbox"
          :checked="hideMyContent"
          :class="testClass('datastore-hide-my-content')">
        <label
          for="datastore_hide_my_content"
          class="c-form-item__label">
          Hide My Content in Content Menu
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_audio_transcripts"
          type="checkbox"
          name="datastore[audio_transcripts]"
          value=""
          class="c-form-item__checkbox"
          :checked="audioTranscripts"
          :class="testClass('datastore-audio-transcripts')">
        <label
          for="datastore_audio_transcripts"
          class="c-form-item__label">
          Show Audio Transcript in Content Menu
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_study_center"
          type="checkbox"
          name="datastore[study_center]"
          value=""
          class="c-form-item__checkbox"
          :checked="studyCenter"
          :class="testClass('datastore-study-center')">
        <label
          for="datastore_study_center"
          class="c-form-item__label">
          Show Study Center on Student Dashboard
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_allow_assessments_randomization"
          type="checkbox"
          name="datastore[allow_assessments_randomization]"
          value=""
          class="c-form-item__checkbox"
          :checked="allowAssessmentsRandomization"
          :class="testClass('datastore-allow-assessments-randomization')">
        <label
          for="datastore_allow_assessments_randomization"
          class="c-form-item__label">
          Allow assessments randomization
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_question_banks_enabled"
          type="checkbox"
          name="datastore[question_banks_enabled]"
          value=""
          class="c-form-item__checkbox"
          :checked="questionBanksEnabled"
          :class="testClass('datastore-question-banks-enabled')">
        <label
          for="datastore_question_banks_enabled"
          class="c-form-item__label">
          Supports Question Banks in custom assessments
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_practice_test_analytics_enabled"
          type="checkbox"
          name="datastore[practice_test_analytics_enabled]"
          value=""
          class="c-form-item__checkbox"
          :checked="practiceTestAnalyticsEnabled"
          :class="testClass('datastore-practice-test-analytics-enabled')">
        <label
          for="datastore_practice_test_analytics_enabled"
          class="c-form-item__label">
          Show Practice Test link in Gradebook Analytics navigation
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_pmr_standard_reports_allowed"
          type="checkbox"
          name="datastore[pmr_standard_reports_allowed]"
          value=""
          class="c-form-item__checkbox"
          :checked="pmrStandardReportsAllowed"
          :class="testClass('datastore-pmr-standard-reports-allowed')">
        <label
          for="datastore_pmr_standard_reports_allowed"
          class="c-form-item__label">
          Enable "Progress Monitoring Standard Reports" feature for this program.
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_share_to_portfolio"
          type="checkbox"
          name="datastore[share_to_portfolio]"
          value=""
          class="c-form-item__checkbox"
          :checked="shareToPortfolio"
          :class="testClass('datastore-share-to-portfolio')">
        <label
          for="datastore_share_to_portfolio"
          class="c-form-item__label">
          Enable "Share to Portfolio" feature for this program.
        </label>
      </div>
      <div class="c-form-item">
        <input
          id="datastore_show_skills_and_refinement_filters"
          type="checkbox"
          name="datastore[show_skills_and_refinement_filters]"
          value=""
          class="c-form-item__checkbox"
          :checked="showSkillsAndRefinementFilters"
          :class="testClass('datastore-show-skills-and-refinement-filters')">
        <label
          for="datastore_show_skills_and_refinement_filters"
          class="c-form-item__label">
          Enable "Skills and Refinement Filters" feature for this program.
        </label>
      </div>
      <div class="c-form-item" :class="testClass('enable-concurrent-enrollment')">
        <input
          id="datastore_enable_concurrent_enrollment"
          type="checkbox"
          name="datastore[enable_concurrent_enrollment]"
          value=""
          class="c-form-item__checkbox"
          :checked="enableConcurrentEnrollment"
          :class="testClass('datastore-enable-concurrent-enrollment')"
          @change="handleConcurrentEnrollmentChange">
        <label
          for="datastore_enable_concurrent_enrollment"
          class="c-form-item__label">
          Enable Concurrent Enrollment
        </label>
      </div>
    </div>
    <BasicDialog
      v-if="showConcurrentEnrollmentDialog"
      :isConfirmationDialog="false"
      :isModal="true"
      :title="`${pendingConcurrentEnrollmentValue ? 'Enable' : 'Disable'} Concurrent Enrollment?`"
      @close-dialog="updateConcurrentEnrollment(true)">
      <template #body>
        <div
          class="concurrent-enrollment-change-requirement"
          :class="testClass('enable-concurrent-enrollment-change-requirement')">
          Changing the concurrent enrollment setting changes enrollment and
          student work transfer behavior for all institutions with site licensing.
          Written approval from the <b>K12 General Manager</b> is required before
          modifying this feature.
        </div>
      </template>
      <template #footer>
        <div class="concurrent-enrollment-modal-controls">
          <StandardButton
            variant="primary"
            class="u-mar-rt-8"
            :class="testClass('confirm-concurrent-enrollment-btn')"
            @click="updateConcurrentEnrollment(false)">
            Confirm
          </StandardButton>
          <StandardButton
            class="u-mar-rt-8"
            :class="testClass('cancel-concurrent-enrollment-btn')"
            @click="updateConcurrentEnrollment(true)">
            Cancel
          </StandardButton>
        </div>
      </template>
    </BasicDialog>
  </div>
</template>

<script>
  import { reactive, ref, watch, toRef } from 'vue';
  import { StandardButton, testClass } from 'music';
  import BasicDialog from
  'music/app/javascript/src/components/basic_dialog/v1.0/BasicDialog.vue';

  export default {
    name: 'OtherFeaturesSettings',
    components: {
      BasicDialog,
      StandardButton,
    },
    props: {
      allowAssessmentsRandomization: { default: false, type: Boolean },
      audioTranscripts: { default: false, type: Boolean },
      hideActivities: { default: false, type: Boolean },
      hideAssessment: { default: false, type: Boolean },
      hideMyContent: { default: false, type: Boolean },
      hideTranslation: { default: false, type: Boolean },
      languageCode: { default: '', type: String },
      practiceTestAnalyticsEnabled: { default: false, type: Boolean },
      questionBanksEnabled: { default: false, type: Boolean },
      shareToPortfolio: { default: false, type: Boolean },
      showSkillsAndRefinementFilters: { default: false, type: Boolean },
      pmrStandardReportsAllowed: { default: false, type: Boolean },
      enableConcurrentEnrollment: { default: false, type: Boolean },
      speechRec: { default: false, type: Boolean },
      studyCenter: { default: false, type: Boolean },
      vocabDefinition: { default: false, type: Boolean },
      vocabWords: { default: false, type: Boolean },
    },
    setup(props) {
      const dataStore = reactive({
        disableVocabDefinition: false,
        grayVocabDefinition: false,
        vocabDefinition: props.vocabDefinition,
      });
      const hideTranslationRef = toRef(props, 'hideTranslation');

      /**
       * Update vocab definition checkbox and label based on hideTranslation configuration
       * if program language is English
       */
      const initializeVocabDefinition = () => {
        if (props.hideTranslation && props.languageCode === 'en') {
          updateVocabDefinition(true);
        }
      };

      /**
       * Update vocab definition checkbox and label
       * @param {boolean} isChecked - whether vocab definition should be set checked
       */
      const updateVocabDefinition = (isChecked) => {
        dataStore.vocabDefinition = isChecked;
        dataStore.disableVocabDefinition = isChecked;
        dataStore.grayVocabDefinition = isChecked;
      };

      const handleConcurrentEnrollmentChange = (event) => {
        const newValue = event.target.checked;
        const oldValue = props.enableConcurrentEnrollment;

        // Show dialog only when the new value differs from the database value
        if (newValue !== oldValue) {
          // Store the new value for the modal title
          pendingConcurrentEnrollmentValue.value = newValue;
          showConcurrentEnrollmentDialog.value = true;
        }

        // Update the ref to reflect the new checkbox state
        enableConcurrentEnrollment.value = newValue;
      };

      const updateConcurrentEnrollment = (isCancel) => {
        if (isCancel) {
          // Revert to the database state when canceling
          enableConcurrentEnrollment.value = props.enableConcurrentEnrollment;
        }
        showConcurrentEnrollmentDialog.value = false;
      };

      const enableConcurrentEnrollment = ref(props.enableConcurrentEnrollment);
      const pendingConcurrentEnrollmentValue = ref(props.enableConcurrentEnrollment);
      const showConcurrentEnrollmentDialog = ref(false);

      watch(
        hideTranslationRef,
        (newValue) => updateVocabDefinition(newValue)
      );

      initializeVocabDefinition();

      return {
        dataStore,
        testClass,
        updateVocabDefinition,
        enableConcurrentEnrollment,
        pendingConcurrentEnrollmentValue,
        handleConcurrentEnrollmentChange,
        updateConcurrentEnrollment,
        showConcurrentEnrollmentDialog,
      };
    },
  };
</script>

<style lang="sass" scoped>
  @import '~MusicAssets/stylesheets/music/library/v1/base/main';

  .concurrent-enrollment-modal-controls {
    display: flex;
    justify-content: flex-end;
  }

  .concurrent-enrollment-change-requirement {
    line-height: rpx(24);
    max-width: rpx(400);
  }

  .warning-img {
    height: rpx(20);
    margin-top: rpx(12);
  }
</style>
