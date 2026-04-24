RSpec.describe SortInstructorByRole do
  describe '#call' do
    let(:instructor_1) { create(:instructor, email: 'instructor1@example.com') }
    let(:instructor_2) { create(:instructor, email: 'instructor2@example.com') }
    let(:instructor_3) { create(:instructor, email: 'instructor3@example.com') }
    let(:empty_section) { create(:section) }
    let(:section) { create(:section, instructor: instructor_3) }

    before do
      create(:section_instructor, section: section, instructor: instructor_1, role: 'Assistant')
      create(:section_instructor, section: section, instructor: instructor_2, role: 'Co-instructor')
    end

    it 'returns instructors ordered by role priority (Instructor, Co-instructor, Assistant)' do
      result = SortInstructorByRole.new(section).call

      expect(result).to eq(
        [
          { instructor: instructor_3, role: 'Instructor' },
          { instructor: instructor_2, role: 'Co-instructor' },
          { instructor: instructor_1, role: 'Assistant' },
        ]
      )
    end

    it 'only returns the owner if the section has no additional instructors' do

      result = SortInstructorByRole.new(empty_section).call

      expect(result).to eq([{ instructor: empty_section.instructor, role: 'Instructor' }])
    end
  end
end
