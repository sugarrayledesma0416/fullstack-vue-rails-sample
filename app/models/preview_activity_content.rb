class PreviewActivityContent < CmsActivityContent
  attr_accessor :xml_content

  def initialize(revision_id, program)
    @revision_id = revision_id
    @cdn = false
    super(@revision_id, @cdn, nil, program)
  end

  def content=(content)
    self.xml_content = content
  end

  def content
    xml_content
  end
end
