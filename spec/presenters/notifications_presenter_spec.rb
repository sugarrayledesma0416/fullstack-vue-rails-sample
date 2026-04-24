describe NotificationsPresenter do
  describe '#notifications_and_announcements' do
    let(:program) { build_stubbed(:program) }
    let(:section) { build_stubbed(:section, course: course) }
    let(:course) { build_stubbed(:course) }
    let(:student) { build_stubbed(:student) }
    let(:activity) { build_stubbed(:activity) }

    let(:presenter) { described_class.new(student, section, program) }

    def populator(factory_name, program, announcement = nil)
      limit = program.vista_online_learning? ? 11 : 6
      (1..limit).map do
        if announcement.present?
          build_stubbed(factory_name, announcement: announcement)
        else
          build_stubbed(factory_name)
        end
      end
    end

    context 'with notifications,' do
      let(:notification) do
        build_stubbed(
          :activity_graded_notification,
          user: student,
          section: section,
          activity: activity
        )
      end

      before do
        allow(Notification).to receive(:find_unique_activity_notifications)
          .and_return([notification])
      end

      it 'calls the correct notification lookup method' do
        presenter.notifications_and_announcements

        expect(Notification).to have_received(:find_unique_activity_notifications)
          .with(student, section)
      end

      it 'returns the notification info for the given user and section' do
        results = presenter.notifications_and_announcements
        expect(results[:activity_notifications]).to eq([notification])
      end

      context 'when current program is VOL,' do
        it 'limits the notification results to 10' do
          allow(program).to receive(:vista_online_learning?).and_return(true)
          allow(Notification).to receive(:find_unique_activity_notifications)
            .and_return(populator(:activity_graded_notification, program))

          results = presenter.notifications_and_announcements

          expect(results[:activity_notifications].size).to eq(10)
        end
      end

      context 'when current program is SS,' do
        it 'limits the notification results to 5' do
          allow(Notification).to receive(:find_unique_activity_notifications)
            .and_return(populator(:activity_graded_notification, program))

          results = presenter.notifications_and_announcements

          expect(results[:activity_notifications].size).to eq(5)
        end
      end
    end

    context 'when the student has announcements,' do
      let(:announcement) { build_stubbed(:announcement) }

      let(:announcement_notification) do
        build_stubbed(
          :announcement_posted_notification,
          user: student,
          section: section,
          announcement: announcement
        )
      end

      before do
        allow(announcement_notification).to receive(:message)
          .and_return(announcement.title)
        allow(Notification).to receive(:find_unread_announcement_notifications)
          .and_return([announcement_notification])
      end

      it 'calls the correct notification finder' do
        presenter.notifications_and_announcements

        expect(Notification).to have_received(:find_unread_announcement_notifications)
          .with(student, section)
      end

      it 'returns the announcement for the given user and section' do
        results = presenter.notifications_and_announcements

        expect(results[:announcement_notifications]).to eq(
          [announcement_notification]
        )
      end
    end

    context 'when current program is VOL' do
      let(:announcement) { build_stubbed(:announcement, class_cancelled: 1) }

      it 'limits the announcement results to 10' do
        allow(program).to receive(:vista_online_learning?).and_return(true)
        allow(Notification).to receive(:find_unread_announcement_notifications)
          .and_return(populator(:announcement_posted_notification, program, announcement))

        results = presenter.notifications_and_announcements

        expect(results[:announcement_notifications].size).to eq(10)
      end
    end

    context 'when current program is SS' do
      let(:announcement) { build_stubbed(:announcement, class_cancelled: 1) }

      it 'limits the announcement results to 5' do
        allow(Notification).to receive(:find_unread_announcement_notifications)
          .with(student, section)
          .and_return(populator(:announcement_posted_notification, program, announcement))

        results = presenter.notifications_and_announcements

        expect(results[:announcement_notifications].size).to eq(5)
      end
    end
  end
end
