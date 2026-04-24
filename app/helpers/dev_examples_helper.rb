module DevExamplesHelper
  include ActionView::Helpers::TagHelper
  require 'rouge'

  def rouge(text, language = 'vue')
    formatter = Rouge::Formatters::HTML.new
    formatter = Rouge::Formatters::HTMLLineTable.new(formatter)
    lexer = Rouge::Lexer.find(language)
    formatter.format(lexer.lex(text))
  end

  def heredoc_linerange(doc, heredoc)
    heredoc_nodes = doc.xpath('//tr').select do |node|
      node.to_html =~ /# #{heredoc}/
    end
    
    heredoc_lines = heredoc_nodes.map do |node|
      node['id'].split('-')[1].to_i
    end

    startline = heredoc_lines[0] + 1
    endline = heredoc_lines[-1] - 1

    startline..endline
  end

  def remove_lines_not_in_range(doc, line_range)
    tr_node_count = doc.xpath('//tr').count

    ((1..tr_node_count).to_a - line_range.to_a).each do |line|
      doc.xpath("//tr[@id='line-#{line}']").remove
    end
  end

  def assign_start_and_end_lines(line_range)
    startline = line_range.first

    if line_range.last != startline
      endline = line_range.last
    end

    if endline == startline
      endline = nil
    end

    [startline, endline]
  end

  def format_code_listing(filepath:, doc:, line_range:)
    startline, endline = assign_start_and_end_lines(line_range) if line_range

    label_text = filepath
    label_text = "#{label_text}:#{startline}" if startline
    label_text = "#{label_text}-#{endline}" if endline
    label = content_tag(:pre, label_text)

    remove_lines_not_in_range(doc, line_range) if line_range

    formatted_example = content_tag(
      :div,
      raw(doc.to_html),
      class: 'highlight'
    )

    raw(
      content_tag(
        :div,
        raw("#{label} #{formatted_example}"),
        class: 'code-listing'
      )
    )
  end

  def code_example(filepath, language, line_range: nil, heredoc: nil)
    code = File.read(filepath)
    doc = Nokogiri::HTML(rouge(code, language))

    if heredoc
      line_range = heredoc_linerange(doc, heredoc)
    end

    format_code_listing(
      filepath: filepath,
      doc: doc,
      line_range: line_range
    )
  end
end
