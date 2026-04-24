describe ActivityLatePenaltyForScoreNotification do
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

  let(:old_penalty) { 5 }
  let(:new_penalty) { 10 }

  let(:params) do
    { activity: activity, user: student, section: section,
      old_penalty_percent: old_penalty, new_penalty_percent: new_penalty }
  end

  it 'inherits from Notification::ForInternalActivity' do
    expect(described_class.new).to be_a_kind_of Notification::BaseInternalActivityNotification
  end

  describe '#message' do
    it 'includes the old penalty and new penalty percentages' do
      notification = described_class.create!(params)
      expect(notification.message).to eql 'Your instructor changed ' \
        "the late penalty percentage from #{old_penalty}% to #{new_penalty}%."
    end
  end

  describe '#redirect_type' do
    it 'returns :internal_activity' do
      notification = build_stubbed(:activity_late_penalty_for_score_notification)
      expect(notification.redirect_type).to eq(:internal_activity)
    end
  end

  describe 'updating the notification' do
    it 'does not removed the values that have been previously saved in the data field' do
      notification = described_class.new(params)
      notification.old_penalty_percent = 45
      notification.new_penalty_percent = 60
      notification.save
      notification = Notification.find(notification.id)
      notification.save

      expect(notification).to have_attributes(
        old_penalty_percent: 45,
        new_penalty_percent: 60
      )
    end
  end
end
