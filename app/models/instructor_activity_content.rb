class InstructorActivityContent
  include JsonContent
  include ActivityContent

  def initialize(revision_id, cdn, activity_id)
    @revision_id = revision_id
    @cdn = cdn
    @activity_id = activity_id
  end

  def parse_content
    if content_json
      build_from_json
    else
      parse_content_xml
    end
  end

  def cache_key_prefix
    'igc'
  end

  def instructor_created?
    true
  end

  private def revision_class
    InstructorActivityRevision
  end
end
