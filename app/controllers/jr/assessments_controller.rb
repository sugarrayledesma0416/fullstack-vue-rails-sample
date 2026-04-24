module Jr
  class AssessmentsController < ApplicationController
    include AssessmentHelper

    before_action :require_user

    layout 'music_v1/default'

    def index
      @menu_location = 'content'
      @page_title = 'Assessments'
      @assessments_data = presenter.to_do_and_finished_list

      session[:activity_return] = {
        'label' => 'Return to Assessments',
        'url' => jr_section_assessments_path(section_id: current_section.id)
      }
    end

    private def presenter
      AssessmentsPresenter.new(current_program, current_section, current_user)
    end
  end
end
