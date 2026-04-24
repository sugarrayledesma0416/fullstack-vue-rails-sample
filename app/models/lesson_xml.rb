
module LessonXML
  def from_xml
    parser = LessonXMLParser.new(toc_entries_xml)
    @toc_entries = parser.parse
    unless @toc_entries
      raise parser.errors.join("\n")
    end
  end
  
  def to_xml
    return true unless @toc_entries
    doc = Nokogiri::XML::Document.new
    root = Nokogiri::XML::Node.new("lesson", doc)
    @toc_entries.each do |toc_entry|
      root << toc_entry_to_xml(toc_entry, doc)
    end
    doc << root
    write_attribute(:toc_entries_xml, doc.to_s)
    true
  end

  def toc_entry_to_xml(toc_entry, doc)
    node = Nokogiri::XML::Node.new("toc_entry", doc)
    node["title"] = toc_entry.title
    node["short_title"] = toc_entry.short_title if toc_entry.short_title.present?
    node["background_color"] = toc_entry.background_color if toc_entry.background_color.present?
    node["location"] = toc_entry.location.to_s
    node["singular_label"] = toc_entry.singular_label if toc_entry.singular_label.present?
    node['assessment'] = toc_entry.assessment? ? 'true' : 'false'
    node["page"] = toc_entry.page.to_s if toc_entry.page
    toc_entry.children.each do |child|
      case child
      when TocEntry
        node << toc_entry_to_xml(child, doc)
      end
    end
    node 
  end
end
