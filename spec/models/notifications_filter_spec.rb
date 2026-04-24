describe NotificationsFilter do
  let!(:activity_notification) { build_stubbed(:notification, :activity_id => 123) }
  let!(:assignment) { double('Assignment', :assignable_id => activity_notification.activity_id,
                                           :grade_availability => nil,
                                           :assignable_type => 'Activity') }
  let!(:assessment_notification_1) { build_stubbed(:notification, :activity_id => 456) }
  let!(:assessment_assignment1) { double('Assignment', :assignable_id => assessment_notification_1.activity_id,
                                                       :assessment_grade_available? => true,
                                                       :assignable_type => 'Activity') }
  let!(:assessment_notification_2) { build_stubbed(:notification, :activity_id => 789) }
  let!(:assessment_assignment2) { double('Assignment', :assignable_id => assessment_notification_2.activity_id,
                                                       :assessment_grade_available? => false,
                                                       :assignable_type => 'Activity') }
  let(:current_section) { build_stubbed(:section) }
  let(:notification_list) { [activity_notification, assessment_notification_1, assessment_notification_2] }
  let(:filter) { NotificationsFilter.new(current_section, notification_list) }

  before do
    allow(Assignment).to receive(:assessments_for_section).and_return([assessment_assignment1, assessment_assignment2])
  end

  it "returns an array of notifications" do
    results = filter.notifications
    expect(results).to be_a Array
    expect(results.first).to be_a Notification
  end

  it "does not include notifications for activities where grading that has not been released" do
    results = filter.notifications
    expect(results).to include activity_notification
    expect(results).to include assessment_notification_1
    expect(results).not_to include assessment_notification_2
  end

  it "does not filter reset work notifications" do
    reset_work_notification = build_stubbed(:notification, :type => 'ActivityResetWorkNotification')
    filter = NotificationsFilter.new(current_section, [activity_notification, assessment_notification_1, assessment_notification_2, reset_work_notification])
    results = filter.notifications
    expect(results).to include reset_work_notification
  end
end
