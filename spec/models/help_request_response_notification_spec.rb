describe HelpRequestResponseNotification do
  let(:section) { create(:section) }
  let(:student) { create(:student) }
  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }
  let(:activity) do
    create(:activity, lesson: lesson, toc_location: strand.location)
  end

  let(:params) do
    { activity: activity, section: section, user: student }
  end

  it 'inherits from Notification::ForInternalActivity' do
    expect(described_class.new).to be_a_kind_of(
      Notification::BaseInternalActivityNotification
    )
  end

  context 'when creating a new help request response notification,' do
    it 'finds the count of instructor-respondable help requests for the ' \
       'specified user, section, and activity' do
      allow(student.help_requests).to receive(
        :processed_instructor_respondable_by_section_and_activity
      ).and_return(instance_double(ActiveRecord::Relation, count: 1))

      described_class.create!(params)

      expect(student.help_requests).to have_received(
        :processed_instructor_respondable_by_section_and_activity
      ).with(section.id, activity.id)
    end

    it 'deletes previous help request response notifications' do
      old_notification = create(
        :help_request_response_notification,
        activity: activity,
        section: section,
        user: student
      )

      described_class.create!(params)

      expect { described_class.find(old_notification.id) }.to raise_error(
        ActiveRecord::RecordNotFound,
        /Couldn\'t find HelpRequestResponseNotification with \'id\'=\d+/
      )
    end
  end

  describe '#message' do
    context 'when there is only one processed help request for an activity' do
      it 'says a help request has been responded to' do
        allow(student.help_requests).to receive(
          :processed_instructor_respondable_by_section_and_activity
        ).and_return(instance_double(ActiveRecord::Relation, count: 1))
        notification = create(
          :help_request_response_notification,
          activity: activity,
          section: section,
          user: student
        )
        expect(notification.message).to eq(
          'Your instructor responded to your help request.'
        )
      end
    end

    context 'when there are multiple processed help requests for an activity' do
      it 'includes the count of processed help requests' do
        allow(student.help_requests).to receive(
          :processed_instructor_respondable_by_section_and_activity
        ).and_return(instance_double(ActiveRecord::Relation, count: 2))

        notification = create(
          :help_request_response_notification,
          activity: activity,
          section: section,
          user: student
        )
        expect(notification.message).to eq(
          'Your instructor responded to 2 help requests.'
        )
      end
    end
  end

  describe '#redirect_type' do
    it 'returns :internal_activity' do
      notification = build_stubbed(:help_request_response_notification)
      expect(notification.redirect_type).to eql :internal_activity
    end
  end
end
