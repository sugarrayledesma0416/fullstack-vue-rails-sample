module ActivityPreviewable
  extend ActiveSupport::Concern

  # sets the lesson, strand and concept based on the program
  # defaulting to the first lesson and strand
  private def activity_attrs_for_program
    lesson = current_program.lessons.first
    strand = lesson.strands.first
    {
      concept_id: strand.location,
      lesson_id: lesson.id,
      toc_location: strand.location
    }
  end

  private def activity_params
    return @activity_params if defined? @activity_params

    @activity_params = params.require(:activity).permit(
      :activity_type,
      :cms_revision_id, # ActivityContent needs this
      :content,
      :content_key
    ).to_h.symbolize_keys
  end

  private def content_cache
    @content_cache ||= CacheManager.new('cms_preview_content')
  end

  private def set_current_user
    current_user
  end

  private def set_up_preview_environment
    @current_section = Section.section_zero

    # retrieve content and create activity
    content_key = activity_params.delete(:content_key)
    activity_params[:content] = content_cache.cache_get(content_key)
    activity_params.merge!(activity_attrs_for_program)
    @activity = PreviewActivity.new(activity_params)

    # assign attributes
    @activity.assign_attributes(
      title: @activity.content_object&.title,
      content_summary: @activity.content_object&.content_summary.to_json
    )

    @attempt = PreviewAttempt.new(
      activity: @activity,
      section: @current_section,
      user: current_user
    )
    @attempt_track = @attempt.attempt_track
    @classwork = Struct.new(:section_id, :user_id, keyword_init: true) do
      def assignment(_activity)
        nil
      end
    end.new(section_id: 0, user_id: current_user.id)

    if @activity.santillana?
      assign_lossless_auth_token # defined in application controller
      assign_santillana_book_iframe_src(max_attempts: @attempt_track.max)
    elsif @activity.ai_virtual_chat?
      assign_lossless_auth_token # defined in application controller
    end
  end

end
