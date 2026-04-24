describe StudentSorter do
  let(:course) { create(:course) }
  let(:section) { create(:section, course: course) }
  let(:student_sorter) { StudentSorter.new([section]) }

  describe '#section_students' do
    let(:students) do
      [build_stubbed(:student, last_name: 'b', first_name: 'z')]
    end

    it 'decorates student instances' do
      expected = double(GradebookStudent)
      expect(Student).to receive(:enrolled_in_sections)
        .with([section])
        .and_return(students)
      expect(GradebookStudent).to receive(:decorate).with(
        students, section.program, [section]
      ).and_return(expected)
      expect(student_sorter.section_students).to eql expected
    end
  end

  describe '#students' do
    let(:student_1) { build_stubbed(:student, last_name: 'b', first_name: 'z') }
    let(:student_2) { build_stubbed(:student, last_name: 'A', first_name: 'y') }
    let(:student_3) { build_stubbed(:student, last_name: 'a', first_name: 'x') }

    before do
      allow(student_sorter).to receive(:section_students).and_return(
        [student_1, student_2, student_3]
      )
    end

    context 'in the default direction' do
      it 'returns students sorted by name, regardless of case' do
        expect(student_sorter.students).to eq([student_3, student_2, student_1])
      end
    end

    context 'in the desc direction' do
      it 'returns students sorted by name, regardless of case' do
        allow(student_sorter).to receive(:direction).and_return('desc')
        expect(student_sorter.students).to eq([student_1, student_2, student_3])
      end
    end
  end
end
