class InstitutionAdmin::AssessmentTemplatesController < Instructor::AssessmentsController
  include TemplateFocusable

  before_action :show_templates_return_bar

  def index
    @page_title = 'Assessments'
    @presenter = InstitutionAdminAssessmentTocPresenter.new(@program,
                                                           current_focus,
                                                           current_user,
                                                           params,
                                                           session)
    set_return_info('Return to Assessment') do
      institution_admin_assessment_template_path(current_program, path_options)
    end
    @path_options = path_options if path_options
    render 'show'
  end
end
