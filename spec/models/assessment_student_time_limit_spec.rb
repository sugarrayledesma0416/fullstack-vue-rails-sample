describe AssessmentStudentTimeLimit do
  let(:section) { build_stubbed(:section) }
  let(:activity) { build_stubbed(:activity) }
  let(:student_1) { build_stubbed(:student) }
  let(:student_2) { build_stubbed(:student) }

  describe '.student_time_limit' do
    let!(:time_limit_1) do
      create(
        :assessment_student_time_limit,
        user_id: student_1.id,
        section_id: section.id,
        activity_id: activity.id,
        time_limit: 75
      )
    end
    let!(:time_limit_2) do
      create(
        :assessment_student_time_limit,
        user_id: student_2.id,
        section_id: section.id,
        activity_id: activity.id,
        time_limit: 90
      )
    end

    it 'returns the time limit record for the section, activity and student' do
      tl = described_class.student_time_limit(section, activity, student_1)
      expect(tl.time_limit).to eq 75
      tl = described_class.student_time_limit(section, activity, student_2)
      expect(tl.time_limit).to eq 90
    end
  end

  describe '.delete_time_limits' do
    # 2 records for the same section and activity
    let!(:time_limit_1) do
      create(
        :assessment_student_time_limit,
        user_id: student_1.id,
        section_id: section.id,
        activity_id: activity.id
      )
    end
    let!(:time_limit_2) do
      create(
        :assessment_student_time_limit,
        user_id: student_2.id,
        section_id: section.id,
        activity_id: activity.id
      )
    end
    # plus a third for the same activity in a different section
    let!(:time_limit_3) do
      create(
        :assessment_student_time_limit,
        section_id: section.id + 1,
        activity_id: activity.id
      )
    end

    it 'removes all student time limits related to the section and activity' do
      expect { described_class.delete_time_limits(section.id, activity.id) }
        .to change(described_class, :count).by(-2)
    end
  end
end
