class TocController < ApplicationController

  before_action :require_user
  before_action :assign_menu_coords

  include ReturnLink

  include ApplicationHelper
  before_action :require_program_access, except: :strand_permalink
  before_action :archived_program_redirect

  include SectionHeader
  before_action :assign_section_header, only: :show

  include HasHelp
  before_action :contextual_help_url, only: :show
  before_action :set_current_program

  before_action :reroute_instructor, only: :show

  def show
    @page_title = 'Activities'
    @presenter = StudentTocPresenter.new( current_program,
                                          current_user,
                                          current_section,
                                          params,
                                          session[:saved_location],
                                          current_section_id)
    set_return_info('Return to Activities') do
      section_toc_path(current_section, current_program, path_options)
    end
    render :show, layout: 'music_v1/responsive'
  end

  def assign_menu_coords
    @menu_location = 'content'
  end

  def strand_permalink
    lesson = Lesson.find(params[:lesson_id])
    start_unit = lesson.unit.rank
    program = lesson.program
    path_opts = { :display_lesson => params[:lesson_id],
                  :toc_location => params[:toc_location_id],
                  :start_unit => start_unit }
    if current_user.student?
      section = current_user.current_section_in_program(program) || Section.section_zero
      redirect_to section_toc_path(section, program, path_opts)
    else
      redirect_to instructor_toc_path(program, path_opts)
    end
  end

  def reroute_instructor
    redirect_to instructor_toc_path(current_program) if current_user.instructor?
  end

end
