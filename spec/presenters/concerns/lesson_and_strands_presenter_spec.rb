describe LessonAndStrandsPresenter do
  let(:dummy_presenter) do
    Class.new do
      include LessonAndStrandsPresenter

      attr_reader :program

      def initialize(program)
        @program = program
      end
    end
  end

  describe '#lessons' do
    let(:program) { create(:program) }
    let(:unit_1) { create(:unit, program:) }
    let(:unit_2) { create(:unit, program:) }
    let(:lesson_1) { create(:lesson, unit: unit_1) }
    let(:lesson_2) { create(:lesson, unit: unit_2) }
    let(:presenter) { dummy_presenter.new(program) }

    it 'returns an array of hashes with lesson id and label' do
      expected_result = [
        { id: lesson_1.id, label: lesson_1.label },
        { id: lesson_2.id, label: lesson_2.label },
      ]
      expect(presenter.lessons).to match_array(expected_result)
    end
  end

  describe '#strands_by_lesson' do
    let(:program) { create(:program) }
    let(:unit_1) { create(:unit, program:) }
    let(:unit_2) { create(:unit, program:) }
    let(:lesson_1) { create(:lesson_with_toc_entries, unit: unit_1) }
    let(:lesson_2) { create(:lesson_with_toc_entries, unit: unit_2) }
    let(:presenter) { dummy_presenter.new(program) }

    it 'returns an array of hashes with lesson_id and strand_title' do
      expected_result =
        lesson_1.strands.map do |strand|
          { lesson_id: lesson_1.id, title: strand.title, strand_id: strand.location }
        end +
        lesson_2.strands.map do |strand|
          { lesson_id: lesson_2.id, title: strand.title, strand_id: strand.location }
        end
      expect(presenter.strands_by_lesson).to eq(expected_result)
    end
  end
end
