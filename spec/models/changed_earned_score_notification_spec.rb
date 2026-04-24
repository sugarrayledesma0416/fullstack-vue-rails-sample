describe ChangedEarnedScoreNotification do
  let(:lesson) { create(:lesson_with_toc_entries) }
  let(:activity) do
    create(
      :activity,
      lesson: lesson,
      toc_location: lesson.strands.first.location
      )
  end
  let(:section)  { build_stubbed(:section) }
  let(:student)  { build_stubbed(:student) }

  let(:old_points_earned) { 10.0 }
  let(:new_points_earned) { 40.0 }
  let(:points_possible)   { 70 }

  let(:params) { { :activity => activity, :section => section, :user => student,
                   :old_points_earned => old_points_earned, :new_points_earned => new_points_earned,
                   :points_possible => points_possible } }

  it 'inherits from Notification::ForInternalActivity' do
    expect(ChangedEarnedScoreNotification.new).to be_a_kind_of Notification::BaseInternalActivityNotification
  end

  describe '#message' do
    it 'includes the old score and the new score' do
      notification = ChangedEarnedScoreNotification.create!(params)
      expected_old_percent = ((old_points_earned/points_possible) * 100).to_i
      expected_new_percent = ((new_points_earned/points_possible) * 100).to_i
      expect(notification.message).to eql "Your instructor changed your score from #{expected_old_percent}% to #{expected_new_percent}%."
    end
  end

  describe "#redirect_type" do
    it "returns :internal_activity" do
      notification = build_stubbed(:changed_earned_score_notification)
      expect(notification.redirect_type).to eql :internal_activity
    end
  end

  describe "updating the notification" do
    it "does not removed the values of the old and earned scores" do
      notification = ChangedEarnedScoreNotification.new(params)
      notification.old_points_earned = 10.0
      notification.new_points_earned = 12.0
      notification.points_possible = 12.0
      notification.save
      notification = Notification.find(notification.id)
      notification.save

      expect(notification).to have_attributes(
        old_score: 83,
        new_score: 100
      )
    end
  end
end
