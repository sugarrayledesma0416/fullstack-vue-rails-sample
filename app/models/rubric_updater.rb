class RubricUpdater
  attr_accessor :original_xml, :rubric_json

  LIST_STYLE_MAPPING = {
    'list-style-type: decimal;' => 'decimal',
    'list-style-type: lower-alpha;' => 'lower-alpha',
    'list-style-type: lower-roman;' => 'lower-roman',
    'list-style-type: upper-alpha;' => 'upper-alpha',
    'list-style-type: upper-roman;' => 'upper-roman',
    'list-style-type: disc;' => 'bullet',
    'list-style-type: none;' => 'none'
  }.freeze
  M3_LIST_STYLE_REGEXP = /c-list-reference__list--(?<list_style>.*)/.freeze

  def initialize(original_xml, rubric_json)
    self.original_xml = original_xml
    self.rubric_json = rubric_json
  end

  def new_doc
    rubric_node[:id] = 0
    rubric_node[:rubric_revision_id] = 0

    create_or_update_show_score
    update_headers
    update_rows

    doc
  end

  private def create_or_update_show_score
    style_node = rubric_node.at('style') || rubric_node.add_child('<style />').first
    score_node = style_node.at('show_score') || style_node.add_child('<show_score />').first
    # show_score will always be forced to true no matter what is posted
    score_node.content = 'true'
  end

  private def doc
    @doc ||= Nokogiri::XML.parse(original_xml)
  end

  private def parsed_json
    @parsed_json ||= JSON.parse(rubric_json).deep_symbolize_keys
  end

  # Worth memoizing?
  private def rubric_node
    doc.at('rubric')
  end

  private def update_headers
    header_data = parsed_json.dig(:header_row, :HeaderRow, :header_columns)
    header_row_node = rubric_node.at('header_row')
    header_row_node.xpath('header_column').each(&:unlink)

    header_data.each do |entry|
      new_node = header_row_node.add_child('<header_column />').first
      new_node['id'] = entry[:id]
      new_node.content = entry[:label]
    end
  end

  private def update_rows
    rubric_node.xpath('criteria').map(&:unlink)

    criteria_data = parsed_json[:criterias].map do |entry|
      entry[:Criteria]
    end

    criteria_data.each do |entry|
      new_node = rubric_node.add_child('<criteria />').first
      new_node.add_child('<title />')
      update_criteria_node(new_node, entry)
    end
  end

  private def update_criteria_node(criteria_node, criteria_entry)
    criteria_node.at('title').content = criteria_entry[:title]
    criteria_node.xpath('performance').map(&:unlink)

    criteria_entry[:performances].each do |entry|
      new_description_doc = Nokogiri::XML::DocumentFragment.parse('')
      Nokogiri::XML::Builder.with(new_description_doc) do |new_document|
        clean_desc = entry[:description].gsub('<br>', '<br/>')
        transform_description(
          Nokogiri::XML::DocumentFragment.parse(clean_desc),
          new_document
        )
      end
      new_node = criteria_node.add_child('<performance />').first
      new_node['header_id'] = entry[:header_id]
      new_node.add_child('<description />')
      new_node.add_child('<score />')
      new_node.at('description').inner_html = new_description_doc.to_xml
      new_node.at('score').content = entry[:score]
    end
  end

  private def transform_description(parent_node, new_description_doc)
    parent_node.children.each do |node|
      # We control what type of tags can be used by the instructor via the
      # Froala editor, but just in case, to avoid including in the XML tags
      # that are not supported by the parser, we set here explicitly what tags
      # to translate. Tags that are not in this case statement will be ignored.
      case node.name
      when 'p'
        new_description_doc.p { transform_description(node, new_description_doc) }
      when 'br'
        new_description_doc.br
      when 'strong'
        new_description_doc.important { transform_description(node, new_description_doc) }
      when 'em'
        new_description_doc.emphasis { transform_description(node, new_description_doc) }
      when 'ul', 'ol'
        new_description_doc.sublist(style: translate_list_style(node)) do
          transform_description(node, new_description_doc)
        end
      when 'li'
        new_description_doc.li { transform_description(node, new_description_doc) }
      when 'text'
        new_description_doc.text(node.text)
      end
    end
  end

  private def translate_list_style(list_node)
    matching_style = LIST_STYLE_MAPPING[list_node['style']]
    unless matching_style
      regexp_results = M3_LIST_STYLE_REGEXP.match(list_node['class'])
      matching_style = regexp_results[:list_style] if regexp_results&.captures
    end
    matching_style || (list_node.name == 'ol' ? 'decimal' : 'none')
  end

  private def find_matching_node(nodes, entry, field)
    nodes.find { |node| node[field] == entry[field] }
  end
end
