module GradebookV2Helper
  def no_course_link
    gradebook_engine.no_course_path(current_program.id)
  end

  # This is the main gradebook link from the grades nav.
  def gradebook_link(section_id = nil)
    with_focused_course do |course|
      # if section_id is nil, try to set it from the focus
      section_id ||= current_focus&.section_id

      if section_id
        gradebook_engine.course_section_scores_path(
          current_program.id, course.id, section_id
        )
      else
        # We assume that a course is in focus.
        gradebook_engine.course_path(current_program.id, course.id)
      end
    end
  end

  def analytics_overview_link
    if params[:section_id]
      gradebook_engine.course_section_analytics_overview_path(filter_params)
    else
      analytics_default_link
    end
  end

  def analytics_progress_link
    if params[:section_id]
      gradebook_engine.course_section_analytics_progress_path(filter_params)
    else
      analytics_default_link(feature: 'progress')
    end
  end

  def analytics_practice_test_link
    if params[:section_id]
      main_app.gradebook_practice_test_path(filter_params)
    else
      analytics_default_link
    end
  end

  def analytics_standards_link
    if params[:section_id]
      main_app.gradebook_standards_landing_page_path(filter_params)
    else
      analytics_default_link(feature: 'standards')
    end
  end

  def analytics_default_link(feature: 'analytics')
    gradebook_engine.course_path(
      active_subnav: 'analytics',
      course_id: @course.id,
      feature: feature,
      program_id: current_program.id
    )
  end

  def format_individual_student_link(student_name, student_id, lesson_id)
    link_to(
      student_name,
      format_individual_student_path(student_id, lesson_id),
      target: '_blank',
      rel: 'noopener',
      onclick: format_popup_onclick(
        analytics_popup_params('Practice Test Analytics')
      )
    )
  end

  private def format_individual_student_path(student_id, lesson_id)
    gradebook_individual_student_path(
      current_program,
      course_id: current_focus.course,
      section_id: params[:section_id],
      student_id: student_id,
      lesson_id: lesson_id
    )
  end

  private def analytics_popup_params(window_name)
    {
      window_name: window_name,
      height: 720,
      width: 960
    }
  end

  # The roster count and "view all" in the instructor dashboard
  #   both use this link.
  def roster_link(section_id = nil)
    with_focused_course do
      main_app.section_roster_path(current_program, section_id || current_section)
    end
  end

  private def with_focused_course
    course = focused_course
    if course
      yield course
    else
      no_course_link
    end
  end

  # Go to gradesheet for section, rolling up at the section level
  #   and filtering by given category.
  def gradebook_category_link(section_id, category)
    gradebook_engine.course_section_scores_path(
      current_program.id, category.course.id, section_id,
      category_id: category.id,
      level: 'lesson',
      summary_level: 'section',
      summary_level_id: section_id
    )
  end

  def student_grade_summary_link
    gradebook_engine.section_user_summary_path(current_program.id,
                                               current_section.id,
                                               current_user.id)
  end

  def student_grade_details_link
    gradebook_engine.section_user_details_path(current_program.id,
                                               current_section.id,
                                               current_user.id)
  end

  def focused_course
    (current_focus&.course) || current_user.courses_for_program(current_program).first
  end

  def program_and_course_ids
    { program_id: current_program.id, course_id: current_focus.course.id }
  end

  def late_work_link
    if current_focus.focused_on_only_one_section?
      gradebook_engine.course_section_show_late_work_path(
        program_and_course_ids.merge(section_id: current_section.id)
      )
    else
      gradebook_engine.course_path(
        program_and_course_ids.merge(active_subnav: 'accept_late_work',
                                     feature: 'late work')
      )
    end
  end

  def reports_link
    if current_focus.focused_on_only_one_section?
      gradebook_engine.course_reports_path(
        program_and_course_ids.merge(section_id: current_section.id)
      )
    else
      gradebook_engine.course_show_reports_path(
        program_and_course_ids.merge(active_subnav: 'reports',
                                     feature: 'reports')
      )
    end
  end

  def analytics_link(view = '')
    if current_focus.focused_on_only_one_section?
      if view == 'progress'
        gradebook_engine.course_section_analytics_progress_path(
          program_and_course_ids.merge(section_id: current_section.id)
        )
      elsif view == 'practice_test'
        gradebook_engine.course_section_analytics_practice_test_path(
          program_and_course_ids.merge(section_id: current_section.id)
        )
      elsif view == 'standards'
        main_app.gradebook_standards_section_report_index_path(
          program_and_course_ids.merge(section_id: current_section.id)
        )
      else
        gradebook_engine.course_section_analytics_overview_path(
          program_and_course_ids.merge(section_id: current_section.id)
        )
      end
    else
      gradebook_engine.course_path(
        program_and_course_ids.merge(active_subnav: 'analytics',
                                     feature: 'analytics')
      )
    end
  end

  def filter_params
    GradebookEngine::FilterBar.filter_params_with_course(params, @course)
  end

  def gradebook_practice_test_sort_link(link_text, column, lesson_id, concept = nil)
    if concept.present?
      order = concept_order(concept, column)
      link_to(
        gradebook_practice_test_path(
          lesson_id: lesson_id,
          concept_id: concept.id,
          order: order,
          sort_by: column
        ),
        class: 'sort-link  u-txt-gray-3'
      ) do
        render('column_header_sort_link', link_text: link_text, order: order)
      end
    else
      order = sorted_by?(column) ? opposite_order : :desc
      link_to(
        gradebook_practice_test_path(
          lesson_id: lesson_id,
          order: order,
          sort_by: column
        ),
        class: 'sort-link  u-txt-gray-3'
      ) do
        render('column_header_sort_link', link_text: link_text, order: order)
      end
    end
  end

  def concept_order(concept, column)
    if params[:concept_id].to_i == concept.id && sorted_by?(column)
      opposite_order
    else
      :desc
    end
  end

  def sorted_by?(column_name)
    return false if params[:sort_by].nil?

    column_name == params[:sort_by].to_sym
  end

  def opposite_order
    case params[:order]
    when 'asc'
      :desc
    when 'desc'
      :asc
    else
      :desc
    end
  end
end
