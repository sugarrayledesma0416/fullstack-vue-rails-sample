describe StudentAssignmentMap do
  let(:section) { build_stubbed(:section) }
  let(:assignment_1) { build_stubbed(:assignment) }
  let(:assignment_2) { build_stubbed(:assignment) }
  let(:gradebook_api) { GradebookEngine::GradebookAPI }
  let(:student_1) { build_stubbed(:student) }

  before do
    allow(gradebook_api).to receive(:find_submitted).and_return([])
  end

  describe '#assignment_count' do
    it 'returns 0 if nil is specified for assignments' do
      student_assignment_map = described_class.new(
        section, [student_1], nil
      )

      expect(student_assignment_map.assignment_count).to eq(0)
    end

    it 'returns the number of specified assignments' do
      student_assignment_map = described_class.new(
        section, [student_1], [assignment_1, assignment_2]
      )

      expect(student_assignment_map.assignment_count).to eq(2)
    end
  end

  describe '#student_assignment_counts' do
    it 'queries the gradebook api for submitted scores for the section ' \
       'and users and the activity ids of the assignments specified on ' \
       'initialization' do
      student_assignment_map = described_class.new(
        section, [student_1], [assignment_1]
      )

      student_assignment_map.student_assignment_counts

      expect(gradebook_api).to have_received(:find_submitted).with(
        activity_id: [assignment_1.assignable_id],
        section_id: section.id,
        user_id: [student_1.id]
      )
    end

    def create_score(student, assignment)
      GradebookEngine::ScoreAction.new(
        activity_id: assignment.assignable_id,
        user_id: student.id
      )
    end

    it 'returns a hash with a count of scores by user id' do
      student_2 = build_stubbed(:student)
      scores = [
        # first student has scores for both assignments
        create_score(student_1, assignment_1),
        create_score(student_1, assignment_2),
        # student 2 has a score for only one of the assignments
        create_score(student_2, assignment_1)
      ]
      allow(gradebook_api).to receive(:find_submitted).and_return(scores)
      students = [student_1, student_2]

      student_assignment_map = described_class.new(
        section,
        students,
        [assignment_1, assignment_2]
      )

      expect(student_assignment_map.student_assignment_counts).to eq(
        student_1.id => 2,
        student_2.id => 1
      )
    end

    it 'returns a hash with a count of 0 for a user who has no scores' do
      student_assignment_map = described_class.new(
        section,
        [student_1],
        [assignment_1]
      )
      allow(gradebook_api).to receive(:find_submitted).and_return([])

      expect(
        student_assignment_map.student_assignment_counts[student_1.id]
      ).to eq(0)
    end
  end
end
