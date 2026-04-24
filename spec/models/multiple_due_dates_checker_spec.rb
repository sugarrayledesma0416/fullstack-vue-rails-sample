describe MultipleDueDatesChecker do
  include described_class

  describe '#assigned_on_multiple_dates?' do
    it "returns false if the activity doesn't have any assignments" do
      activity = create(:activity)
      expect(assigned_on_multiple_dates?(activity.assignments)).to be(false)
    end

    it 'returns false if activity has only one assignment ' \
       'and is not individually assigned' do
      activity = create(:activity)
      create(:assignment, assignable: activity)
      expect(assigned_on_multiple_dates?(activity.assignments)).to be(false)
    end

    it 'returns true if activity has only one assignment ' \
       'that is individually assigned to multiple dates' do
      activity = create(:activity)
      assignment = create(:assignment, assignable: activity, individually_assignable: true)
      # When activity is individually assigned in multiple due dates an attribute is added
      # here app/presenters/concerns/instructor_toc_presentation.rb#L18 but in this case
      # a stub would demostrate what this method does
      allow(assignment).to receive(:multiple_due_dates?).and_return(true)
      allow(activity).to receive(:assignments).and_return([assignment])
      expect(assigned_on_multiple_dates?(activity.assignments)).to be(true)
    end

    it 'returns true if there is more than 1 assignment with different due date' do
      activity = create(:activity)
      due_date_1 = Time.zone.now
      due_date_2 = due_date_1 + 2.days
      create(:assignment, assignable: activity, individually_assignable: true, due_date: due_date_1)
      create(:assignment, assignable: activity, individually_assignable: true, due_date: due_date_2)
      expect(assigned_on_multiple_dates?(activity.assignments)).to be(true)
    end
  end
end
