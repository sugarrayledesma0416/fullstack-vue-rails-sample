describe ProgramToProgramMappingPresenter do
  let(:dest_program) { create(:program_with_toc_entries) }
  let(:src_program) { create(:program_with_toc_entries) }
  let(:presenter) { described_class.new(dest_program) }

  describe 'mapping_src_programs_array' do
    context 'when populating src program dropdown' do
      it 'returns all programs matching destination program language code' do
        programs = []
        3.times do
          programs << create(:program_with_toc_entries)
        end

        programs.each do |p|
          3.times { create(:concept, program: p) }
        end
        prog_array = programs.sort_by(&:title).collect do |program|
          [program.title.html_safe, program.id]
        end << ['No Mapping', 0]
        expect(presenter.mapping_src_programs_array).to eq prog_array
      end
    end
  end

  describe 'mapping_src_lessons_strands' do
    context 'when selecting a source program' do
      it 'returns all lessons and strands for the specified program' do
        3.times { create(:concept, program: src_program, lesson: src_program.lessons.first) }

        mapping_src_lessons_strands = src_program.lessons.map do |lesson|
          {
            concepts: lesson.strands(true).map { |s| { id: s.location.to_i, name: s.title } },
            name: lesson.name
          }
        end

        expect(presenter.mapping_src_lessons_strands(src_program))
          .to eq mapping_src_lessons_strands
      end
    end
  end

  describe 'mapping_dest_lesson_strands' do
    context 'when selecting a destination lesson' do
      it 'returns all lessons and strands for the specified program' do
        3.times { create(:concept, program: dest_program, lesson: dest_program.lessons.first) }

        mapping_dest_lesson_strands = dest_program.lessons.first.strands(true).map do |concept|
          {
            id: concept.location.to_i,
            name: concept.title
          }
        end

        expect(presenter.mapping_dest_lesson_strands(dest_program.lessons.first.id))
          .to eq mapping_dest_lesson_strands
      end
    end
  end

  describe 'current_dest_for_src' do
    context 'when checking if a source program has a mapping to another destination' do
      it 'returns the id and name of the destination program for the provided source' do
        mappings = []
        src_program.lessons.first.strands(true).each do |strand|
          concept = create(:concept, program: src_program, lesson: src_program.lessons.first, id: strand.location.to_i)
          mappings << create(:program_to_program_mapping, src_strand: concept)
        end

        dest_for_src = {
          id: mappings.first.dest_program.id,
          name: mappings.first.dest_program.title
        }

        expect(presenter.current_dest_for_src(src_program.id)).to eq dest_for_src
      end
    end
  end

  describe 'current_mappings' do
    it 'returns all current mappings for the given destination program' do
      mappings = []
      3.times do
        mappings << create(:program_to_program_mapping, dest_program: dest_program)
      end

      expect(presenter.current_mappings).to eq mappings
    end
  end

  describe 'mapping_src_prog_id' do
    context 'when there is no existing mapping' do
      it 'returns the source program id as an empty string' do
        expect(presenter.mapping_src_prog_id).to eq ''
      end
    end

    context 'when there is an existing mapping' do
      it 'returns the source program id for the given destination program' do
        mapping = create(:program_to_program_mapping, dest_program: dest_program)
        expect(presenter.mapping_src_prog_id).to eq mapping.src_strand.program.id
      end
    end
  end

  describe 'strands_for_lesson_array' do
    it 'returns an array of concept ids and names for a lesson' do
      3.times { create(:concept, program: dest_program, lesson: dest_program.lessons.first) }
      strands_array = dest_program.lessons.first.strands(true).collect { |c| [c.title, c.location.to_i] }
      expect(presenter.strands_for_lesson_array(dest_program.lessons.first.id)).to eq strands_array
    end
  end

  describe 'lessons_for_dest_program_array' do
    it 'returns an array of lesson ids and names for a program' do
      lessons_array = dest_program.lessons.collect { |l| [l.name, l.id] }
      expect(presenter.lessons_for_dest_program_array).to eq lessons_array
    end
  end

  describe 'strands_for_dest_lesson_array' do
    it 'returns an array of destination strands for a lesson given a source strand id' do
      src_program.lessons.each do |sl|
        sl.strands.each { |ss| create(:concept, program: src_program, lesson: sl, id: ss.location.to_i) }
      end

      dest_program.lessons.each do |dl|
        dl.strands.each { |ds| create(:concept, program: dest_program, lesson: dl, id: ds.location.to_i) }
      end

      mapping = create(:program_to_program_mapping, dest_program: dest_program,
                       src_strand_id: src_program.lessons.first.strands.first.location.to_i,
                       dest_strand_id: dest_program.lessons.first.strands(true).first.location.to_i)

      strands_array = mapping.dest_strand.lesson.strands(true).collect { |c| [c.title.html_safe, c.location.to_i] }
      expect(presenter.strands_for_dest_lesson_array(mapping.src_strand.id)).to eq strands_array
    end

    it 'returns an empty string if there are no destination strands for the source strand id' do
      src_strand = create(:concept,
                          program: src_program,
                          lesson: src_program.lessons.first,
                          id: src_program.lessons.first.strands(true).first.location.to_i)

      expect(presenter.strands_for_dest_lesson_array(src_strand.id)).to eq ''
    end
  end

  describe 'destination_for_source_strand' do
    it 'returns a hash of current mappings for use in the view' do
      3.times { create(:program_to_program_mapping, dest_program: dest_program) }
      cmh = dest_program.program_to_program_mappings.each_with_object({}) do |m, h|
        h[m.src_strand_id] = { lesson_id: m.dest_strand.nil? ? '' : m.dest_strand.lesson.id, strand_id: m.dest_strand_id }
      end
      expect(presenter.destination_for_source_strand).to eq cmh
    end
  end

  describe 'map_automatically' do
    it 'returns a hash mapping for the source and destination programs' do
      src_program.lessons.each do |src_lesson|
        src_lesson.strands.each { |src_lesson_strand| create(:concept, program: src_program, lesson: src_lesson, id: src_lesson_strand.location.to_i) }
      end

      dest_program.lessons.each do |dest_lesson|
        dest_lesson.strands.each { |dest_lesson_strand| create(:concept, program: dest_program, lesson: dest_lesson, id: dest_lesson_strand.location.to_i) }
      end
      auto_map = {}
      src_program.lessons.each_with_index do |src_lesson, src_lesson_index|
        src_lesson.strands(true).each_with_index do |strand, strand_index|
          auto_map[strand.location.to_i] = { dest_lesson_id: dest_program.lessons[src_lesson_index].id,
                                             dest_strand_id: dest_program.lessons[src_lesson_index].strands(true)[strand_index].location.to_i }
        end
      end
      expect(presenter.map_automatically(dest_program.id, src_program.id)).to eq auto_map
    end
  end
end
