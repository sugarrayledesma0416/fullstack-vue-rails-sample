module PartnerChatHelper
  def partner_chat_recording_url(response)
    if response[:recording_path].blank?
      ''
    else
      "#{M3::Application.config.partner_chat_cdn}/#{response[:recording_path]}"
    end
  end

  def solo_video_recording_url(response)
    partner_chat_recording_url(response)
  end

  def partner_chat_class(student, student_to_grade)
    if student == student_to_grade
      'current_student'
    else
      'current_partner'
    end
  end

  def avatar_meta_tag
    avatar_url = current_user.avatar_image_url
    "<meta name=\"VHL.avatar_path\" content=\"#{avatar_url}\"/>".html_safe
  end
end
