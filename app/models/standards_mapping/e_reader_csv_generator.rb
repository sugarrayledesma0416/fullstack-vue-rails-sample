module StandardsMapping
  class EReaderCsvGenerator
    EREADER_HEADERS = %w[
      unit_name
      lesson_name
      strand_name
      concept_id
      page_section
      page_number
      title
      descriptor
      domain
      subdomain
      standards_id_list
    ].freeze

    TOC_HEADERS = %w[
      unit_name
      unit_id
      lesson_name
      lesson_id
      concept_name
      concept_id
    ].freeze

    class << self
      def generate_csv_string
        CSV.generate { |csv_data| csv_data << EREADER_HEADERS }
      end

      def generate_toc_csv(program_id)
        program = Program
                  .select(
                    'programs.id',
                    'programs.title'
                  )
                  .includes(lessons: :concepts)
                  .find(program_id)

        CSV.generate(
          write_headers: true,
          headers: [program.title, program.id, '', '', '', '']
        ) do |csv_data|
          csv_data << TOC_HEADERS # the true header row contains program info.
          write_toc_loop(program, csv_data)
        end
      end

      private def write_toc_loop(program, csv_data)
        program.units.each do |unit|
          csv_data << [unit.name, unit.id, '', '', '', '']
          unit.lessons.each do |lesson|
            csv_data << ['', '', lesson.name, lesson.id, '', '']
            lesson.concepts.each do |concept|
              csv_data << ['', '', '', '', concept.name, concept.id]
            end
          end
        end
      end
    end
  end
end
