
class LessonXMLParser

  include MaestroActivityEngine::XMLParser

  attr_accessor :errors

  def initialize(xml)
    @errors = Array.new
    begin
      @doc = Nokogiri::XML.parse(xml, nil, nil, Nokogiri::XML::ParseOptions::STRICT)
    rescue Nokogiri::XML::SyntaxError => e
      @doc = Nokogiri::XML.parse(xml)
      @errors << "There was a syntax error.\n" + e.message + "on line: #{e.line}"
    end
  end

  def parse
    return nil unless @doc
    begin
      item = parse_root_node(@doc)
    rescue ParserException => e
      @errors << e.message
    end

    if @errors.length > 0
      nil
    else
      item
    end
  end

  def common_parser_spec
    {:children => {:toc_entry => "*"}}
  end

  def parse_lesson(node)
    @level = 1
    params = yield(common_parser_spec)
    if params
      params[:children]
    else
      []
    end
  end

  def parse_toc_entry(node)
    toc_entry = TocEntry.new
    toc_entry.title = node["title"]
    toc_entry.short_title = node["short_title"]
    toc_entry.location = node["location"]
    toc_entry.singular_label = node["singular_label"]
    toc_entry.background_color = node["background_color"]
    toc_entry.page = node["page"].to_i if node.has_attribute?("page")  && node["page"] =~ /^\d+$/
    toc_entry.assessment = (node.has_attribute?('assessment') && node['assessment'] == 'true')
    toc_entry.level = @level
    @level += 1
    params = yield(common_parser_spec)
    @level -= 1
    toc_entry.children = params[:children] if params
    toc_entry
  end

end
