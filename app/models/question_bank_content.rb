class QuestionBankContent
  include JsonContent
  include ActivityContent

  attr_accessor :activity_id, :revision_id

  def initialize(revision_id, activity_id)
    self.activity_id = activity_id
    self.revision_id = revision_id
  end

  def parse_content
    build_from_json
  end

  private def revision_class
    QuestionBankRevision
  end
end
