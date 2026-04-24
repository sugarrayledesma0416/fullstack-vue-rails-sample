module TemplateFocusable
  extend ActiveSupport::Concern

  included do
    # The institution-admin controllers that mix in this concern inherit from
    #   instructor controllers with before_actions that depend on the session
    #   focus setting. In Rails 5, the parent-class before_actions run before
    #   the child-class before_actions. `prepend_before_action` overrides that
    #   behavior and puts :set_session_focus ahead of the parent-class
    #   callbacks.
    prepend_before_action :set_session_focus

    before_action :assign_institution_admin_flag
    before_action :hide_program_logo
  end

  private def show_templates_return_bar
    @show_templates_return_bar = true
  end

  private def assign_institution_admin_flag
    @in_institution_admin = true
  end

  private def hide_program_logo
    @hide_header = true
  end

  private def set_session_focus
    return unless params[:program_id]

    @program = Program.find(params[:program_id])

    session[:focus] = {
      params[:program_id] => {
        'course_id' => params[:course_id],
        'section_id' => params[:section_id]
      },
      'template' => true
    }
  end
end
