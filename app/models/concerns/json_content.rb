module JsonContent
  extend ActiveSupport::Concern

  def content_json
    return @content_json if defined?(@content_json)

    @content_json = current_revision.try(:content_json)
  end

  private def current_revision
    revision_class.find_by(id: revision_id)
  end

  private def revision_class
    raise NotImplementedError, 'revision_class method must be defined'
  end

  private def build_from_json
    MaestroActivityEngine::ActivityParser.linked_media_item_class = MediaLink
    type = JSON.parse(content_json)['activity_type']
    type = 'drop_down' if type == 'drop_down_same'
    content_class = "MaestroActivityEngine::ActivityContent::#{type.camelize}Content".constantize
    content_class.from_json(content_json)
  end
end
