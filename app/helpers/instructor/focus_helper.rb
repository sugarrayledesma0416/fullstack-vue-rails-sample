module Instructor::FocusHelper
  def focus_json
    if current_focus.course
      JSON.generate(course: current_focus.course.id,
                    section: current_focus.section_id)
    end
  end
end
