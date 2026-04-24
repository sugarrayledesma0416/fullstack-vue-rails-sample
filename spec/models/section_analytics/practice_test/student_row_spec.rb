describe SectionAnalytics::PracticeTest::StudentRow do
  describe '#concept_score_groups' do
    let(:student){ create(:student) }
    let(:section){ create(:section) }
    let(:summative_assignment) do
      create(:assignment, assignable: summative_activity, section: section, due_date: Date.tomorrow)
    end
    let(:summative_activity) { create(:activity, activity_type: 'diagnostic_v2') }
    let(:formative_assignment) do
      create(:assignment, assignable: formative_activities.first, section: section, due_date: Date.tomorrow)
    end
    let(:formative_activities) { [create(:activity, activity_type: 'diagnostic_v2')] }
    let(:student_row) do
      described_class.new(
        student: student,
        summative_activity: summative_activity,
        formative_activities: formative_activities,
        assignments: {formative: [formative_assignment], summative: summative_assignment}
      )
    end

    before do
      allow(summative_activity).to(
        receive(:content_object).and_return(
          OpenStruct.new(concepts: Array.new(4))
        )
      )
      4.times do |index|
        create(
          :study_plan_concept,
          activity: summative_activity,
          reference_id: "1.#{index}",
          cms_revision_id: summative_activity.cms_revision_id
        )
      end
    end

    it 'creates as many groups as there are study plan concepts for the summative activity' do
      expect(student_row.concept_score_groups.count).to eq(4)
    end

    it 'creates a hash of 6 key value pairs for each group' do
      expect(student_row.concept_score_groups.map(&:count)).to all(eq(6))
    end

    it 'returns the values in the correct concept order, ' \
       'even if there are records for older versions of the activity' do
      4.times do |index|
        create(
          :study_plan_concept,
          activity: summative_activity,
          reference_id: "1.#{index}",
          cms_revision_id: summative_activity.cms_revision_id - 1
        )
      end
      expect(
        student_row.concept_score_groups.pluck(:_reference_id)
      ).to eq %w[1.0 1.1 1.2 1.3]
    end
  end
end
