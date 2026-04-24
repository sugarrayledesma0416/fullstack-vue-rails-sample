class ShowForumPresenter
  def initialize(forum, unsaved_posts = {})
    @forum = forum
    @unsaved_edit = unsaved_posts[:edit]
    @unsaved_reply = unsaved_posts[:reply]
  end

  def has_unsaved_reply?(post)
    unsaved_reply(post).present?
  end

  def reply_for(post)
    unsaved_reply(post) || ForumPost.new(forum_id: @forum.id, parent_id: post.id)
  end

  def has_unsaved_edits?(post)
    unsaved_edit(post).present?
  end

  def edit_for(post)
    unsaved_edit(post) || post
  end

  private def unsaved_reply(post)
    @unsaved_reply if @unsaved_reply && @unsaved_reply.parent_id == post.id
  end

  private def unsaved_edit(post)
    @unsaved_edit if @unsaved_edit && @unsaved_edit.id == post.id
  end
end
