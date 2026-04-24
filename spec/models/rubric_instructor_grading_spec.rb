describe RubricInstructorGrading do
  include RspecJsContentHelpers

  let(:instructor) { create(:instructor) }
  let(:program) { create(:program_with_lessons) }
  let(:rubric_activity) { create_composition_activity_with_rubric(program) }

  let(:rubric_instructor_grading) do
    described_class.new(rubric_activity.id, section.id, student.id)
  end

  let(:section) { create(:section, instructor: instructor) }

  let(:student) { create(:student) }

  before do
    create(:gb_activity, id: rubric_activity.id)
    create(:gb_section, id: section.id)
    create(:gb_user, id: student.id)
  end

  describe '#grade_pending?' do
    context 'if there is no score action' do
      it 'returns true' do
        expect(rubric_instructor_grading).to be_grade_pending
      end
    end

    context 'when the activity is not graded yet' do
      before do
        create(
          :gb_score_action,
          activity_id: rubric_activity.id,
          school_id: 123,
          section_id: section.id,
          summation: {
            pending: true,
            points_earned: 0.0,
            points_possible: 10,
            submitted_at: Time.zone.now,
            rubric_graded: false
          },
          user: student
        )
      end

      it 'returns true' do
        expect(rubric_instructor_grading).to be_grade_pending
      end
    end

    context 'when the activity is already graded' do
      before do
        create(
          :gb_score_action,
          activity_id: rubric_activity.id,
          school_id: 123,
          section_id: section.id,
          summation: {
            pending: false,
            points_earned: 10,
            points_possible: 10,
            submitted_at: Time.zone.now,
            rubric_graded: false
          },
          user: student
        )
      end

      it 'returns false' do
        expect(rubric_instructor_grading).not_to be_grade_pending
      end
    end
  end

  describe '#rubric_graded?' do
    context 'when the activity is not graded yet' do
      before do
        create(
          :gb_score_action,
          activity_id: rubric_activity.id,
          school_id: 123,
          section_id: section.id,
          summation: {
            pending: true,
            points_earned: 0.0,
            points_possible: 10,
            submitted_at: Time.zone.now,
            rubric_graded: false
          },
          user: student
        )
      end

      it 'returns false' do
        expect(rubric_instructor_grading).not_to be_rubric_graded
      end
    end

    context 'when activity is manually graded' do
      before do
        create(
          :gb_score_action,
          activity_id: rubric_activity.id,
          school_id: 123,
          section_id: section.id,
          summation: {
            pending: false,
            points_earned: 10,
            points_possible: 10,
            submitted_at: Time.zone.now,
            rubric_graded: false
          },
          user: student
        )
      end

      it 'returns false' do
        expect(rubric_instructor_grading).not_to be_rubric_graded
      end
    end

    context 'when the activity is graded with a rubric' do
      before do
        create(
          :gb_score_action,
          activity_id: rubric_activity.id,
          school_id: 123,
          section_id: section.id,
          summation: {
            pending: false,
            points_earned: 10,
            points_possible: 10,
            submitted_at: Time.zone.now,
            rubric_graded: true
          },
          user: student
        )
      end

      it 'returns true' do
        expect(rubric_instructor_grading).to be_rubric_graded
      end
    end
  end
end
