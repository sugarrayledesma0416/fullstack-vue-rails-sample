module ActivityIcons
  private def icon_for_activity_type
    return icons_for_xml_content unless content_json

    icons = determine_icons(content_object)
    icons.uniq.join(',')
  end

  private def icons_for_xml_content
    icon_map = {
      'audio_composition' => 'microphone',
      'composition' => 'composition',
      'external_video' => 'video',
      'partner_chat' => 'partner_chat',
      'recording_v2' => 'microphone,audio',
      'solo_video_recording' => 'solo_video_recording',
      'video' => 'video'
    }

    icon_map.fetch(activity_type, '')
  end

  private def determine_icons(content_object)
    if content_object.chat_activity? || content_object.composition_activity?
      [activity_type]
    elsif content_object.video_activity?
      ['video']
    elsif content_object.respond_to?(:activities) && content_object.activities.present?
      solo_icons = includes_svr? ? ['solo_video_recording'] : []
      solo_icons + collect_activity_icons(content_object.activities)
    else
      parse_content_object_icons(content_object)
    end
  end

  private def collect_activity_icons(activities)
    activities.flat_map do |activity|
      parse_content_object_icons(activity)
    end
  end

  private def parse_content_object_icons(activity_content)
    icons = []
    icons << 'microphone' if activity_content.recording_activity?
    icons << 'video' if activity_content.has_video_recording?
    icons << 'audio' if activity_content.has_audio_recording?

    return icons unless activity_content.respond_to?(:items)

    icons + extract_item_icons(activity_content.items)
  end

  private def extract_item_icons(items)
    items.map do |item|
      ref_class = item.class.to_s.gsub('MaestroActivityEngine::ActivityContent::Reference::', '')
      case ref_class
      when 'Video' then 'video'
      when 'Audio' then 'audio'
      end
    end.compact
  end

  private def includes_svr?
    svr_content_class = MaestroActivityEngine::ActivityContent::SoloVideoRecordingContent
    content_object.is_a?(svr_content_class) ||
    content_object.activities.any? { |act| act.is_a?(svr_content_class) }
  end
end
