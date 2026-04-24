module Redirectable
  def return_from_grading_path
    session.delete(:grading_done_return_to) \
      || instructor_grading_tasks_assignments_path(current_program)
  end
end
