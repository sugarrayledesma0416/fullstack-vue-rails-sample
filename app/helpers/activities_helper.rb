module ActivitiesHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::SanitizeHelper
  include AudienceLabeling

  def format_next_activity_button(activity)
    config = activity.content_object.config
    (config.present? && config.next_button_text) || 'Next Activity'
  end

  def format_help_request_data(program, section, users, activity, current_view, http_referer,
                               params)
    { http_referer:,
      user_id: users.map(&:id),
      user_type: users.first.base_account_type.downcase,
      activity_id: activity.id,
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id,
      program_id: program.id,
      section_id: section.id,
      activity_state: current_view,
      request_params: params }
  end

  def show_instructor_notes_link_for?(user, controller_name)
    user.instructor? && controller_name == 'activities'
  end

  def get_current_button_tag(activity, attempt_track, workset)
    return '' if activity.preview?

    if activity&.content_object&.submittable? && !activity.santillana?
      if attempt_track.practice?
        'practice_activity'
      elsif activity.partner_chat? || activity.speech_rec_listen_repeat? || activity.ai_virtual_chat?
        if workset && !workset.final_activity?(activity)
          'next_activity_submit'
        else
          'submit'
        end
      else
        'save_submit'
      end
    elsif workset&.final_activity?(activity) || workset.nil?
      'return_to'
    else
      'next_activity'
    end
  end

  def activities_by_component(activities, use_component_name = false)
    current_component_activities = []
    current_component_name = nil
    component_language = ''
    previous_language = nil

    activities.each do |activity|
      display_name = component_display_name(activity, use_component_name)
      component_language = activity.component_language

      if display_name != current_component_name
        component_language = previous_language unless previous_language.nil?
        unless current_component_activities.empty?
          yield(current_component_name, component_language, current_component_activities)
        end
        current_component_name = display_name
        current_component_activities = []
      end
      previous_language = component_language
      current_component_activities << activity
    end

    return if current_component_activities.empty?

    yield(current_component_name, component_language, current_component_activities)
  end

  def activity_path(activity_id, section_id = 0)
    section_activity_path(id: activity_id, section_id:).html_safe
  end

  def external_reference_links(activity, section_id, program_id)
    return if activity.hide_external_references?

    activity.external_references.map do |external_reference|
      external_reference_link(external_reference, section_id, program_id)
    end
  end

  def external_reference_link(external_reference, section_id, program_id)
    if external_reference.is_a?(MaestroActivityEngine::ActivityContent::ExternalReference::Activity)
      format_external_activity_popup_link(external_reference, section_id, program_id)
    elsif external_reference.is_a?(MaestroActivityEngine::ActivityContent::ExternalReference::Url)
      format_external_url_popup_link(external_reference)
    else
      format_popup_play_link(external_reference.link.media_item, external_reference.title)
    end
  end
  private :external_reference_link

  def format_external_url_popup_link(external_reference)
    popup_options = { window_name: "external_ref_url_#{external_reference}",
                      height: 600, width: 885 }
    link_to(
      external_reference.title.html_safe,
      external_reference.url,
      onclick: format_popup_onclick(popup_options),
      'aria-label': "#{strip_tags(external_reference.title)}. The link will open in a new window"
    )
  end

  def format_external_activity_popup_link(external_reference, section_id, program_id)
    popup_options = { window_name: "external_ref_activity_#{external_reference.activity}",
                      height: 600, width: 885 }
    link_to(
      external_reference.title.html_safe,
      popup_section_activity_path(section_id:, id: external_reference.activity,
                                  program_id:),
      onclick: format_popup_onclick(popup_options),
      'aria-label': "#{strip_tags(external_reference.title)}. The link will open in a new window"
    )
  end

  def external_reference_path(cms_activity_id, activity, section)
    popup_section_activity_path(section_id: (section ? section.id : 0), id: cms_activity_id,
                                program_id: activity.program.id)
  end

  def format_popup_reference(cms_activity_id)
    popup_options = { window_name: "external_ref_activity_#{cms_activity_id}",
                      height: 600, width: 885 }
    link_to('View full activity',
            popup_section_activity_path(section_id: current_section, id: cms_activity_id, program_id: current_program), onclick: format_popup_onclick(popup_options), class: 'external-activity')
  end

  def activity_path_from_toc(section_id, activity)
    if spr?
      spr_section_activity_path(id: activity.id, section_id:)
    else
      section_activity_path(id: activity.id, section_id:)
    end
  end

  # def show_flashcards_deck_path(activity_id, deck_index, flashcards_deck_type)
  # stubbing this to get plugin working, real deck support is pending
  # "/stub_show_flashcards_deck_path/#{activity_id}/#{deck_index}".html_safe
  # end

  def format_activity_label_with_icons(
    label_id,
    activity,
    link_path = nil,
    _hover_path = link_path,
    has_note = false,
    svg_format = false,
    has_title = true
  )
    output = ''
    if has_title
      output << if link_path
                  link_to(
                    activity.title.html_safe,
                    link_path,
                    aria: {
                      describedby: "icon_#{activity.id} " \
                                   "#{'instructor_graded' if activity.instructor_graded?}" \
                                   "#{'instructor_note' if has_note}"
                    },
                    class: 'c-col-activity__info-link  activity_link' \
                           "  u-txt-under  #{test_class('activity-title')}",
                    id: label_id
                  )
                else
                  content_tag(:span, activity.title.html_safe, id: label_id)
                end
    end
    output << activity_icon(activity, svg_format) if activity.icon.present?
    output << instructor_icon(:graded, svg_format) if activity.instructor_graded?
    output << instructor_icon(:note, svg_format) if has_note
    output.html_safe
  end

  def should_render_submit_confirmation?(attempt_track, options = {})
    buttons = options[:buttons]
    show_not_enrolled_warning = options[:show_not_enrolled_warning]
    instructor_practice = options[:instructor_practice]

    return false unless attempt_track&.remaining == '1' && !show_not_enrolled_warning

    %w[save_submit next_activity_submit submit].include?(buttons) ||
      buttons == 'accept_retry' ||
      (buttons == 'practice_activity' && instructor_practice)
  end

  private def activity_icon(activity, svg_format)
    content_tag(
      :span,
      format_activity_icon(activity.icon, svg_format),
      id: "icon_#{activity.id}",
      class: 'icon'
    )
  end

  private def instructor_icon(icon_type = :graded, svg_format = false)
    icon_filename = icon_type == :graded ? 'icon_person' : 'instructor_note_icon_rounded'
    button_opts = {
      lang: 'en',
      class: 'icon  u-bord-none  u-bg-transparent  u-pad-0  u-mar-lt-5  js-tooltip-auto',
      id: "instructor_#{icon_type}",
      type: 'button',
      aria: {
        label: icon_type == :graded ? 'Grading information' : "instructor #{icon_type}"
      }
    }.tap do |memo|
      memo[:title] = if icon_type == :graded
                       audience_label(current_program&.audience, :Instructor_graded)
                     else
                       "instructor #{icon_type}"
                     end
    end

    content_tag(:button, button_opts) do
      if svg_format
        feature_icon("music/toc/#{icon_filename}")
      else
        image_tag("#{icon_filename}.png")
      end
    end
  end

  def format_activity_due_date(due_date, _overdue = false, add_divs = false)
    return '' if due_date.blank?

    if add_divs
      "<div class='due-date-month'>#{due_date.strftime('%B')}</div><div class='due-date-date'>#{due_date.strftime('%d')}</div>".html_safe
    else
      format_date_time(due_date, :relative_weekday_month_ordinal)
    end
  end

  def format_flashcards_menu_link(link_text, _activity, _section_id = 0)
    link_to(link_text, '#', onclick: 'window.close()')
  end

  def format_flashcards_deck_link(deck_index, section_id, activity_id, flashcards_deck_type)
    link_to("Deck #{deck_index + 1}",
            section_show_flashcards_deck_path(section_id.to_i, activity_id, deck_index + 1, flashcards_deck_type), onclick: format_popup_onclick(width: 960, height: 800))
  end

  def format_flashcards_language_link(link_text, section_id, activity_id, deck_number, deck_type)
    link_to(link_text,
            section_show_flashcards_deck_path(section_id, activity_id, deck_number, deck_type))
  end

  def format_point_earned_ratio_for_sub_activity(sub_activity, results)
    sub_activity_labels = sub_activity.items.collect(&:label)
    sub_activity_labels_regexp = sub_activity_labels.join('|')
    sub_activity_results = []
    results.each do |result|
      sub_activity_results << result if result[:label] =~ /#{sub_activity_labels_regexp}/
    end

    points_earned = 0
    points_possible = 0

    sub_activity_results.each do |result|
      points_possible += results.points_possible(result[:label])
      points_earned += results.points_earned(result[:label])
    end
    "#{points_earned} of #{points_possible}"
  end

  def format_answer_key_mode_link(user, controller, activity, section_id, program_id, params)
    return format_preview_answer_key_mode_link(controller, activity) if activity.preview?
    return '' unless user.instructor? && activity.gradable?

    if controller.action_name == 'answer_keys'
      return_path = if params[:task_type].present?
                      instructor_grading_styles_path(program_id, activity,
                                                     task_type: params[:task_type])
                    elsif user.cartridge?
                      cartridge_section_activity_path(section_id, activity, popup: params[:popup])
                    elsif spr?
                      spr_section_activity_path(id: activity.id, section_id:, popup: params[:popup])
                    else
                      section_activity_path(section_id, activity, popup: params[:popup])
                    end
      link_to 'Exit answer key', return_path
    elsif user.cartridge?
      link_to 'Answer key',
              answer_keys_cartridge_section_activity_path(section_id, activity.id, task_type: params[:task_type],
                                                                                   popup: params[:popup])
    elsif spr?
      link_to(
        'Answer key',
        answer_keys_spr_section_activity_path(
          section_id, activity.id, task_type: params[:task_type], popup: params[:popup]
        )
      )
    else
      link_to 'Answer key',
              answer_keys_section_activity_path(section_id, activity.id, task_type: params[:task_type],
                                                                         popup: params[:popup])
    end
  end

  private def format_preview_answer_key_mode_link(controller, activity)
    return '' unless activity.gradable?

    if controller.action_name == 'preview_answer_key'
      link_to 'Exit answer key', preview_activity_path(safe_preview_params_hash)
    else
      link_to 'Answer key', preview_answer_key_path(safe_preview_params_hash)
    end
  end

  # score: a GradebookEngine::Grade
  # results: from mae's validate_responses
  def format_footer_score(score, results, rubric_link = nil)
    content_tag(:p, class: "c-footer__score-content  #{test_class('footer-score-content')}") do
      if score
        if score.pending? || score.partial_pending?
          "Score : #{format_current_score(score)}"
        elsif rubric_link
          format_rubric_score(score, rubric_link)
        else
          format_non_rubric_score(score)
        end
      elsif results
        # if there's no score, then we are in Section Zero
        # or the work is unassigned. Use results.
        "#{results.total_points_earned} of " \
          "#{results.total_points_possible} pts. " \
          "#{format_as_percent_with_one_decimal(results.score)}"
      end
    end
  end

  def points_earned_vs_possible(score)
    return unless score

    "#{score.formatted_points_earned_for_display} of " \
      "#{score.points_possible_for_display} pts. " \
  end

  private def format_rubric_score(score, rubric_link)
    insert_rubric_link(score, rubric_link) << format_late_penalty(score)
  end

  private def insert_rubric_link(score, rubric_link)
    output = 'Rubric Grade '
    output << rubric_content_tag(rubric_link)
    output.tap do |str|
      str << " (#{score.formatted_score}%)"
    end
    sanitize(output, tags: %w[a span], attributes: %w[href onclick class])
  end

  private def rubric_content_tag(rubric_link)
    content_tag(
      :span,
      rubric_link,
      class: "u-txt-bold  #{test_class('scored-rubric-link')}"
    )
  end

  private def format_non_rubric_score(score)
    output = 'Grade '
    output << content_tag(
      :span,
      points_earned_vs_possible(score),
      class: "u-txt-bold  #{test_class('non-rubric-score')}"
    )
    output.tap do |str|
      str << "(#{score.formatted_score}%) "
      str << format_late_penalty(score)
    end
    sanitize(output, tags: %w[span], attributes: %w[class])
  end

  private def format_late_penalty(score)
    score.late? ? " Late Penalty: #{score.net_penalty_percent}%" : ''
  end

  def show_uploader_controls(attachment, field_name, allowed_file_types = '')
    # rubocop:disable Rails/UnknownEnv
    content_tag(
      :div,
      '',
      class: 'js-composition-uploader',
      data: {
        'allowed-file-types' => allowed_file_types,
        'debug' => !Rails.env.live?,
        'endpoint-url' => composition_attachments_path,
        'hidden-field-prefix' => field_name
      }.merge(attachment_data_attrs(attachment))
    )
    # rubocop:enable Rails/UnknownEnv
  end

  # Returns AI configuration for a student in a section
  # If no student config or section is found, use the activity's XML default input mode and audio transcript
  def current_student_section_ai_config(section_id, user, activity: nil)
    return default_ai_config(activity) unless user && section_id

    section = Section.find_by(id: section_id)
    return default_ai_config(activity) unless section

    student_config = StudentSectionConfig.find_by(section_id:, user_id: user.id)

    {
      inputMode: determine_input_mode(student_config, section),
      allowAudioTranscript: determine_audio_transcript(student_config, section)
    }
  end

  private def default_ai_config(activity)
    return {} unless activity&.content_object&.item&.first

    # If no student config or section is found, use the activity's XML default input mode and audio transcript
    {
      inputMode: activity.content_object.item.first.input_mode,
      allowAudioTranscript: activity.content_object.item.first.allow_audio_transcript
    }
  end

  private def determine_input_mode(student_config, section)
    student_config&.input_mode || section.input_mode
  end

  private def determine_audio_transcript(student_config, section)
    if student_config&.audio_transcript.nil?
      section.audio_transcript
    else
      student_config.audio_transcript
    end
  end

  def show_attachment_info(section, attachment)
    download_link = link_to(attachment.file_name,
                            section_composition_attachment_path(section, attachment), target: '_blank', rel: 'noopener')
    file_size_info = number_to_human_size(attachment.file_size)
    remove_link = link_to('Remove uploaded file', composition_attachment_path(attachment),
                          class: 'remove_attachment_link')
    content_tag(:div, class: 'composition_link_container') do
      output = "<div data-container=\"download_link\" class=\"composition_download\">#{download_link}</div>"
      output << "<div data-container=\"file_size\" class=\"composition_file_size\">(#{file_size_info})</div>"
      output << "<div data-container=\"remove_link\" class=\"remove_link_container\">#{remove_link}</div>"
      output.html_safe
    end
  end

  def format_lesson_and_strand_header(current_lesson_label, activity_list_header)
    full_header = "#{current_lesson_label} | #{activity_list_header}"
    max_header_length = 55
    if full_header.length < max_header_length
      "<span class=\"current_strand_lesson\">#{current_lesson_label}</span>| #{activity_list_header}".html_safe
    else
      pipe_index = activity_list_header.rindex(/\|/)
      if pipe_index.present?
        first_activity_header = activity_list_header.slice(0, pipe_index + 1)
        second_activity_header = activity_list_header.slice(pipe_index + 2,
                                                            activity_list_header.length)
        "<span class=\"current_strand_lesson\">#{current_lesson_label}</span>| #{first_activity_header}<br/>#{second_activity_header}".html_safe
      else
        "<span class=\"current_strand_lesson\">#{current_lesson_label}</span>|<br/>#{activity_list_header}".html_safe
      end
    end
  end

  def show_accent_bar_for_activity?(enable_accentbar, activity)
    enable_accentbar && activity.activity_content.present? && !activity.santillana?
  end

  def get_activity_shell_icon_path(icon_file)
    supersites_path = 'activity-shell'
    jr_path = 'jr/activity-shell'
    subdir = supersite_junior? ? jr_path : supersites_path
    "music/features/#{subdir}/icons/#{icon_file}"
  end

  def format_activity_rubric_icon
    feature_icon(
      'music/features/activity-shell/icons/icon-external-reference'
    )
  end

  private def attachment_data_attrs(attachment)
    if attachment
      {
        'attachment-download-url' => section_composition_attachment_path(
          current_section,
          attachment
        ),
        'attachment-file-name' => attachment.file_name,
        'attachment-file-size' => attachment.file_size,
        'attachment-id' => attachment.id
      }
    else
      { 'attachment-id' => '' }
    end
  end

  private def component_display_name(activity, use_component_name)
    if activity.instructor_created? || use_component_name || activity.strand_singular_label.blank?
      activity.component_name
    else
      activity.strand_singular_label
    end
  end

  def title_and_dl_audio_paths(activity)
    audio_paths = []
    audio_paths << activity.title_audio_filepath if activity.title_audio_filepath.present?
    if activity.direction_line_audio_filepath.present?
      audio_paths << activity.direction_line_audio_filepath
    end
    audio_paths
  end

  # Removes any <br> tags, but preserves other html. e.g. w/ a title like:
  # "Estructura<br />The present tense of <b>ir</b>" it returns
  # "Estructura The present tense of <b>ir</b>"
  def single_line_title(title)
    sanitize(
      title.gsub(%r{<br */? *>}, ' ').squish,
      tags: %w[b i em span strong],
      attributes: %w[lang]
    )
  end
end
