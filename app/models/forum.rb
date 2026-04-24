class Forum < ApplicationRecord
  has_many :forum_posts
  has_one :first_post,
          -> { where(original_post: true) },
          class_name: 'ForumPost',
          inverse_of: :forum

  belongs_to :section
  belongs_to :instructor

  validates :instructor_id, :name, :section_id, presence: true

  accepts_nested_attributes_for :first_post

  def posts_tree
    @root_node ||= build_tree
  end

  private def build_tree
    nodes = forum_posts.order('original_post desc, parent_id, created_at')
                       .map { |post| TreeNode.new(post) }
    nodes_by_id = nodes.index_by { |node| node.object.id }
    root_node = nodes.shift
    nodes.group_by { |node| node.object.parent_id }.each do |parent_id, kids|
      nodes_by_id[parent_id].children = kids
    end
    root_node
  end
end
