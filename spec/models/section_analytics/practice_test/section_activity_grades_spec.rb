describe SectionAnalytics::PracticeTest::SectionActivityGrades do
  let(:activity) { create(:activity) }
  let(:section) { create(:section) }
  let(:activity_grades){ described_class.new(section, activity) }
  let(:student) { create(:student) }
  let(:other_student) { create(:student) }
  let(:student_scores) do
     [
       OpenStruct.new(
        user_id: student.id,
        formatted_submitted_not_due_score: 80,
        submitted?: true
        )
      ]
  end

  before do
    allow(GradebookEngine::GradebookAPI)
      .to(
        receive(:find_section_assignment_grades)
      )
      .and_return(student_scores)
  end

  describe '#student_grade_submitted?' do
    context 'when given a student with a grade result' do
      it "returns the student's score" do
        expect(activity_grades.student_grade_submitted?(student)).to be true
      end
    end

    context 'when given a student without a grade result' do
      it 'returns 0' do
        expect(activity_grades.student_grade_submitted?(other_student)).to be false
      end
    end
  end

  describe '#student_grade' do
    context 'when given a student with a grade result' do
      it "returns the student's score" do
        expect(activity_grades.student_grade(student)).to eq(80)
      end
    end

    context 'when given a student without a grade result' do
      it 'returns 0' do
        expect(activity_grades.student_grade(other_student)).to eq(0)
      end
    end

    context 'when given a student without a nil score' do
      let(:student_scores) do
        [
          OpenStruct.new(
            user_id: student.id,
            formatted_submitted_not_due_score: 80,
            submitted?: true
          ),
          OpenStruct.new(
            user_id: other_student.id,
            formatted_submitted_not_due_score: nil,
            submitted?: true
          )
        ]
      end

      it 'returns 0' do
        expect(activity_grades.student_grade(other_student)).to eq(0)
      end
    end
  end

  describe '#average' do
    let(:another_student) { create(:student) }
    let(:yet_another_student) { create(:student) }

    let(:student_scores) do
      [
        OpenStruct.new(
          user_id: student.id,
          formatted_submitted_not_due_score: 80,
          submitted?: true
        ),
        OpenStruct.new(
          user_id: other_student.id,
          formatted_submitted_not_due_score: 90,
          submitted?: true
        ),
        OpenStruct.new(
          user_id: another_student.id,
          formatted_submitted_not_due_score: 60,
          submitted?: true
        ),
        OpenStruct.new(
          user_id: yet_another_student.id,
          formatted_submitted_not_due_score: 30,
          submitted?: true
        ),
      ]
    end

    it 'averages the student scores' do
      expect(activity_grades.average).to eq(65)
    end

    context 'when there are students with unsubmitted scores' do
      let(:student_scores) do
        [
          OpenStruct.new(
            user_id: student.id,
            formatted_submitted_not_due_score: 80,
            submitted?: true
          ),
          OpenStruct.new(
            user_id: other_student.id,
            submitted?: false
          )
        ]
      end

      it 'excludes them from the average' do
        average_with_other_student = student_scores.first.formatted_submitted_not_due_score / student_scores.count
        expect(activity_grades.average).to_not eq(average_with_other_student)
      end

      it 'only averages students with a score' do
        expect(activity_grades.student_grade(student)).to eq(80)
      end
    end
  end
end
