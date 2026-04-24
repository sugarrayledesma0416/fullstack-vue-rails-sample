import { createApp } from 'vue';
import ProgramConfigEditApp from 'features/program_config/ProgramConfigEditApp';

document.addEventListener('DOMContentLoaded', () => {
  const rootElm = document.querySelector('.js-program-config');
  const programConfigDataElm = document.querySelector('.js-program-config-data');
  const dataFromDom = JSON.parse(programConfigDataElm.getAttribute('data-from-dom'));
  const aiSettings = getAISettings(dataFromDom);
  const contentMenuSettings = getContentMenuSettings(dataFromDom);
  const otherFeaturesSettings = getOtherFeaturesSettings(dataFromDom);
  const standardsSettings = getStandardsSettings(dataFromDom);

  const propsData = {
    aiSettings,
    contentMenuSettings,
    currentSettings: JSON.parse(dataFromDom.current_settings),
    otherFeaturesSettings,
    programId: dataFromDom.program_id,
    programsByTitle: dataFromDom.programs_by_title,
    previousEditionProgramId: dataFromDom.previous_edition_program_id,
    nextEditionProgramId: dataFromDom.next_edition_program_id,
    programMappingData: dataFromDom.program_mapping_data,
    volConfigs: dataFromDom.vol_configs,
    standardsSettings,
    standardsSettingsData: dataFromDom.standards_settings_data,
  };

  const app = createApp(ProgramConfigEditApp, propsData);
  app.provide('programId', dataFromDom.program_id);
  app.provide('programTitle', dataFromDom.program_title);
  app.mount(rootElm);
});

/**
 * This method gets formatted program configuration for Content Menu Settings.
 * This changes key format to camelCase.
 * @param {Object} dataFromDom - Program configuration data from rails side
 * @return {Object} - Formatted program configuration
 */
const getContentMenuSettings = (dataFromDom) => {
  const contentMenuSettings = dataFromDom.content_menu_settings;
  return {
    additionalEntries: getAdditionalEntries(contentMenuSettings),
    ebook: contentMenuSettings.ebook,
    teacherVtextLabel: contentMenuSettings.teacher_vtext_label,
    teacherVtextUrl: contentMenuSettings.teacher_vtext_url,
    vocabTools: contentMenuSettings.vocab_tools,
    vocabToolsEnabled: contentMenuSettings.vocab_tools_enabled,
    vtextLabel: contentMenuSettings.vtext_label,
    vtextType: contentMenuSettings.vtext_type,
    vtextUrl: contentMenuSettings.vtext_url,
  };
};

/**
 * This method gets formatted content menu additional entries.
 * @param {Object} contentMenuSettings - Content menu settings from rails side
 * @param {Array} contentMenuSettings.content_menu_additional_entries - Content menu additional
 * entries from rails side
 * @return {Array} - Formatted menu additional entries
 */
const getAdditionalEntries = (contentMenuSettings) => {
  return contentMenuSettings.content_menu_additional_entries?.map(
    getFormattedEntry
  ) ?? [];
};

/**
 * This method gets formatted content menu additional entry
 * @param {Object} entry - Content menu additional entry from rails side
 * @return {Object} - Formatted content menu additional entry
 */
const getFormattedEntry = (entry) => {
  const additionalEntry = entry.table;
  return {
    description: additionalEntry.description,
    label: additionalEntry.label,
    programId: additionalEntry.program_id || '',
    targetUser: additionalEntry.target_user,
    url: additionalEntry.url,
  };
};

/**
 * This method gets formatted program configuration for Other Features Settings.
 * This changes key format to camelCase.
 * @param {Object} dataFromDom - Program configuration data from rails side
 * @return {Object} - Formatted settings
 */
const getOtherFeaturesSettings = (dataFromDom) => {
  const otherFeaturesSettings = dataFromDom.other_features_settings;
  return {
    allowAssessmentsRandomization: otherFeaturesSettings.allow_assessments_randomization,
    audioTranscripts: otherFeaturesSettings.audio_transcripts,
    hideActivities: otherFeaturesSettings.hide_activities,
    studyCenter: otherFeaturesSettings.study_center,
    hideAssessment: otherFeaturesSettings.hide_assessment,
    hideMyContent: otherFeaturesSettings.hide_my_content,
    hideTranslation: otherFeaturesSettings.hide_translation,
    languageCode: otherFeaturesSettings.language_code,
    questionBanksEnabled: otherFeaturesSettings.question_banks_enabled,
    practiceTestAnalyticsEnabled: otherFeaturesSettings.practice_test_analytics_enabled,
    shareToPortfolio: otherFeaturesSettings.share_to_portfolio,
    showSkillsAndRefinementFilters: otherFeaturesSettings.show_skills_and_refinement_filters,
    pmrStandardReportsAllowed: otherFeaturesSettings.pmr_standard_reports_allowed,
    enableConcurrentEnrollment: otherFeaturesSettings.enable_concurrent_enrollment,
    speechRec: otherFeaturesSettings.speech_rec,
    vocabDefinition: otherFeaturesSettings.vocab_definition,
    vocabWords: otherFeaturesSettings.vocab_words,
  };
};

/**
 * This method gets the formatted program configuration for Standards Settings.
 * This changes the key format to camelCase.
 * @param {Object} dataFromDom - Program configuration data from rails side
 * @return {Object} - Formatted settings
 */
const getStandardsSettings = (dataFromDom) => {
  const standardsSettings = dataFromDom.standards_settings;
  return {
    supportedStandardSetIds: standardsSettings.supported_standard_set_ids,
  };
};

/**
 * This method gets the formatted program configuration for AI Settings.
 * This changes the key format to camelCase.
 * @param {Object} dataFromDom - Program configuration data from rails side
 * @return {Object} - Formatted settings
 */
const getAISettings = (dataFromDom) => {
  const aiSettings = dataFromDom.ai_settings;
  return {
    gradingSuggestions: aiSettings.grading_suggestions,
    programLevel: aiSettings.program_level,
  };
};
