describe SectionAnalytics::PracticeTest::SectionStudentsAggregator do
  let(:summative_activity) { create(:activity, activity_type: 'diagnostic_v2') }
  let(:summative_assignment) do
    create(:assignment, assignable: summative_activity, section: section, due_date: Date.tomorrow)
  end
  let(:formative_activity) { create(:activity, activity_type: 'diagnostic_v2') }
  let(:formative_assignment) do
    create(:assignment, assignable: formative_activity, section: section, due_date: Date.tomorrow)
  end
  let(:summative_concept) do
    create(
      :study_plan_concept,
      activity: summative_activity,
      cms_revision_id: summative_activity.cms_revision_id
    )
  end
  let(:formative_concept) { create(:study_plan_concept, activity: formative_activity) }
  let(:activities) { [summative_activity, formative_activity] }
  let(:assignments) { { summative: summative_assignment, formative: formative_assignment } }
  let(:students) do
    section.current_students_base.map do |student|
      SectionAnalytics::PracticeTest::StudentSubmittedActivityScores.new(
        student,
        summative_activity,
        [formative_activity],
        assignments
      )
    end
  end
  let(:instructor) { create(:instructor, username: 'diag_v2_instructor') }
  let(:course) { create(:course, owner: instructor) }
  let(:section) { create(:section_with_enrollments, course: course) }
  let(:student_concept_scores) do
    described_class.new(
      section: section,
      activities: activities,
      assignments: assignments
    )
  end

  before do
    allow(summative_activity).to receive(:formative_activities).and_return([formative_activity])
    students.each do |student_scores|
      activities.each do |activity|
        create(
          :attempt,
          user_id: student_scores.student_id,
          activity: activity,
          section: section,
          status_code: AttemptStatus::CODE_COMPLETED
        )
      end
    end
  end

  describe '#student_rows' do
    it 'returns student row instances' do
      expect(student_concept_scores.student_rows).to all(
        be_a SectionAnalytics::PracticeTest::StudentRow
      )
    end

    it 'includes all current students in the section' do
      expect(student_concept_scores
               .student_rows
               .map(&:student)
               .sort_by(&:id)
              ).to eq(section.current_students_base.sort_by(&:id))
    end
  end

  describe '#summative_activity_grades' do
    context 'when a summative activity is given' do
      it 'returns an ActivityGrades instance' do
        expect(student_concept_scores.summative_activity_grades).to(
          be_a(SectionAnalytics::PracticeTest::SectionActivityGrades)
        )
      end
    end

    context 'when no summative activity is given' do
      before do
        allow(summative_activity).to receive(:formative_activities).and_return([])
        allow(formative_activity).to receive(:formative_activities).and_return([])
      end

      it 'returns nil' do
        expect(student_concept_scores.summative_activity_grades).to be_nil
      end
    end
  end

  describe '#summative_concepts' do
    context 'when a summative activity is given' do
      it "returns the activity's study plan concepts for the correct revision" do
        (1..4).each do |index|
          create(
            :study_plan_concept,
            activity: summative_activity,
            cms_revision_id: summative_activity.cms_revision_id + index
          )
        end
        expect(student_concept_scores.summative_concepts).to eq([summative_concept])
      end
    end

    context 'when a summative activity is not given' do
      before do
        allow(summative_activity).to receive(:formative_activities).and_return([])
        allow(formative_activity).to receive(:formative_activities).and_return([])
      end

      it 'returns an empty collection' do
        expect(student_concept_scores.summative_concepts).to eq([])
      end
    end
  end

  describe '#sort_by' do
    let(:scores) do
      {
        student_concept_scores.student_rows[0].student_scores.student_id => 87,
        student_concept_scores.student_rows[1].student_scores.student_id => 100,
        student_concept_scores.student_rows[2].student_scores.student_id => 75,
        student_concept_scores.student_rows[3].student_scores.student_id => 40,
        student_concept_scores.student_rows[4].student_scores.student_id => 90
      }
    end
    let!(:sorted_student_rows) do
      [
        student_concept_scores.student_rows[3],
        student_concept_scores.student_rows[2],
        student_concept_scores.student_rows[0],
        student_concept_scores.student_rows[4],
        student_concept_scores.student_rows[1]
      ]
    end

    it 'sorts the StudentRows by their student scores record according to the block given' do
      student_concept_scores.sort_by do |student|
        scores[student.student_id]
      end

      expect(
        student_concept_scores.student_rows.map { |sr| sr.student_id }
      ).to eq(sorted_student_rows.map { |sr| sr.student_scores.student_id })
    end
  end

  describe '#reverse' do
    let!(:reversed_student_rows) do
      student_concept_scores.student_rows.reverse
    end

    it 'reverses the order of the student rows' do
      expect(student_concept_scores.reverse).to eq(reversed_student_rows)
    end
  end
end
