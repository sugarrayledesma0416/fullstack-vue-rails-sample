class CmsActivityContent
  include ActivityContent

  def initialize(revision_id, cdn, activity_id, program = nil)
    @revision_id = revision_id
    @cdn = cdn
    @activity_id = activity_id
    @program = program
  end

  def parse_content
    @content = content
    if parsed_content_json
      MaestroActivityEngine::ActivityParser.linked_media_item_class = MediaLink
      type = parsed_content_json['activity_type']
      type = 'drop_down' if type == 'drop_down_same'
      content_class = "MaestroActivityEngine::ActivityContent::#{type.camelize}Content".constantize
      content_class.from_json(decode_content_html_entities)
    else
      parse_content_xml(@content, @program)
    end
  end

  def cache_key_prefix
    'cms'
  end

  def instructor_created?
    false
  end

  # Returns content json in stringified form based on the check if its a
  # valid json
  def content_json
    @content_json ||= parsed_content_json.to_json if parsed_content_json
  end

  # Returns Hash or Array if @content is a json. For a xml content null value will be returned.
  private def parsed_content_json
    @parsed_content_json ||= JSON.parse(@content) if @content
  rescue JSON::ParserError
    nil
  end

  # Decoding the prompt inputs because they contain encoded html string.
  def decode_content_html_entities
    nbsp_text = Nokogiri::HTML('&nbsp;').text

    # Nokogiri::XML.parse is adding extra </br> tag for each <br> which is
    # interpreted as extra line space by the erb. So replacing <br> with <br/>
    # so that extra line space does not appear while rendering.
    parsed_json = JSON.parse(@content.gsub('&amp;nbsp;', nbsp_text).gsub('<br>', '<br/>'))
    parsed_json.to_json
  end
end
