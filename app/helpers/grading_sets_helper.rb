module GradingSetsHelper

  def format_progress_box_class(status_hash, on_current_question_or_student = false)
    css_class_attr = status_hash[:status_class]
    css_class_attr << ' current' if on_current_question_or_student
    css_class_attr
  end

  def format_progress_box_style(concept_color, on_current_question_or_student)
    unless concept_color.blank?
      if on_current_question_or_student
        "background-color: #{concept_color};"
      else
        "border-color: #{concept_color}; width: 23px;"
      end
    end
  end

  def format_progress_status(status_hash, student_or_question, on_current_student_or_question)
    status_class = format_progress_box_class(status_hash, on_current_student_or_question)
    if status_class == 'complete'
      'Complete'
    else
     "#{pluralize(status_hash[:remaining], student_or_question.to_s)} remaining"
    end
  end

  def format_activity_reference(sub_activity, show_auto_graded_questions, activity_rank)
    if sub_activity.instructor_graded? || show_auto_graded_questions
      sub_activity.items.each do |ref|
        next unless ref.is_a?(MaestroActivityEngine::ActivityContent::Reference::Base)
        @output_buffer << 
        case ref.type
        when 'exam'
          format_reference_exam(ref, activity_rank)
        when 'diagnostic'
          format_reference_diagnostic(sub_activity.activity_type, ref, activity_rank, nil, sub_activity.is_bonus, true)
        else 
          format_reference(ref, activity_rank)
        end
      end
    end
  end

end
