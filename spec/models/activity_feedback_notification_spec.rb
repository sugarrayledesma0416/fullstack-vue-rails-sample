describe ActivityFeedbackNotification do
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

  it 'inherits from Notification::BaseInternalActivityNotification' do
    expect(described_class.new).to be_a_kind_of(
      Notification::BaseInternalActivityNotification
    )
  end

  context 'when creating a new activity graded notification,' do
    it 'deletes previous activity graded notifications' do
      old_notification = create(
        :activity_feedback_notification,
        user: student,
        section: section,
        activity: activity
      )
      create(:gb_score_action, user: student, section: section, activity: activity)
      described_class.create!(params)
      expect do
        described_class.find(old_notification.id)
      end.to raise_error(
        ActiveRecord::RecordNotFound,
        /Couldn\'t find ActivityFeedbackNotification with \'id\'=\d+/
      )
    end
  end

  describe '#message' do
    context 'when AI has not been used,' do
      it 'says that the instructor added some feedback' do
        notification = described_class.create!(params)

        expect(notification.message).to eql 'Your instructor added some feedback.'
      end
    end

    context 'when AI has been used,' do
      it 'says that the instructor added some feedback' do
        notification = described_class.create!(params.merge(ai_used: true))

        expect(notification.message).to eql(
          'Your instructor added some feedback.'
        )
      end
    end
  end

  describe '#redirect_type' do
    it 'returns :internal_activity' do
      notification = build_stubbed(:activity_feedback_notification)
      expect(notification.redirect_type).to eql :internal_activity
    end
  end
end
