<template>
  <div>
    <ReferenceToolSettings :currentSettings="currentSettings" />
    <ContentMenuSettings
      :additionalEntries="contentMenuSettings.additionalEntries"
      :ebook="contentMenuSettings.ebook"
      :programId="programId"
      :teacherVtextLabel="contentMenuSettings.teacherVtextLabel"
      :teacherVtextUrl="contentMenuSettings.teacherVtextUrl"
      :vocabTools="contentMenuSettings.vocabTools"
      :vocabToolsEnabled="contentMenuSettings.vocabToolsEnabled"
      :vtextLabel="contentMenuSettings.vtextLabel"
      :vtextType="contentMenuSettings.vtextType"
      :vtextUrl="contentMenuSettings.vtextUrl"
      @updateHideTranslation="updateHideTranslation" />
    <AISettings
      :gradingSuggestions="aiSettings.gradingSuggestions"
      :programLevel="aiSettings.programLevel" />
    <OtherFeaturesSettings
      :allowAssessmentsRandomization="otherFeaturesSettings.allowAssessmentsRandomization"
      :audioTranscripts="otherFeaturesSettings.audioTranscripts"
      :hideActivities="otherFeaturesSettings.hideActivities"
      :hideAssessment="otherFeaturesSettings.hideAssessment"
      :hideMyContent="otherFeaturesSettings.hideMyContent"
      :hideTranslation="dataStore.hideTranslation"
      :languageCode="otherFeaturesSettings.languageCode"
      :questionBanksEnabled="otherFeaturesSettings.questionBanksEnabled"
      :practiceTestAnalyticsEnabled="otherFeaturesSettings.practiceTestAnalyticsEnabled"
      :shareToPortfolio="otherFeaturesSettings.shareToPortfolio"
      :showSkillsAndRefinementFilters="otherFeaturesSettings.showSkillsAndRefinementFilters"
      :pmrStandardReportsAllowed="otherFeaturesSettings.pmrStandardReportsAllowed"
      :enableConcurrentEnrollment="otherFeaturesSettings.enableConcurrentEnrollment"
      :speechRec="otherFeaturesSettings.speechRec"
      :studyCenter="otherFeaturesSettings.studyCenter"
      :vocabDefinition="otherFeaturesSettings.vocabDefinition"
      :vocabWords="otherFeaturesSettings.vocabWords" />
    <VolConfigs v-if="volConfigs.is_vista_online_learning" :volConfigs="volConfigs" />
    <ProgramMappingComponent
      :programMappingData="programMappingData" />
    <ProgramEditions
      :programsByTitle="programsByTitle"
      :previousEditionProgramId="previousEditionProgramId"
      :nextEditionProgramId="nextEditionProgramId" />
    <StandardSettings
      v-if="standardsSettingsData.standard_sets_array.length > 0"
      :supportedStandardSetIds="standardsSettings.supportedStandardSetIds"
      :standardsSettingsData="standardsSettingsData" />
  </div>
</template>

<script>
  import { reactive } from 'vue';
  import { testClass } from 'music';
  import AISettings from './components/AISettings';
  import ProgramEditions from './components/ProgramEditions';
  import ProgramMappingComponent from './components/program_mapping/ProgramMappingComponent';
  import ReferenceToolSettings from './components/ReferenceToolSettings';
  import ContentMenuSettings from './components/ContentMenuSettings';
  import OtherFeaturesSettings from './components/OtherFeaturesSettings';
  import VolConfigs from './components/VolConfigs';
  import StandardSettings from './components/StandardSettings';

  export default {
    name: 'ProgramConfigEditApp',
    components: {
      AISettings,
      ContentMenuSettings,
      OtherFeaturesSettings,
      ProgramMappingComponent,
      ReferenceToolSettings,
      VolConfigs,
      ProgramEditions,
      StandardSettings,
    },
    props: {
      aiSettings: { required: true, type: Object },
      contentMenuSettings: { required: true, type: Object },
      currentSettings: { required: true, type: Object },
      otherFeaturesSettings: { required: true, type: Object },
      programId: { required: true, type: Number },
      programsByTitle: { required: true, type: Array },
      previousEditionProgramId: { type: String, default: '' },
      nextEditionProgramId: { type: String, default: '' },
      programMappingData: { required: true, type: Object },
      volConfigs: { required: true, type: Object },
      standardsSettings: { required: true, type: Object },
      standardsSettingsData: { required: true, type: Object },
    },
    setup(props) {
      const dataStore = reactive({
        hideTranslation: props.otherFeaturesSettings.hideTranslation,
      });

      /**
       * Update datastore to update "Show Hide Translation" checkbox in OtherFeaturesSettings
       * for English programs
       * @param {Object} payload - Payload from Vocab Tools checkbox in ContentMenuSettings
       * @param {Event} payload.event - Change event from Vocab Tools Checkbox
       * @param {boolean} payload.event.target.checked - Whether Vocab Tools checkbox is checked
       */
      const updateHideTranslation = (payload) => {
        if (props.otherFeaturesSettings.languageCode === 'en') {
          const { event } = payload;
          dataStore.hideTranslation = event.target.checked;
        }
      };

      return { dataStore, testClass, updateHideTranslation };
    },
  };
</script>
