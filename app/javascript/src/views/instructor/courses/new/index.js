import { createApp } from 'vue';
import NewCourseWizardApp from 'features/course_wizard/NewCourseWizardApp';
import { getRouter } from 'features/course_wizard/services/router';

document.addEventListener('DOMContentLoaded', () => {
  const rootElm = document.querySelector('.js-course-wizard');
  const courseWizardDataElm = document.querySelector('.js-course-wizard-data');
  const dataFromDom = JSON.parse(courseWizardDataElm.getAttribute('data-from-dom'));
  const app = createApp(NewCourseWizardApp, {
    canShareToGoogleClassroomForSchool: dataFromDom.can_share_to_google_classroom_for_school,
    currentUser: JSON.parse(dataFromDom.current_user),
    gradebookCategories: dataFromDom.gradebook_categories,
    hasAiVirtualChatActivities: dataFromDom.has_ai_virtual_chat_activities,
    hasVocabTutorials: dataFromDom.has_vocab_tutorials,
    institutionSupportsChat: dataFromDom.institution_supports_chat,
    isCurrentProgramSupersiteJunior: dataFromDom.is_current_program_supersite_junior,
    isVol: dataFromDom.is_vol,
    languageCode: dataFromDom.language_code,
    loadingIconPath: dataFromDom.loading_icon_path,
    programHasAudioTranscripts: dataFromDom.program_has_audio_transcripts,
  });
  const router = getRouter('add');
  app.use(router).mount(rootElm);
});

