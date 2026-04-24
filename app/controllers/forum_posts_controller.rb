class ForumPostsController < ApplicationController
  before_action :require_user
  before_action :require_program_access

  before_action :set_current_program
  before_action :prevent_supersite_junior_access

  before_action :set_current_focus, if: :current_user_is_instructor?
  before_action :assign_course_sections_and_students_from_focus,
                if: :current_user_is_instructor?

  include ForumAccessProtection
  before_action :assign_forum
  before_action :restrict_forum_access

  layout 'music_v1/default'

  def create
    post = ForumPost.create(safe_reply_params)
    if post.persisted?
      flash[:notice] = 'Your reply was posted.'
      redirect_to_forum_with_anchor(post.parent_id)
    else
      @presenter = ShowForumPresenter.new(@forum, reply: post)
      display_forum
    end
  end

  def update
    post = ForumPost.find(params[:id])
    with_editing_allowed(post) do
      if post.update(safe_update_params)
        flash[:notice] = 'Your edit was saved.'
        redirect_to_forum_with_anchor(post.id)
      else
        @presenter = ShowForumPresenter.new(@forum, edit: post)
        display_forum
      end
    end
  end

  def destroy
    post = ForumPost.find(params[:id])
    with_editing_allowed(post) do
      post.delete!
      redirect_to_forum_with_anchor(post.id)
    end
  end

  private def with_editing_allowed(post)
    if post.user_id == current_user.id
      yield
    else
      redirect_intruder
    end
  end

  private def redirect_to_forum_with_anchor(post_id)
    redirect_to(
      forum_path(current_program.id, current_section, @forum, anchor: "post_id_#{post_id}")
    )
  end

  private def display_forum
    @page_title = @page_header = @forum.name
    render 'forums/show'
  end

  private def safe_update_params
    params.require(:forum_post)
      .permit(:text, :audio_path)
      .merge(edited_at: Time.now)
  end

  private def safe_reply_params
    params.require(:forum_post)
      .permit(:parent_id, :text, :audio_path)
      .merge(user_id: current_user.id, forum_id: @forum.id)
  end

  private def assign_forum
    @forum = Forum.find(params[:forum_id])
  end

end
