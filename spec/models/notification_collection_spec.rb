describe NotificationCollection do
  let(:program) { create(:program) }
  let(:section) { create(:section) }
  let(:user) { create(:student) }

  let(:strand) { create(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand]) }

  let(:announcement) { create(:announcement) }

  let(:activity) do
    create(
      :activity,
      lesson: lesson,
      toc_location: strand.location,
      concept: create(
        :concept,
        id: strand.location,
        lesson: lesson,
        program: program
      )
    )
  end

  describe '#serialize' do
    it 'returns only notifications for the specified user and section' do
      target_notification = create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: section,
        user: user
      )

      create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: create(:section),
        user: user
      )

      create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: section,
        user: create(:student)
      )

      collection = described_class.new(program, section, user)
      results = collection.serialize

      ids = results[:notifications][:new].map { |entry| entry[:id] }
      expect(ids).to eq([target_notification.id])
    end

    it 'sorts the notifications with the newest first' do
      older_notification = create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: nil,
        section: section,
        user: user
      )

      newer_notification = create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: nil,
        section: section,
        user: user
      )

      collection = described_class.new(program, section, user)
      results = collection.serialize

      ids = results[:announcements][:new].map { |entry| entry[:id] }
      expect(ids).to eq([newer_notification.id, older_notification.id])
    end

    it 'groups the notifications based on whether they are for an activity ' \
       'or for an announcement, and whether or not they have been viewed' do
      viewed_activity_notification = create(
        :help_request_response_notification,
        activity: activity,
        dismissed_at: Time.now.utc,
        section: section,
        user: user
      )

      new_activity_notification = create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: section,
        user: user
      )

      viewed_announcement_notification = create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: Time.now.utc,
        section: section,
        user: user
      )

      new_announcement_notification = create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: nil,
        section: section,
        user: user
      )

      collection = described_class.new(program, section, user)
      results = collection.serialize

      expect(results).to match(
        {
          announcements: {
            new: [hash_including(id: new_announcement_notification.id)],
            viewed: [hash_including(id: viewed_announcement_notification.id)]
          },
          notifications: {
            new: [hash_including(id: new_activity_notification.id)],
            viewed: [hash_including(id: viewed_activity_notification.id)]
          }
        }
      )
    end

    it 'sets the class cancelled attribute of each notification entry to ' \
       'false if the notification is not for an announcement' do
      create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: section,
        user: user
      )

      collection = described_class.new(program, section, user)
      results = collection.serialize

      # Using eq(false) instead of be_falsey to explicitly assert the intent
      # that the return value is a boolean.
      expect(results[:notifications][:new].first[:class_cancelled]).to eq(false)
    end

    context 'with a notification for an announcement,' do
      before do
        create(
          :announcement_posted_notification,
          announcement: announcement,
          dismissed_at: nil,
          section: section,
          user: user
        )
      end

      it 'sets the class cancelled attribute of the notification entry to ' \
         'false if the announcement class_cancelled attribute is false' do
        collection = described_class.new(program, section, user)
        results = collection.serialize

        # Using eq(false) instead of be_falsey to explicitly assert the intent
        # that the return value is a boolean.
        expect(results[:announcements][:new].first[:class_cancelled]).to eq(false)
      end

      it 'sets the class cancelled attribute of the notification entry to ' \
         'true if the announcement class_cancelled attribute is true' do
        # rubocop:disable Rails/SkipsModelValidations
        # Need to use update_column to change this value to avoid executing
        # callbacks that will destroy existing notifications.
        announcement.update_column(:class_cancelled, true)
        # rubocop:enable Rails/SkipsModelValidations

        collection = described_class.new(program, section, user)
        results = collection.serialize

        expect(results[:announcements][:new].first[:class_cancelled]).to eq(true)
      end
    end

    it 'formats the created_at date of each notification entry' do
      created_at_time = DateTime.new(2014, 5, 27, 4, 5).utc
      notification = create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: nil,
        section: section,
        user: user
      )

      # rubocop:disable Rails/SkipsModelValidations
      # Need to use update_column to set this value, instead of using
      # Timecop.freeze, because Timecop.freeze only affects the Time
      # object in ruby, but created_at is set by the database.
      notification.update_column(:created_at, created_at_time)
      # rubocop:enable Rails/SkipsModelValidations

      collection = described_class.new(program, section, user)
      results = collection.serialize

      expect(results[:announcements][:new].first[:created_at]).to eq(
        'May 27 12:05 AM'
      )
    end

    it 'sets the language of the notification entry to the language code ' \
       'of the speified program' do
      create(
        :announcement_posted_notification,
        announcement: announcement,
        dismissed_at: nil,
        section: section,
        user: user
      )
      collection = described_class.new(program, section, user)
      results = collection.serialize

      expect(results[:announcements][:new].first[:language]).to eq(
        program.language_code
      )
    end

    it 'returns the id, student_label, message, and path of each notification' do
      activity.update!(student_title: 'my title')

      notification = create(
        :activity_feedback_notification,
        activity: activity,
        dismissed_at: nil,
        section: section,
        user: user
      )

      collection = described_class.new(program, section, user)
      results = collection.serialize

      expect(results[:notifications][:new].first).to match(
        hash_including(
          id: notification.id,
          label: notification.label,
          message: notification.message,
          path: notification.path
        )
      )
    end

    context 'when the activity is an assessment,' do
      let(:concept) do
        create(:concept, program: activity.program, lesson:, name: 'ploki', assessment: true)
      end

      it 'uses the activity student display title for the label with html tags stripped out' do
        activity.update!(concept:, student_title: '<b>c &amp; d</b>')

        create(
          :activity_feedback_notification,
          activity:,
          dismissed_at: nil,
          section:,
          user:
        )

        collection = described_class.new(program, section, user)
        results = collection.serialize

        expect(results[:notifications][:new].first[:label]).to eq('c & d')
      end
    end

    context 'when the activity is not an assessment,' do
      let(:strand) { create(:toc_entry, title: '<b>this &amp; strand</b>') }

      it 'uses the lesson label and strand name for the label with htlm tags stripped out' do
        activity.update!(student_title: '<b>c &amp; d</b>')
        lesson.update!(label: '<b>this &amp; lesson</b>')

        create(
          :activity_feedback_notification,
          activity:,
          dismissed_at: nil,
          section:,
          user:
        )

        collection = described_class.new(program, section, user)
        results = collection.serialize

        expect(results[:notifications][:new].first[:label]).to eq(
          "this & lesson | this & strand | #{activity.title}"
        )
      end
    end
  end
end
