module Instructor::CreatedActivitiesHelper
  FRIENDLY_TITLES = {
    'audio_composition' => 'Student Recording',
    'composition' => 'Composition',
    'drop_down' => 'Drop-down',
    'exam' => 'Exam',
    'external_video' => 'Video',
    'external_link' => 'External Link',
    'fill_in_the_blanks' => 'Fill In The Blanks',
    'multiple_answer' => 'Multiple Answer',
    'multiple_choice' => 'Multiple Choice',
    'multiple_choice_same' => 'Multiple Choice Same',
    'open_ended' => 'Free Response',
    'partner_chat' => 'Partner Chat',
    'recording_v2' => 'Student Recording',
    'solo_video_recording' => 'Video Recording',
    'upload_file_activity' => 'Upload File'
  }.freeze

  def activity_title(activity_type)
    content_tag(:div, "Create new #{activity_label(activity_type)} activity")
  end

  def activity_label(activity_type)
    FRIENDLY_TITLES[activity_type.to_s]
  end
end
