describe ActivityGradedNotification do
  let(:lesson) { create(:lesson_with_toc_entries) }
  let(:activity) do
    create(
      :activity,
      lesson: lesson,
      toc_location: lesson.strands.first.location
    )
  end

  let(:section)  { create(:section) }
  let(:student)  { create(:student) }

  let(:params) { { activity: activity, section: section, user: student } }

  it 'inherits from Notification::ForInternalActivity' do
    expect(described_class.new).to be_a_kind_of Notification::BaseInternalActivityNotification
  end

  context 'when creating a new activity graded notification' do
    it 'deletes previous activity graded notifications' do
      old_notification = create(
        :activity_graded_notification,
        user: student,
        section: section,
        activity: activity
      )
      create(:gb_score_action, user: student, section: section, activity: activity)
      notification = described_class.create!(params)
      expect { described_class.find(old_notification.id) }
        .to raise_error(
          ActiveRecord::RecordNotFound,
          /Couldn\'t find ActivityGradedNotification with \'id\'=\d+/
        )
    end
  end

  describe '#message' do
    it 'includes the score the instructor granted' do
      score = create(:gb_score_action, user: student, section: section, activity: activity)
      notification = described_class.create!(params)
      expected_grade = ((score.points_earned / score.points_possible) * 100).to_i
      expect(notification.message).to eq(
        "Your instructor graded this activity, giving you a score of #{expected_grade}%."
      )
    end
  end

  describe '#redirect_type' do
    it 'returns :internal_activity' do
      notification = build_stubbed(:activity_graded_notification)
      expect(notification.redirect_type).to eq(:internal_activity)
    end
  end
end
