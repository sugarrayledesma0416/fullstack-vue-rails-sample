
module AssignmentHelper
  def format_assignment_description(assignment)
    assignment.assignable.title
  end

  def return_min_of(a,b)
    return a if a < b
    b
  end

  def format_grade_availability_text(grade_availability, grade_available_at, due_date)
    text_prefix = "Students will be able to see their grades"

    case grade_availability
      when :on_release
        "#{text_prefix} when I release them"
      when :on_due_date
        "#{text_prefix} after #{due_date.strftime("%a, %b #{due_date.day.ordinalize} %I:%M %p")}"
      when :on_specific_date
        if grade_available_at.present?
          "#{text_prefix} after #{grade_available_at.strftime("%a, %b #{grade_available_at.day.ordinalize} %I:%M %p")}"
        else
          "#{text_prefix} when all students have been graded"
        end
      when :never
        "#{text_prefix} never"
      else
        "#{text_prefix} when all students have been graded"
    end
  end

  def get_assignment_filter_focus_on_me(current_count,total_count,delta,pos)
    case pos
    when 'top'
      return "dont_focus_on_me"
    when 'bottom'
      return "dont_focus_on_me" if current_count <= delta
      return "focus_on_me"
    end
  end

  def format_toc_assignment_info(assignments)
    out = ''
    current_date = nil
    assignments.sort { |a,b| a.due_date <=> b.due_date }.each do |assignment|
      if current_date != assignment.due_date
        out << "</ul>\n" if current_date
        out << "<ul>\n"
        out << "  <li class='due_date'>#{format_toc_due_date(assignment)}</li>\n"
        out << "  <li class='section_name'>#{assignment.section_name}</li>\n"
        current_date = assignment.due_date
      else
        out << "  <li>#{assignment.section_name}</li>\n"
      end
    end
    out << "</ul>\n" if out != ''
    content_tag('div', out.html_safe, :id => "tooltip_toc_activity_due_date_#{assignments[0].id}", :class => 'toc_activity_due_date_info')
  end

  def format_toc_due_date(assignment, is_student = false, attempt_status = 'complete')
    assign_date = ''
    supplement = ''
    if assignment.present?
      if assignment.is_a?(Array)
        div_id = assignment[0].id
        assign_date = 'varies'
        supplement = format_toc_assignment_info(assignment)
      else
        div_id = assignment.id
        assign_date = format_date_time(assignment.due_date, :toc_due_date)
        if is_student
          assign_date = format_due_date_if_late(assignment.due_date, assign_date, attempt_status)
        end
      end
    end
    content_tag('div', assign_date, :id => "toc_activity_due_date_#{div_id}", :class => 'toc_activity_due_date') + supplement
  end

  def assignment_by_due_date(sections,assignments,activity)
    activity_assignments = assignments.select {|assignment| assignment.assignable_id == activity.id}
    assignments_by_due_date = []
    due_date_hash = {}
    activity_assignments.each do |assignment|
      if due_date_hash.has_key?(assignment.due_date.to_date.to_s)
         due_date_hash[assignment.due_date.to_date.to_s][:sections] << assignment.section
         due_date_hash[assignment.due_date.to_date.to_s][:assignments] << assignment
      else
         due_date_hash[assignment.due_date.to_date.to_s] = {}
         due_date_hash[assignment.due_date.to_date.to_s][:sections] = [assignment.section]
         due_date_hash[assignment.due_date.to_date.to_s][:assignments] = [assignment]
         due_date_hash[assignment.due_date.to_date.to_s][:reference_assignment] = assignment
         due_date_hash[assignment.due_date.to_date.to_s][:due_date] = assignment.due_date.to_date.to_s
      end
    end

    due_date_hash.each do | key,value|
      assignments_by_due_date << value
    end
    assignments_by_due_date.sort!{ |a,b| a[:due_date] <=> b[:due_date] }
  end

  def format_due_date_if_late(datetime, str, status)
    if ([:unopened, :opened, :reset].include?(status)) && datetime.to_date < Time.zone.now.to_date
      str = content_tag('span', str, :title => 'Overdue', :class => 'overdue_assignment_date')
    end
    str
  end

  def format_assessment_url(assignments, activity)
    return '' if assignments.blank?
    activity_assignments = assignments.where(assignable: activity)
    activity_assignments.present? ? activity_assignments.map(&:id).join('-') : assignments.first.id
  end

  def format_assessment_strand_label(assessment)
    return '' unless assessment
    if assessment.strand_singular_label.blank?
      ''
    else
      assessment.strand_singular_label.capitalize
    end
  end

  def category_for_assignment(categories, program_id, course)
    case categories.size
    when 0
      link_to 'add category',
              "#{edit_instructor_course_path(program_id, course)}#/gradebook",
              "data-link-type" => "edit course"
    when 1
      category = categories.first
      "#{category.name} #{hidden_field_tag 'activity_assignment[category_id]', category.id}".html_safe
    else
      options = options_from_collection_for_select(categories, 'id', 'name')
      select_tag('activity_assignment[category_id]', options, include_blank: true)
    end
  end
end
