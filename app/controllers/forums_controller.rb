class ForumsController < ApplicationController
  before_action :assign_menu_coords
  before_action :require_user
  before_action :require_program_access
  before_action :archived_program_redirect

  before_action :require_instructor_or_grader, except: %i[index show]

  before_action :set_current_program
  before_action :prevent_supersite_junior_access

  before_action :set_current_focus, if: :current_user_is_instructor?
  before_action :assign_course_sections_and_students_from_focus,
                if: :current_user_is_instructor?

  include ForumAccessProtection
  before_action :assign_forum_by_id, only: %i[show edit update destroy]
  before_action :restrict_forum_access, only: %i[show edit update destroy]
  layout 'music_v1/default'

  def index
    @page_title = @page_header = 'Forums'
    # TODO: This is probably complex enough to suggest a presenter.

    # Need to call the var @forum_sections instead of @sections to avoid
    # conflicting w/ @sections assigned by focus.
    with_course_in_focus do
      @forum_sections = sections_for_current_user
      @forums = Forum.where(section_id: @forum_sections).group_by(&:section_id)
    end
  end

  def new
    with_course_in_focus do
      @forum = Forum.new(instructor: current_user, section: current_focus.section)
      setup_new_forum_form
    end
  end

  def create
    @forum = Forum.create(new_forum_params)
    if @forum.persisted?
      flash[:notice] = 'Forum was successfully created!'
      redirect_to forums_path(current_program, current_section)
    else
      setup_new_forum_form
      render :new
    end
  end

  def show
    @presenter = ShowForumPresenter.new(@forum)
    @page_title = @page_header = @forum.name
  end

  def edit
    @page_title = @page_header = 'Edit a Forum'
  end

  def update
    if @forum.update(edit_forum_params)
      redirect_to forums_path(current_program, current_section)
    else
      @page_title = @page_header = 'Edit a Forum'
      render :edit
    end
  end

  def destroy
    @forum.destroy
    flash[:notice] = "Forum '#{@forum.name}' has been deleted."
    redirect_to forums_path(current_program, current_section)
  end

  private def assign_menu_coords
    @menu_location = 'communication'
  end

  private def assign_forum_by_id
    @forum = Forum.find(params[:id])
  end

  private def with_course_in_focus
    yield if !current_user.instructor? || current_focus.has_atleast_one_actionable_section?
  end

  private def sections_for_current_user
    if current_user_is_instructor?
      @course.sections_by_instructor(current_user)
    else
      [current_section]
    end
  end

  private def setup_new_forum_form
    @page_title = @page_header = 'Create a Forum'
    @available_sections = @course.sections_by_instructor(current_user)
    @forum.build_first_post(user: current_user) unless @forum.first_post
  end

  private def new_forum_params
    params.require(:forum).permit(
      :name, :section_id, first_post_attributes: %i[audio_path text]
    ).merge(instructor_id: current_user.id).tap do |memo|
      if memo.key?(:first_post_attributes)
        memo[:first_post_attributes] = memo[:first_post_attributes].merge(
          user_id: current_user.id
        )
      end
    end
  end

  private def edit_forum_params
    params.require(:forum).permit(:name)
  end
end
