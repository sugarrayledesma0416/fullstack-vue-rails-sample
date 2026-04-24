require 'new_student_dashboard_controller'

feature 'Notifications', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include ActionView::Helpers::DateHelper

  def create_activity(student_title, grade_method = nil)
    create(
      :activity,
      lesson: lesson,
      toc_location: strand.location,
      component_name: 'Practice',
      grading_method: grade_method,
      concept: lesson.concepts[0],
      student_title: student_title
    )
  end

  def student_dashboard_url
    course_section_path(course, section)
  end

  def expect_notification_element(type, text)
    expect(page).to have_selector(
      ".test-notification-#{type}",
      text: text,
      visible: true
    )
  end

  def expect_announcement_element(type, text)
    expect(page).to have_selector(
      ".test-announcement-#{type}",
      text: text,
      visible: true
    )
  end

  def validate_class_bulletin_announcement(notification, date:)
    within(".test-notification-id-#{notification.id}") do
      expect_notification_element(:label, notification.label.shorten(36))
      # We can't reliably check the date because the displayed date has
      # been humanized (for example 'less than one minute ago').
      # What we could do is to freeze the time, but we decided that we only
      # want to check if the date element is present, we don`t want to check
      # its content.
      expect(page).to have_selector('.test-notification-date', visible: true)
    end
  end

  def validate_announcement_details(announcement, title = nil)
    within(".test-announcement-#{announcement.id}") do
      expect_announcement_element(:title, title || announcement.title)
      expect_announcement_element(:body, announcement.body)
      expect_announcement_element(
        :'date-posted', announcement.created_at.strftime('%b %d %I:%M %p')
      )
      expect_announcement_element(
        :'date-update', announcement.updated_at.strftime('%b %d %I:%M %p')
      )
    end
  end

  def validate_notification_summary(notification, message: nil)
    within(".test-notification-#{notification.id}") do
      expect_notification_element(:label, notification.label)
      expect_notification_element(:message, message) if message.present?
      expect_notification_element(:date, notification.created_at.strftime('%b %d %I:%M %p'))
    end
  end

  def validate_notification_listing(notification, message)
    within(".test-notification_listing .test-notification-#{notification.id}") do
      expect_notification_element(:message, message)
    end
  end

  let(:school) { create(:school) }
  let(:program) { create(:program) }
  let(:student) { create(:student) }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:unit) { create(:unit, program: program, name: 'UNIT-01', rank: 0) }
  let(:lesson) do
    create(:lesson_with_toc_entries, unit: unit, label: 'Leccion 1').tap do |memo|
      memo.concepts << create(:concept, program: program, lesson: memo)
    end
  end
  let(:strand) { create_strand_in_lesson(lesson, assessment: true, title: 'strand 1') }
  let(:course) do
    create(
      :course,
      program: program,
      school: school,
      owner: instructor,
      first_unit_id: unit.id,
      last_unit_id: unit.id
    ).tap do |memo|
      memo.categories << create(:category, course: memo)
    end
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity_1) { create_activity('Activity_1 student title', grading_method: 'instructor') }
  let(:activity_2) { create_activity('Activity_2 student title') }
  let(:help_request_1) do
    create(
      :help_request,
      activity: activity_1,
      section: section,
      user: student,
      status: 'responded',
      created_at: 2.day.ago
    )
  end
  let(:help_request_2) do
    2.times do
      create(
        :help_request,
        activity: activity_2,
        section: section,
        user: student,
        status: 'responded',
        created_at: 2.day.ago
      )
    end
  end
  let(:help_request_response_1) do
    create(
      :help_request_response_notification,
      user: student,
      section: section,
      activity: activity_1,
      created_at: 2.day.ago
    )
  end

  let(:help_request_response_2) do
    Array.new(2) do
      create(
        :help_request_response_notification,
        user: student,
        section: section,
        activity: activity_2,
        created_at: 2.hour.ago
      )
    end
  end

  let(:title_no_tags) { 'announcement 1' }

  let(:announcement_1) do
    create(
      :announcement,
      title: "<strong>#{ title_no_tags }</strong>",
      body: 'blah',
      created_at: 1.day.ago
    )
  end
  let(:announcement_2) do
    create(
      :announcement,
      title: 'announcement 2',
      body: 'foo',
      created_at: Time.now
    )
  end
  let(:announcement_notification_1) do
    create(
      :announcement_posted_notification,
      section: section,
      user: student,
      announcement: announcement_1,
      created_at: 1.day.ago
    )
  end
  let(:announcement_notification_2) do
    create(
      :announcement_posted_notification,
      section: section,
      user: student,
      announcement: announcement_2,
      created_at: Time.now
    )
  end
  let(:score_action) do
    create(
      :gb_score_action,
      section_id: section.id,
      user_id: student.id,
      activity_id: activity_1.id,
      summation: {
        points_earned: 71.0,
        pending: true,
        points_possible: 100,
        submitted_at: Time.now
      }
    )
  end
  let(:activity_graded_notification) do
    create(
      :activity_graded_notification,
      user: student,
      section: section,
      activity: activity_1,
      created_at: Time.now
    )
  end

  let(:activity_1_label) { "#{lesson.label} | #{strand.name} | #{activity_1.title}" }
  let(:truncated_activity_1_label) { activity_1_label.shorten(36) }
  let(:activity_2_label) { "#{lesson.label} | #{strand.name} | #{activity_2.title}" }
  let(:truncated_activity_2_label) { activity_2_label.shorten(36) }

  alias_method :create_help_request_1, :help_request_1
  alias_method :create_help_request_2, :help_request_2
  alias_method :create_help_request_response_1, :help_request_response_1
  alias_method :create_help_request_response_2, :help_request_response_2
  alias_method :create_announcement_notification_1, :announcement_notification_1
  alias_method :create_announcement_notification_2, :announcement_notification_2
  alias_method :create_score_action, :score_action
  alias_method :create_activity_graded_notification, :activity_graded_notification

  before do
    content_filepath = File.join('spec', 'fixtures', 'xml', 'open_ended.xml')
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    allow(lesson).to receive(:strand_for_toc_location).and_return(strand)
    create_help_request_1
    create_help_request_2
    create_help_request_response_1
    create_help_request_response_2
    create_announcement_notification_1
    create_announcement_notification_2
    create_score_action
    create_activity_graded_notification
    initialize_program_access_client_calls_for_user_and_program(student, program)
    give_user_access_to_program(student, program)
    log_in_as(student)
    create(:active_enrollment, section: section, user: student)
  end

  scenario 'As a student' do
    step 'I log in as a student'
    purpose 'I see a list of notifications on my dashboard' do
      step 'Go to the dashboard home page' do
        visit student_dashboard_url
      end

      step 'I see "Notifications (2)"' do
        expect_notification_element(:count, 'Notifications (2)')
      end
      step 'I see a list of all the notifications' do
        validate_class_bulletin_announcement(
          help_request_response_1,
          date: '2 days ago'
        )
        validate_class_bulletin_announcement(
          help_request_response_2[1],
          date: 'about 2 hours ago'
        )
      end
    end

    purpose 'I see a page where all notifications of the section are displayed' do
      find('.test-notification-count a').click
      step 'I see unreviewed notifications' do
        validate_notification_summary(
          help_request_response_1,
          message: 'Your instructor responded to your help request.'
        )
        validate_notification_summary(
          activity_graded_notification,
          message: 'Your instructor graded this activity, giving you a score of 71%.'
        )
        validate_notification_summary(
          help_request_response_2[1],
          message: 'Your instructor responded to 2 help requests.'
        )
      end
      step 'I see previously reviewed notifications' do
        click_link 'Viewed'
        step 'I see no notification' do
          expect(page).to have_no_selector('.test-notification-label', visible: true)
        end
      end
    end

    purpose 'When I open an activity I see all notifications for that activity ' \
      'in a popup and they are automatically dismissed' do
      click_link 'Return to Dashboard'
      step 'Click on the notification for activity 1"' do
        find('.test-notification-label', text: activity_graded_notification.label.shorten(36)).click
      end
      step 'I see the activity "activity 1"' do
        expect(page).to have_selector('.test-activity-title', text: activity_1.title, visible: true)
      end
      step 'I see a link "Activity notifications"' do
        expect(page).to have_selector(
          ".test-notification-#{activity_graded_notification.id}",
          visible: true
        )

      end
      step 'I see a popup' do
        validate_notification_listing(
          help_request_response_1,
          'Your instructor responded to your help request.'
        )
        validate_notification_listing(
          activity_graded_notification,
          'Your instructor graded this activity, giving you a score of 71%.'
        )
      end
    end
    purpose 'I do not see dismissed notifications' do
      click_link 'Return to Dashboard'
      step 'I see "Notifications (1)' do
        expect_notification_element(:count, 'Notifications (1)')
      end
      step 'I do not see a link "lesson 1 | strand | activity 1' do
        expect(page).to have_no_selector(
          ".test-notification-id-#{activity_graded_notification.id}"
        )
      end
    end

    purpose 'I see the list of notifications, with the \
            ones I have reviewed in the activity view hidden' do
      find('.test-notification-count a').click
      step 'I see unreviewed notifications' do
        validate_notification_summary(
          help_request_response_2[1],
          message: 'Your instructor responded to 2 help requests.'
        )
      end

      step 'I see previously reviewed notifications' do
        click_link 'Viewed'
        validate_notification_summary(
          help_request_response_1,
          message: 'Your instructor responded to your help request.'
        )
        validate_notification_summary(
          activity_graded_notification,
          message: 'Your instructor graded this activity, giving you a score of 71%.'
        )
      end
    end

    purpose 'When I open an activity for which existing notifications ' \
            'have already been reviewed, I do not see the notification popup' do
      step 'Click on the link "lesson 1 | strand 1 | activity 1"' do
        click_link(activity_graded_notification.label, match: :first)
      end
      step 'I see the activity "activity 1"' do
        expect(page).to have_selector('.test-activity-title', text: activity_1.title, visible: true)
      end
      step 'I do not see the notification popup' do
        expect(page).to have_no_selector(".test-notification-#{help_request_response_1.id}")
        expect(page).to have_no_selector(".test-notification-#{activity_graded_notification.id}")
      end
      step 'I do not see the link "Activity notifications"' do
        expect(page).to have_no_selector('.test-notifications-link')
      end
    end

    purpose 'I see a list of announcement notifications on my dashboard' do
      visit student_dashboard_url
      expect_announcement_element(:count, 'Announcements (2)')
      validate_class_bulletin_announcement(
        announcement_notification_1,
        date: '1 day ago'
      )
      validate_class_bulletin_announcement(
        announcement_notification_2,
        date: time_ago_in_words(announcement_notification_2.created_at)
      )
    end

    purpose 'I see a page where all the announcement notifications are displayed' do
      find('a.test-announcement-count', text: 'Announcements').click

      step 'I see unreviewed announcements' do
        validate_notification_summary(
          announcement_notification_1
        )
        validate_notification_summary(
          announcement_notification_2
        )
      end
      step 'I see previously reviewed announcements' do
        click_link 'Viewed'
        step 'I see no notification' do
          expect(page).to have_no_selector(
            '.test-notification-label',
            visible: true
          )
        end
      end
    end

    purpose 'I can go back to the dashboard after seeing an announcement' do
      click_link 'Return to Dashboard'
      step 'Click on the "announcement 1" link' do
        page.find('.test-notification-label', text: title_no_tags).click
      end
      validate_announcement_details(announcement_1, title_no_tags)
      click_link 'Return to Dashboard'
    end

    purpose 'I see a page where all the announcement notifications are displayed' do
      find('a.test-announcement-count', text: 'Announcements').click

      step 'I see unreviewed announcements' do
        validate_notification_summary(
          announcement_notification_2
        )
      end
      step 'I see previously reviewed announcements' do
        click_link 'Viewed'
        validate_notification_summary(
          announcement_notification_1
        )
      end
    end
  end
end
