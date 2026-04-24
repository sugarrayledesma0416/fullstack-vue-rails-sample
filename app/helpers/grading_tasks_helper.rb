module GradingTasksHelper
  def format_student_count_list(student_list,count)
     students_count = student_list.count
     count = 'All' if count == 'All' && students_count <= count.to_i
     students_count -=1 unless students_count == 1
     options_for_select(((['All'] << (1..(students_count)).to_a).flatten), (count == 'All')? count: count.to_i)
  end

  def format_lesson_strand_label(activity)
    lesson_strand_label = activity.lesson_strand_label.present? ? "| #{activity.lesson_strand_label}" : ''

    "<span class='lesson_spanner  u-txt-14' style='border-left: 0.25rem solid #{activity.concept.background_color}'> \
     <strong>#{activity.lesson.display_name}</strong> #{lesson_strand_label}</span>".html_safe
  end

  def format_grading_count(number_graded, task_type)
    case task_type
    when GradingTask::ALREADY_GRADED then "#{number_graded} already graded"
    else "#{number_graded} to be graded"
    end
  end

  def format_submitted_count(counts, task_type)
    case task_type
    when GradingTask::UNASSIGNED_ACTIVITIES then "#{counts[:submitted_count]} submitted"
    else "#{counts[:submitted_count]} of #{counts[:assigned_count]} submitted"
    end
  end
end
