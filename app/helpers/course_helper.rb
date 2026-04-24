module CourseHelper
  def format_current_school_style(school_id, curr_school_id)
    return 'display:block;'  if school_id == curr_school_id
    return 'display:none;'
  end

  def format_dashboard_selected_course(focus, courses, course)
    selected_course_id = nil
    selected_course_id = focus.course.id if focus && focus.course && focus.course.id
    selected_course_id = courses.first.id if !selected_course_id && !courses.empty?
    if !selected_course_id || (selected_course_id != course.id)
      ''
    else
      'expanded'
    end
  end

  def format_dashboard_selected_section(focus, sections, section)
    selected_section_id = nil
    selected_section_id = focus.section.id if focus && focus.section && focus.section.id
    selected_section_id ||= sections.first.id if sections.present?
    if (focus.type == 'course' || !selected_section_id || (selected_section_id != section.id)) &&
       sections.count > 1
      ''
    else
      'expanded'
    end
  end

  def format_instructor_last_names(section)
    return "" if section.blank?
    last_name_class =  (section.instructors.count > 1) ? 'multiple' : 'single'
    section.instructors.collect do |instructor|
      content_tag(:span, ' ' + instructor.last_name, :class => last_name_class)
    end.join('').html_safe
  end

  def format_previous_course_index(course)
    if course.id.nil?
      if course.name == 'New course name'
        'default'
      else
        'basic'
      end
    else
      course.id
    end
  end

end
