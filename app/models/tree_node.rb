class TreeNode
  attr_reader :object
  attr_accessor :children

  def initialize(object)
    @object = object
    @children = []
  end
end
