module FixProgram
  class ConceptColors
    TOC_ENTRY_COLORS = [
      '#ED1C24',
      '#007DC6',
      '#E0861B',
      '#17A46A',
      '#5B57A6',
      '#FFD503'
    ].freeze

    STRAND_COLORS = {
      'contextos' => '#ED1C24',
      'fotonovela' => '#76377C',
      'pronunciación' => '#76377C',
      'pronunciaci&#xF3;n' => '#76377C',
      'cultura' => '#DA9A22',
      'estructura' => '#3A7CC0',
      'adelante' => '#4DA75E',
      'flash cultura' => '#DA9A22',
      'panorama' => '#4DA75E',
      'vocabulario' => '#FFCC00'
    }.freeze

    def initialize(program)
      if program.title.match(/vistas/i) || program.title.match(/panorama/i)
        update_toc_entry_background_colors(program.id)
      end
    end

    private def update_toc_entry_background_colors(program_id)
      Unit.where(program_id: program_id).each do |unit|
        unit.lessons.each do |lesson|
          color_index = 0
          doc = Nokogiri::XML.parse(lesson.toc_entries_xml)
          doc.search('toc_entry').each do |toc_entry|
            title = toc_entry.attributes['title'].value
            background_color = TOC_ENTRY_COLORS[color_index]
            background_color = STRAND_COLORS[title] if STRAND_COLORS[title]

            unless toc_entry.attributes['background_color']
              toc_entry.set_attribute('background_color', background_color)
            end

            if toc_entry.attributes['location']
              concept = Concept.find_by(id: toc_entry.attributes['location'].value)
              concept&.update!(background_color: background_color)
            end
            color_index = (color_index >= TOC_ENTRY_COLORS.length - 1 ? 0 : color_index + 1)
          end
          lesson.update!(toc_entries_xml: doc.to_xml)
        end
      end
    end
  end
end
