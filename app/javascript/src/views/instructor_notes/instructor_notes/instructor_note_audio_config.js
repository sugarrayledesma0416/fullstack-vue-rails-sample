import { metaTagContent } from 'shared/utils.js';

/**
 * @type {object} - Metadata to add to each instructor notes recording
 *   The metadata will be appended to the recording on S3
 */
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

VHL.InstructorNotes = VHL.InstructorNotes || {};

/**
 * @type {object} - Config for recording, including the recording endpoint URL, the cdn URL,
 *   the base directory, and the metadata to save recordings in for this activity type.
 * @memberOf VHL.InstructorNotes
 */
VHL.InstructorNotes.Config = {
  baseDir: VHL.multimediaConfig.instructor_notes.base_dir,
  endpoint: VHL.multimediaConfig.instructor_notes.recording_endpoint,
  cdnPrefix: VHL.multimediaConfig.instructor_notes.cdn_prefix,
  metadata: baseMetadata,
};
