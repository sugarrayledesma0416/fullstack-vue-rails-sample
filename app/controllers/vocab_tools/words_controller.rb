# encoding: utf-8

module VocabTools
  class WordsController < ApplicationController
    include ApplicationHelper
    include VocabSecurity

    before_action :require_user
    before_action { |controller| controller.require_vocab_license('Vocabulary Tools') }
    before_action :set_page_header
    before_action :assign_menu_coords

    def set_page_header
      return if ssjr_student?

      @page_title = current_program.vocab_tools_label
      @return_label = 'Return to Dashboard'
      @return_url = if current_user.instructor?
                      instructor_dashboard_path(current_program.id)
                    elsif current_section == Section.section_zero
                      no_section_student_dashboard_path(current_section, current_program)
                    else
                      student_dashboard_path(current_program, current_section)
                    end
    end

    def index
      @no_focus = true
      @words_data = {
        words_data: VocabToolsWordsPresenter.new(current_user, current_program, params).payload,
        course_data: VocabToolsUnitsPresenter.new(current_section, current_program).payload
      }
      redirect_to_vocab_words
    end

    private def redirect_to_vocab_words
      respond_to do |format|
        if ssjr_student?
          format.html { render 'layout': 'music_v1/default' }
        else
          format.html { render 'layout': 'music_v1/responsive' }
        end
        format.json do
          render json: @words_data
        end
      end
    end

    private def assign_menu_coords
      @menu_location = 'teaching'
    end
  end
end
