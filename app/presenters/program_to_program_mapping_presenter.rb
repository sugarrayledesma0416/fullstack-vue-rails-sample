class ProgramToProgramMappingPresenter
  attr_accessor :dest_program

  def initialize(dest_program = '')
    self.dest_program = dest_program
    @src_lessons = {}
    @dest_lessons = {}
  end

  def mapping_src_programs_array
    src_programs = Program.joins(:concepts)
                          .where(language_code: dest_program.language_code)
                          .where('programs.id != ?', dest_program.id)
                          .where('maestro_version != ? || maestro_version is null', 2)
                          .order(:title)
                          .group('programs.id')

    src_programs.collect { |s| [s.title.html_safe, s.id] } << ['No Mapping', 0]
  end

  def mapping_src_lessons_strands(src_prog_id = '')
    src_lessons(src_prog_id.blank? ? mapping_src_prog_id : src_prog_id).map do |lesson|
      {
        concepts: mapping_dest_lesson_strands(lesson.id),
        name: lesson.name
      }
    end
  end

  def mapping_dest_lesson_strands(lesson_id)
    lesson = Lesson.find lesson_id
    lesson.strands(true).map { |s| { id: s.location.to_i, name: s.title } }
  end

  # Returns the id and name of the destination program if there is an existing mapping
  #   for the given source program

  def current_dest_for_src(src_program_id)
    current = ProgramToProgramMapping.joins(:src_strand)
                                     .where('concepts.program_id = ?', src_program_id).first
    return '' if current.nil?
    {
      id: current.dest_program.id,
      name: current.dest_program.title
    }
  end

  def current_mappings
    ProgramToProgramMapping.includes(dest_strand: :lesson).where(dest_program_id: dest_program.id)
  end

  def mapping_src_prog_id
    @mapping_src_program_id ||= if current_mappings.empty?
                                  ''
                                else
                                  current_mappings.first.src_strand.program.id
                                end
  end

  # Returns an array of options for strands by lesson for use to populate the
  #   dynamic dropdown in the view.

  def strands_for_lesson_array(lesson_id = '')
    return '' if lesson_id.blank?
    Lesson.find(lesson_id).strands(true).collect { |c| [c.title.html_safe, c.location.to_i] }
  end

  # Returns an array of options for lessons by program for use to populate the
  #   dropdown in the view.

  def lessons_for_dest_program_array
    lessons = dest_lessons(dest_program.id)
    lessons.collect { |l| [l.name.html_safe, l.id] }
  end

  # Returns an array of options for strands by lesson given a current source strand id

  def strands_for_dest_lesson_array(src_strand_id)
    mapping_obj = ProgramToProgramMapping.where(src_strand_id: src_strand_id).first
    dest_lesson_id = mapping_obj&.dest_strand&.lesson&.id
    return '' unless dest_lesson_id
    strands_for_lesson_array(dest_lesson_id)
  end

  # Returns a hash of the current mappings for a program for use in
  #   populating the dropdowns in the view.

  def destination_for_source_strand
    hash_with_defaults = Hash.new { |h, k| h[k] = Hash.new { |h_2, k_2| h_2[k_2] = '' } }
    current_mappings.each_with_object(hash_with_defaults) do |m, h|
      h[m.src_strand_id] = {
        lesson_id: m.dest_strand.nil? ? '' : m.dest_strand.lesson.id,
        strand_id: m.dest_strand_id
      }
    end
  end

  def map_automatically(dest_prog_id, src_prog_id)
    auto_map = {}
    src_lessons(src_prog_id).each_with_index do |sl, sl_index|
      dest_lesson = dest_lessons(dest_prog_id)[sl_index]
      next if dest_lesson.nil?
      ds = mapping_dest_lesson_strands(dest_lesson.id)
      mapping_dest_lesson_strands(sl.id).each_with_index do |sc, sc_index|
        auto_map[sc[:id]] = { dest_lesson_id: dest_lesson.id,
                              dest_strand_id: ds[sc_index].nil? ? '' : ds[sc_index][:id] }
      end
    end

    auto_map
  end

  private def lessons
    @lessons ||= Lesson.joins(:unit)
                       .includes(:concepts)
                       .order('units.rank, lessons.rank')
  end

  private def src_lessons(src_prog_id)
    @src_lessons[src_prog_id] ||= lessons.where(units: { program_id: src_prog_id })
                                  .where.not(toc_entries_xml: nil)
  end

  private def dest_lessons(dest_prog_id)
    @dest_lessons[dest_prog_id] ||= lessons.where(units: { program_id: dest_prog_id })
                                    .where.not(toc_entries_xml: nil)
  end
end
