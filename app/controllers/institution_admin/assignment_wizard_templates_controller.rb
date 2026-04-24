class InstitutionAdmin::AssignmentWizardTemplatesController < Instructor::AssignmentWizardController
  include TemplateFocusable

  before_action :show_templates_return_bar

  def create
    result = AssignmentWizardCopier.call(params, :templates)

    if result.success?
      render json: { job_ids: result.job_ids }
    else
      render json: { error: result.message }, status: 500
    end
  end

  private def find_course(course_id)
    Course.find(course_id)
  end
end
