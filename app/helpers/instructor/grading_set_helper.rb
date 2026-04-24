module Instructor::GradingSetHelper

  def format_points_earned(points)
    return '' if points == nil
    points
  end

  def format_original_answer_student_link(view_manager)
     link_to("Show student's original answer", '#',
          :id => "#{view_manager.current_response_id}_original_response_link",
          :class => "original_answer_image",
          'data-original-response-selector' => "#{view_manager.current_response_id}_student_response",
          'data-original-response-label' => "#{view_manager.current_student.full_name} - Question #{view_manager.question_number}",
          'data-editor-id' => "#{view_manager.current_response_id}_student_response")
  end
end
