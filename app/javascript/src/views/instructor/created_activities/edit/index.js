import 'froala-editor/css/froala_editor.min.css';
import 'froala-editor/css/froala_style.min.css';
import 'froala-editor/js/plugins/lists.min.js';

import { createApp } from 'vue';
import { metaTagContent } from 'shared/utils.js';
import { CreatedActivityApp, VueFroala } from 'mae';
import CustomFroalaList from 'features/created_activities/models/custom_froala_list';

CustomFroalaList.setDirectionLineUL();

document.addEventListener('DOMContentLoaded', () => {
  const rootElm = document.querySelector('.js-edit-created-activity-app');
  const createdActivityDataElm = document.querySelector('.js-edit-created-activity-data');
  const dataFromDom = JSON.parse(createdActivityDataElm.getAttribute('data-from-dom'));
  const baseMetadata = JSON.stringify({
    'activity_id': metaTagContent('VHL.activity_id'),
    'concept_id': metaTagContent('VHL.concept_id'),
    'course_guid': metaTagContent('VHL.course_guid'),
    'lesson_id': metaTagContent('VHL.lesson_id'),
    'school_id': metaTagContent('VHL.current_school'),
    'section_guid': metaTagContent('VHL.section_guid'),
    'user_guid': metaTagContent('VHL.user_guid'),
    'user_id': metaTagContent('VHL.user_id'),
  });
  const recordingConfig = {
    baseDir: dataFromDom.base_dir,
    cdnPrefix: dataFromDom.cdn_prefix,
    mediaRecordingEndpoint: dataFromDom.media_item_recording_endpoint,
    endpoint: dataFromDom.media_item_recording_endpoint,
    metadata: baseMetadata,
  };

  let activityJsonData = JSON.parse(dataFromDom.activity_json);
  activityJsonData = {
    ...activityJsonData,
    ...{
      direction_line: dataFromDom.direction_line,
      language: dataFromDom.language,
      question_prompt: dataFromDom.question_prompt,
      video_platform: dataFromDom.video_platform,
      video_url: dataFromDom.video_url,
    },
  };

  const app = createApp(CreatedActivityApp, {
    activityHeader: dataFromDom.activity_header,
    activityJsonData,
    activityTitle: dataFromDom.activity_title,
    activityType: dataFromDom.activity_type,
    allowsAudioTranscripts: dataFromDom.allows_audio_transcripts,
    assignmentGroupsData: dataFromDom.assignment_groups_data,
    configName: dataFromDom.config_name,
    contentJson: JSON.parse(dataFromDom.content_json),
    courseAllowsAudioTranscripts: dataFromDom.course_allows_audio_transcripts,
    createdActivityReferences: JSON.parse(dataFromDom.created_activity_references),
    fromMyContent: dataFromDom.from_my_content,
    isAssessmentTab: dataFromDom.is_assessment_tab,
    isDev: dataFromDom.is_dev,
    isDraft: dataFromDom.is_draft,
    isVol: dataFromDom.is_vol,
    mediaLookup: dataFromDom.media_lookup && JSON.parse(dataFromDom.media_lookup) || {},
    mode: 'edit',
    programLanguage: JSON.parse(dataFromDom.program_language),
    recordingConfig,
    returnLabel: dataFromDom.return_label,
    returnUrl: dataFromDom.return_url,
    submitMethod: 'patch',
    submitUrl: dataFromDom.submit_url,
    lessonId: dataFromDom.lesson_id,
    strandId: dataFromDom.strand_id,
  });

  app.use(VueFroala);
  app.mount(rootElm);
});
