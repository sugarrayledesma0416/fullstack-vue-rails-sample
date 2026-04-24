describe Notification do

  let(:section) { create(:section) }
  let(:student) { create(:student) }
  let(:lesson) { create(:lesson) }
  let(:activity) { build_stubbed(:activity, :lesson => lesson) }
  let(:announcement) { build_stubbed(:announcement) }
  let(:strand) { build_stubbed(:toc_entry) }

  before do
    allow(lesson).to receive(:strand_for_toc_location).and_return(strand)
  end

  describe 'scopes' do

    describe '.for_activities' do
      it 'returns only notifications with an activity id' do
        activity_notification = create(:activity_graded_notification, :section => section, :user => student,
                                                                       :activity => activity)
        announcement_notification = create(:announcement_posted_notification, :section => section, :user => student,
                                                                               :announcement => announcement)
        results = Notification.for_activities
        expect(results).to include activity_notification
        expect(results).not_to include announcement_notification
      end
    end

    describe '.for_announcements' do
      it 'returns only notifications with an announcement id' do
        announcement_notification = create(:announcement_posted_notification, :section => section, :user => student,
                                                                               :announcement => announcement)
        activity_notification = create(:activity_graded_notification, :section => section, :user => student,
                                                                       :activity => activity)

        results = Notification.for_announcements
        expect(results).to include announcement_notification
        expect(results).not_to include activity_notification
      end
    end

    describe '.by_section' do
      it 'returns only notifications for the specified section' do
        section_notification = create(:notification, :user => student, :section => section)
        other_section_notification = create(:notification, :user => student, :section => build_stubbed(:section))

        results = Notification.by_section(section)

        expect(results).to include section_notification
        expect(results).not_to include other_section_notification
      end
    end

    describe '.undismissed' do
      it 'returns only notifications with no dismissed_at date' do
        undismissed_notification = create(:notification, :dismissed_at => nil, :section => section, :user => student)
        dismissed_notification = create(:notification, :dismissed_at => Time.now, :section => section, :user => student)

        results = Notification.undismissed

        expect(results).to include undismissed_notification
        expect(results).not_to include dismissed_notification
      end
    end

    describe '.dismissed' do
      it 'returns only notifications with a dismissed_at date' do
        undismissed_notification = create(:notification, :dismissed_at => nil, :section => section, :user => student)
        dismissed_notification = create(:notification, :dismissed_at => Time.now, :section => section, :user => student)

        results = Notification.dismissed

        expect(results).to include dismissed_notification
        expect(results).not_to include undismissed_notification
      end
    end

    describe '.by_user_and_section' do
      it 'returns only notifications for the specified user and section' do
        section_notification = create(:notification, :user => student, :section => section)
        other_section_notification = create(:notification, :user => student, :section => build_stubbed(:section))
        other_user_notification = create(:notification, :user => build_stubbed(:student), :section => section)

        results = Notification.by_user_and_section(student, section)

        expect(results).to include section_notification
        expect(results).not_to include other_section_notification
        expect(results).not_to include other_user_notification
      end

      describe '#dismiss_all!' do
        it 'marks all matching notifications as dismissed' do
          section_notification = create(:notification, :user => student, :section => section)
          other_section_notification = create(:notification, :user => student, :section => build_stubbed(:section))
          other_user_notification = create(:notification, :user => build_stubbed(:student), :section => section)

          Notification.by_user_and_section(student, section).dismiss_all!

          expect(section_notification.reload).to be_dismissed
          expect(other_section_notification.reload).not_to be_dismissed
          expect(other_user_notification.reload).not_to be_dismissed
        end
      end
    end
  end

  describe ".communications" do
    it 'returns only notifications for the specified user, section, dismissal state, and notification type' do
      undismissed_activity_notification = create(:help_request_response_notification, :user => student, :section => section,
                                                                                     :activity => activity,
                                                                                     :dismissed_at => nil)
      dismissed_activity_notification   = create(:help_request_response_notification, :user => student, :section => section,
                                                                                     :activity => activity,
                                                                                     :dismissed_at => Time.now)
      # activity notifications for different section and different student
      create(:help_request_response_notification, :user => student, :section => build_stubbed(:section), :activity => activity,
                                                 :dismissed_at => nil)
      create(:help_request_response_notification, :user => build_stubbed(:student), :section => section, :activity => activity,
                                                 :dismissed_at => nil)

      undismissed_announcement_notification = create(:announcement_posted_notification, :user => student, :section => section,
                                                                                         :announcement => announcement,
                                                                                         :dismissed_at => nil)
      dismissed_announcement_notification = create(:announcement_posted_notification, :user => student, :section => section,
                                                                                       :announcement => build_stubbed(:announcement),
                                                                                       :dismissed_at => Time.now)
      # announcement notifications for different section and different student
      create(:announcement_posted_notification, :user => student, :section => build_stubbed(:section), :dismissed_at => nil,
                                                 :announcement => build_stubbed(:announcement) )
      create(:announcement_posted_notification, :user => build_stubbed(:student), :section => section, :dismissed_at => Time.now,
                                                 :announcement => build_stubbed(:announcement) )

      expect(Notification.communications(student, section, 'activities', 'undismissed')).to eq([undismissed_activity_notification])
      expect(Notification.communications(student, section, 'activities', 'dismissed')).to eq([dismissed_activity_notification])
      expect(Notification.communications(student, section, 'announcements', 'undismissed')).to eq([undismissed_announcement_notification])
      expect(Notification.communications(student, section, 'announcements', 'dismissed')).to eq([dismissed_announcement_notification])
    end
  end

  describe ".find_unique_activity_notifications" do
    it 'returns undismissed notifications for activities for the specified user and section' do
      undismissed_notification       = create(:help_request_response_notification, :user => student, :section => section,
                                                                                  :activity => activity,
                                                                                  :dismissed_at => nil)
      dismissed_notification         = create(:help_request_response_notification, :user => student, :section => section,
                                                                                  :activity => activity,
                                                                                  :dismissed_at => Time.now)
      other_section_notification     = create(:help_request_response_notification, :user => student,
                                                                                  :section => build_stubbed(:section),
                                                                                  :activity => activity,
                                                                                  :dismissed_at => nil)
      other_student_notification     = create(:help_request_response_notification, :user => build_stubbed(:student),
                                                                                  :section => section, :activity => activity,
                                                                                  :dismissed_at => nil)

      results = Notification.find_unique_activity_notifications(student, section)

      expect(results).to include undismissed_notification
      expect(results).not_to include dismissed_notification
      expect(results).not_to include other_section_notification
      expect(results).not_to include other_student_notification
    end

    it 'returns only 1 notification per activity' do
      create(:help_request_response_notification, :user => student, :section => section, :activity => activity)
      create(:activity_graded_notification, :user => student, :section => section, :activity => activity)
      expect(Notification.find_unique_activity_notifications(student, section).length).to eq(1)
    end
  end

  describe ".find_unread_announcement_notifications" do
    it 'returns only undismissed notifications for announcements for the specified user and section' do
      undismissed_notification   = create(:announcement_posted_notification, :user => student, :section => section,
                                                                              :announcement => announcement,
                                                                              :dismissed_at => nil)
      dismissed_notification     = create(:announcement_posted_notification, :user => student, :section => section,
                                                                              :announcement => build_stubbed(:announcement),
                                                                              :dismissed_at => Time.now)
      other_section_notification = create(:announcement_posted_notification, :user => student, :section => build_stubbed(:section),
                                                                              :announcement => build_stubbed(:announcement),
                                                                              :dismissed_at => nil)
      other_student_notification = create(:announcement_posted_notification, :user => build_stubbed(:student), :section => section,
                                                                              :announcement => build_stubbed(:announcement),
                                                                              :dismissed_at => nil)

      results = Notification.find_unread_announcement_notifications(student, section)

      expect(results).to include undismissed_notification
      expect(results).not_to include dismissed_notification
      expect(results).not_to include other_section_notification
      expect(results).not_to include other_student_notification
    end
  end

  describe "#label" do
    it "requires implementation in child class" do
      notification = create(:notification)
      expect{ notification.label }.to raise_error NotImplementedError
    end
  end

  describe "#dismiss" do
    it "sets the dismissed_at attribute to today's date" do
      notification = create(:notification, :dismissed_at => nil)
      notification.dismiss
      expect(notification.dismissed_at.to_date).to eq(Date.today)
    end
  end

  describe "#dismissed?" do
    it "should should return true if dismissed_at attribute has a value" do
      notification = create(:notification, :dismissed_at => Date.today)
      expect(notification).to be_dismissed
    end

    it "should should return false if dismissed_at attribute doesn't have a value" do
      notification = create(:notification, :dismissed_at => nil)
      expect(notification).not_to be_dismissed
    end
  end
end

describe Notification::BaseInternalActivityNotification do
  let(:strand) { create(:toc_entry) }
  let(:lesson) do
    create(:lesson, label: 'Lesson 1', toc_entries: [strand])
  end
  let(:section) { build_stubbed(:section) }
  let(:activity) do
    create(:activity, lesson: lesson, toc_location: strand.location)
  end
  let(:student) { build_stubbed(:student) }
  let(:notification) do
    described_class.create!(
      activity: activity,
      section: section,
      user: student
    )
  end

  describe '#label' do
    context 'when the activity is an assessment,' do
      let(:concept) do
        create(:concept, program: activity.program, lesson:, name: 'ploki', assessment: true)
      end

      it 'returns the activity student display title' do
        activity.update!(concept:)

        expect(notification.label).to eq activity.student_display_title
      end
    end

    context 'when the activity is not an assessment,' do
      it 'returns the lesson label, strand name and activity title' do
        expect(notification.label).to eq(
          "#{lesson.label} | #{strand.name} | #{activity.title}"
        )
      end

      it 'returns the lesson label and the strand name' do
        expect(notification.label(true)).to eq(
          "#{lesson.label} | #{strand.name}"
        )
      end
    end
  end
end

describe StudyPlanCreatedNotification do
  let(:strand) { create(:toc_entry) }
  let(:lesson) do
    create(:lesson, label: 'Lesson 1', toc_entries: [strand])
  end
  let(:section) { build_stubbed(:section) }
  let(:student) { build_stubbed(:student) }

  describe '#redirect_type' do
    it 'redirects to study plan v2 for diagnostic_v2 activities' do
      activity = create(
        :activity,
        lesson: lesson,
        toc_location: strand.location,
        activity_type: 'diagnostic_v2'
      )
      notification = described_class.create(
        activity: activity,
        section: section,
        user: student
      )
      expect(notification.redirect_type).to eq :study_plan_v2
    end

    it 'redirects to study plan for non diagnostic_v2 activities' do
      activity = create(
        :activity,
        lesson: lesson,
        toc_location: strand.location,
        activity_type: 'foo'
      )
      notification = described_class.create(
        activity: activity,
        section: section,
        user: student
      )
      expect(notification.redirect_type).to eq :study_plan
    end
  end
end
