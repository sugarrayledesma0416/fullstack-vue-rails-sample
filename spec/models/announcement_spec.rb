describe Announcement do
  let(:receiver) { create(:announcement) }
  let(:school) { build_stubbed(:school) }
  let(:program) { build_stubbed(:program) }
  let(:instructor) { create(:instructor) }

  let(:course) do
    create(:course, school: school, program: program, owner: instructor)
  end

  it_should_behave_like 'an object that sanitizes uploaded file names'
  it_should_behave_like 'an object that has file presence validation methods'
  it_should_behave_like 'an object that can read its related file data from an S3 bucket'

  describe 'notifications' do
    let(:section) { create(:section, course: course, instructor: course.owner) }
    let(:student) { create(:student) }
    let(:announcement) { create(:announcement, author: instructor) }

    it 'allows AnnouncementPostedNotifications to be dispatched via ' \
       'association extension' do
      announcement.notifications.dispatch(
        'AnnouncementPosted',
        section: section,
        user: student
      )

      notification = announcement.notifications.first

      expect(notification.class).to eq(AnnouncementPostedNotification)
      expect(notification.announcement).to eq(announcement)
      expect(notification.user).to eq(student)
      expect(notification.section).to eq(section)
    end

    context 'when announcement is saved,' do
      before do
        section.students << student
      end

      context 'when an announcement is for one section,' do
        it 'creates notifications for that section' do
          announcement = described_class.new(
            announcement_sections_attributes: [{ section_id: section.id }],
            author_id: instructor.id,
            body: '',
            title: 'title'
          )
          announcement.save!

          results = AnnouncementPostedNotification.where(
            section_id: section.id,
            announcement_id: announcement.id
          )
          expect(results.size).to eq(1)
          expect(results.first.user).to eq(student)
        end
      end

      context 'when an announcement is for a course with multiple sections,' do
        it 'creates notifications for all sections in the course' do
          section_2 = create(:section, course: course, instructor: course.owner)
          student_2 = create(:student)
          section_2.students << student_2

          announcement = described_class.new(
            author_id: course.owner.id,
            body: '',
            title: 'title',
            announcement_sections_attributes: [
              { section_id: section.id },
              { section_id: section_2.id }
            ]
          )
          announcement.save!

          section_1_notifications = AnnouncementPostedNotification.where(
            announcement_id: announcement.id, section_id: section.id
          )
          expect(section_1_notifications.size).to eq(1)
          expect(section_1_notifications.first.user).to eq(student)
          section_2_notifications = AnnouncementPostedNotification.where(
            announcement_id: announcement.id, section_id: section_2.id
          )
          expect(section_2_notifications.size).to eq(1)
          expect(section_2_notifications.first.user).to eq(student_2)
        end
      end

      context 'when an instructor only has access to a subset of the course sections' do
        it 'creates notifications only for the sections that the instructor teaches' do
          course = create(
            :course,
            owner: instructor,
            program: program,
            school: school
          )

          teacher = create(:instructor)
          target_section = create(:section, instructor: teacher, course: course)
          other_section  = create(:section, instructor: instructor, course: course)
          target_section.students << create(:student)
          other_section.students << create(:student)

          announcement = described_class.new(
            announcement_sections_attributes: [{ section_id: target_section.id }],
            author_id: teacher.id,
            body: '',
            title: 'title',
          )
          announcement.save!

          expect(
            AnnouncementPostedNotification.where(
              section_id: target_section.id,
              announcement_id: announcement.id
            ).size
          ).to eq(1)
          expect(
            AnnouncementPostedNotification.where(
              section_id: other_section.id,
              announcement_id: announcement.id
            ).size
          ).to eq(0)
        end
      end

      context 'when there are existing notifications for the same announcement,' do
        it 'deletes only existing notifications that have not been read' do
          announcement = described_class.new(
            announcement_sections_attributes: [{ section_id: section.id }],
            author_id: course.owner.id,
            body: '',
            title: 'title',
          )
          announcement.save!
          announcement.notifications.destroy_all # ensure we start out without any notifications

          unread_notification = create(
            :announcement_posted_notification,
            announcement: announcement,
            dismissed_at: nil,
            section: section,
            user: student
          )
          read_notification   = create(
            :announcement_posted_notification,
            announcement: announcement,
            dismissed_at: 1.day.ago,
            section: section,
            user: student
          )

          announcement.update!(:updated_at => Time.now)

          results = AnnouncementPostedNotification.where(
            announcement_id: announcement.id, section_id: section.id
          )
          expect(results).not_to include unread_notification
          expect(results).to include read_notification
        end
      end

      context 'when being archived,' do
        it 'removes any associated notifications' do
          announcement = described_class.new(
            announcement_sections_attributes: [{ section_id: section.id }],
            author_id: section.instructor.id,
            body: '',
            title: 'title'
          )
          announcement.save!
          expect(announcement.notifications.reload).not_to be_empty
          announcement.update(is_archived: true)
          announcement.reload
          expect(announcement.notifications).to be_empty
        end
      end
    end
  end

  describe 'validations' do
    it "should validate the presence of a title" do
      title = ''
      announcement = build(:announcement, :title => title)
      expect(announcement).not_to be_valid
      expect(announcement.errors.messages[:title]).to include 'is required'
    end

    it 'validates the presence of author_id' do
      ann = described_class.new
      expect(ann).not_to be_valid
      expect(ann.errors[:author_id]).to include I18n.t('activerecord.errors.messages')[:blank]
    end

    it 'should be valid title' do
      title = 'Not so important announcement'
      announcement = create(:announcement, title: title, author: create(:instructor))
      expect(announcement).to be_valid
    end

    context 'when external link url has been set' do
      let(:announcement_1) { create(:announcement, title: 'Some title') }

      it 'is valid if url has no protocol' do
        announcement_1.external_link_url = "www.some.url.com"
        expect(announcement_1).to be_valid
      end

      it 'is invalid if url has a misspelled protocol' do
        announcement_1.external_link_url = 'hlp://www.some.url.com'
        expect(announcement_1).not_to be_valid
        expect(announcement_1.errors.messages[:external_link_url]).to include 'is invalid'
      end

      it 'is invalid if url has special chars' do
        announcement_1.external_link_url = 'www.@someñ.url.com'
        expect(announcement_1).not_to be_valid
        expect(announcement_1.errors.messages[:external_link_url]).to include 'is invalid'
      end

      it 'is invalid if url has no server name' do
        announcement_1.external_link_url = 'http://.url'
        expect(announcement_1).not_to be_valid
        expect(announcement_1.errors.messages[:external_link_url]).to include 'is invalid'
      end

      it 'is invalid if domain or top-level domain has only one letter' do
        announcement_1.external_link_url = 'http://url.i'
        expect(announcement_1).not_to be_valid
        expect(announcement_1.errors.messages[:external_link_url]).to include 'is invalid'
      end

      it 'is valid for shorten urls' do
        announcement_1.external_link_url = 'http://goo.gl/n8DtR'
        expect(announcement_1).to be_valid
      end

      it 'is valid for correct urls' do
        announcement_1.external_link_url = "http://www.vhlcentral.com"
        expect(announcement_1).to be_valid
      end
    end
  end

  describe "scopes" do
    describe ".by_section" do
      it "should return only the announcements that belong to the passed section" do
        course = create(:course, :school => school, :program => program, :owner => instructor)
        section_1 = create(:section_with_course, :course => course, :instructor => instructor)
        section_2 = create(:section_with_course, :course => course, :instructor => instructor)

        announcement_section_1 = create(:announcement, :author => instructor)
        create(:announcement_section, announcement: announcement_section_1 , section: section_1)

        announcement_section_2 = create(:announcement, :author => instructor)
        create(:announcement_section, announcement: announcement_section_2 , section: section_2)

        results = described_class.by_section(*section_1)
        expect(results).to include announcement_section_1
        expect(results).not_to include announcement_section_2
      end

      it "should return only the announcements that belong to the passed sections" do
        course = create(:course, :school => school, :program => program, :owner => instructor)
        section_1 = create(:section_with_course, :course => course, :instructor => instructor)
        section_2 = create(:section_with_course, :course => course, :instructor => instructor)

        announcement_section_1 = create(:announcement, :author => instructor)
        create(:announcement_section, announcement: announcement_section_1 , section: section_1)
        announcement_section_2 = create(:announcement, :author => instructor)
        create(:announcement_section, announcement: announcement_section_2 , section: section_2)
        results = described_class.by_section(*[section_1, section_2])
        expect(results).to include announcement_section_1
        expect(results).to include announcement_section_2
      end

      it "should return empty array if no course and section are specified" do
        course = create(:course, :school => school, :program => program, :owner => instructor)
        section_1 = create(:section_with_course, :course => course, :instructor => instructor)
        section_2 = create(:section_with_course, :course => course, :instructor => instructor)
        announcement_section_1 = create(:announcement, :author => instructor)
        announcement_section_2 = create(:announcement, :author => instructor)
        expect(described_class.by_section(*[])).to eq([])
      end
    end

    describe ".default" do
      let(:course) { create(:course, :owner => instructor) }
      let(:section) { create(:section_with_course, :course => course, :instructor => instructor) }

      it "retrieves only non-archived announcements" do
        non_archived_announcement = create(:announcement, :author => instructor, :is_archived => false)
        create(:announcement_section, announcement: non_archived_announcement , section: section)
        archived_announcement = create(:announcement, :author => instructor, :is_archived => true)
        create(:announcement_section, announcement: archived_announcement , section: section)
        results = described_class.all
        expect(results).not_to include archived_announcement
        expect(results).to include non_archived_announcement
      end

      it "returns announcements ordered by creation date, newest first" do
        third_announcement  = create(:announcement, :author => instructor, :created_at => Time.now)
        create(:announcement_section, announcement: third_announcement, section: section)
        second_announcement = create(:announcement, :author => instructor, :created_at => 1.day.ago)
        create(:announcement_section, announcement: second_announcement, section: section)
        first_announcement  = create(:announcement, :author => instructor, :created_at => 2.days.ago)
        create(:announcement_section, announcement: first_announcement, section: section)
        returned_announcement = described_class.by_section(section)
        expect(returned_announcement[0]).to eq(third_announcement)
        expect(returned_announcement[1]).to eq(second_announcement)
        expect(returned_announcement[2]).to eq(first_announcement)
      end
    end
  end

  describe "accepts nested attributes for announcement sections" do
     let(:section_1) { create(:section, :course => course) }
     let(:section_2) { create(:section, :course => course) }

    it "destorying a announcement should delete the announcement sections" do
      params = { :author => instructor, :title => "title", :body => '',
                 :announcement_sections_attributes => [{ :section_id => section_1.id}, {:section_id => section_2.id}] }
      announcement = described_class.new(params)
      announcement.save
      expect(AnnouncementSection.count).to eql(2)
      announcement.reload
      announcement.destroy
      expect(AnnouncementSection.count).to be_zero
    end

    it "creates new announcement sections" do
      params = { :author => instructor, :title => "title", :body => '',
                 :announcement_sections_attributes => [{ :section_id => section_1.id}, {:section_id => section_2.id}] }
      announcement = described_class.new(params)
      announcement.save
      expect(announcement.announcement_sections.map(&:section_id)).to eql([section_1.id, section_2.id])
    end

    it "adds to existing list of announcement sections, when updated " do
      params = { :author => instructor, :title => "title", :body => '',
                 :announcement_sections_attributes => [{ :section_id => section_1.id}] }
      announcement = described_class.new(params)
      announcement.save
      expect(announcement.announcement_sections.map(&:section_id)).to eql([section_1.id])
      announcement.update({:announcement_sections_attributes => [{:section_id => section_2.id}]})
      announcement.reload
      expect(announcement.announcement_sections.map(&:section_id)).to eql([section_1.id, section_2.id])
    end

    it "removes announcement sections links, when marked" do
      params = { :announcement_sections_attributes => [{ :section_id => section_1.id}] }
      announcement = create(:announcement, :author => instructor, :title => "title")
      announcement.update({:announcement_sections_attributes => [
        {:section_id => section_1.id}
      ]})
      announcement.reload
      expect(announcement.announcement_sections.map(&:section_id)).to eql([section_1.id])
      announcement.update({:announcement_sections_attributes => [
        {:id => announcement.announcement_sections.first.id, :announcement_id => announcement.id, :section_id => section_1.id, "_destroy" => "true"},
        {:section_id => section_2.id}
      ]})
      announcement.reload
      expect(announcement.announcement_sections.map(&:section_id)).to eql([section_2.id])
    end
  end

  describe '.by_month_and_calendar_day' do
    let(:section) { create(:section, course: course) }
    let(:today) { Date.today }
    let(:month_number) { today.month }
    let(:month_first_day) { Date.parse "#{today.year}-#{today.month}-01" }
    let(:cancelled_class_day) { month_first_day + 1.weeks }

    before do
      announcement_1 = create(:announcement, show_on: month_first_day)
      announcement_2 = create(:announcement, show_on: month_first_day)
      announcement_3 = create(:announcement, show_on: month_first_day + 2.weeks)
      announcement_4 = create(:announcement, show_on: month_first_day + 1.month)

      # class cancelled on `month_first_day + 1.weeks`
      announcement_5 = create(:announcement, show_on: cancelled_class_day)
      announcement_6 = create(:announcement, show_on: cancelled_class_day, class_cancelled: true)

      AnnouncementSection.create(section_id: section.id, announcement_id: announcement_1.id)
      AnnouncementSection.create(section_id: section.id, announcement_id: announcement_2.id)
      AnnouncementSection.create(section_id: section.id, announcement_id: announcement_3.id)
      AnnouncementSection.create(section_id: section.id, announcement_id: announcement_4.id)
      AnnouncementSection.create(section_id: section.id, announcement_id: announcement_5.id)
      AnnouncementSection.create(section_id: section.id, announcement_id: announcement_6.id)
    end

    it 'returns announcements for the given month number' do
      results = described_class.by_month_and_calendar_day([section], month_number)
      expect(results[month_first_day].announcement_count).to eq(2)
      expect(results[month_first_day + 2.weeks].announcement_count).to eq(1)
      expect(results[month_first_day + 1.month]).to be_nil
    end

    it 'returns class is not cancelled when none of announcements has class cancel instruction' do
      results = described_class.by_month_and_calendar_day([section], month_number)
      expect(results[month_first_day].any_class_cancelled).to eq(0)
    end

    it 'returns class is cancelled when any one of announcements has class cancel instruction' do
      results = described_class.by_month_and_calendar_day([section], month_number)
      expect(results[cancelled_class_day].any_class_cancelled).to eq(1)
    end
  end

  describe '#dismiss_notifications_for_user_and_section' do
    it 'dismisses notifications for this announcement for the specified user and section' do
      section = create(:section_with_course, :course => course, :instructor => instructor)
      student = create(:student)
      announcement = create(:announcement, :author => instructor)
      other_announcement = create(:announcement, :author => instructor)

      target_notification             = AnnouncementPostedNotification.create!(:announcement => announcement,
                                                                               :user => student, :section => section)
      other_announcement_notification = AnnouncementPostedNotification.create!(:announcement => other_announcement,
                                                                               :user => student, :section => section)
      other_student_notification      = AnnouncementPostedNotification.create!(:announcement => announcement,
                                                                               :user => create(:student), :section => section)
      other_section_notification      = AnnouncementPostedNotification.create!(:announcement => announcement,
                                                                               :user => student, :section => create(:section))
      announcement.dismiss_notifications_for_user_and_section(student, section)
      expect(target_notification.reload).to be_dismissed
      expect(other_announcement_notification.reload).not_to be_dismissed
      expect(other_student_notification.reload).not_to be_dismissed
      expect(other_section_notification.reload).not_to be_dismissed
    end
  end

  describe '#create_notification_if_missing' do
    let (:section) { create(:section_with_course, :course => course, :instructor => instructor) }
    let (:student) { create(:student) }
    let (:announcement) { create(:announcement, :author => instructor) }

    before do
      announcement.notifications.destroy_all # ensure we start out without any notifications
      section.students << student
    end

    context 'when no notifications exist for specified student, section, and announcement' do
      it 'creates a new notification' do
        announcement.create_notification_if_missing(student, section)
        results = AnnouncementPostedNotification.where(section_id: section.id, announcement_id: announcement.id)
        expect(results.size).to eq(1)
        expect(results.first.user).to eq(student)
      end
    end

    context 'when there are existing notifications for the specified student, section, and announcement,' do
      it 'leaves those notifications alone and does not create duplicates' do
        unread_notification = create(:announcement_posted_notification, :user => student, :section => section,
                                        :dismissed_at => nil, :announcement => announcement)
        read_notification   = create(:announcement_posted_notification, :user => student, :section => section,
                                        :dismissed_at => 1.day.ago, :announcement => announcement)

        announcement.create_notification_if_missing(student, section)
        results = AnnouncementPostedNotification.where(section_id: section.id, announcement_id: announcement.id)
        expect(results.size).to eq(2)
        expect(results).to match_array([read_notification, unread_notification])
      end
    end
  end

  describe '.create_missing_notifications_for_student_in_section' do
    let (:section) { create(:section, :course => course, :instructor => instructor) }
    let (:student) { create(:student) }

    it 'finds announcements for the specified section and course and creates missing notifications' do
      announcement =  create(:announcement, :author => instructor)
      create(:announcement_section, announcement: announcement, section: section)

      expected_params = {:section => section, :course => section.course}
      expect(described_class).to receive(:by_section).with(*section).and_return([announcement])
      expect(announcement).to receive(:create_notification_if_missing).with(student, section)

      described_class.create_missing_notifications_for_student_in_section(student, section)
    end
  end

  describe "#file_path" do
    context "when announcement has a file name specified" do
      it "returns the path to announcement file folder" do
        announcement =  create(:announcement, :file_name => "file.test", :author => instructor)
        expected_path = "announcements/#{M3::Application.config.current_deployed_env_name}/#{announcement.id.to_s}/#{announcement.file_name}"
        expect(announcement.file_path.to_s).to eq(expected_path)
      end
    end

    context "when announcement has no file name specified" do
      it "returns the path to announcement file folder" do
        announcement = create(:announcement, author: instructor)
        expect(announcement.file_path).to eq('')
      end
    end
  end

  describe '#signed_url' do
    let(:url_signer_mock) { double(Aws::CF::Signer) }

    context 'with an attachment file' do
      it 'returns the 404 url' do
        announcement = create(:announcement, file_name: '')
        expect(announcement.signed_url).to eq '/404'
      end
    end

    context 'without an attachment file' do
      it 'creates a signed url for the bucket path' do
        announcement = create(:announcement, file_name: 'some_file.txt')
        mock_bucket = 'test.files.vhlcentral.dom'
        allow(Radner).to receive(:bucket_name).and_return(mock_bucket)
        expect(Aws::CF::Signer).to receive(:sign_url).with(
          "https://#{mock_bucket}/#{announcement.file_path}",
          expires: kind_of(Time)
        )
        announcement.signed_url
      end
    end
  end

  describe '#signed_url' do
    let(:url_signer_mock) { instance_double(Aws::CF::Signer) }

    context 'with an attachment file' do
      it 'returns the 404 url' do
        announcement = create(:announcement, file_name: '')
        expect(announcement.signed_url).to eq '/404'
      end
    end

    context 'without an attachment file' do
      it 'creates a signed url for the bucket path' do
        announcement = create(:announcement, file_name: 'some_file.txt')
        mock_bucket = 'test.files.vhlcentral.dom'
        allow(Radner).to receive(:bucket_name).and_return(mock_bucket)
        expect(Aws::CF::Signer).to receive(:sign_url).with(
          "https://#{mock_bucket}/#{announcement.file_path}",
          expires: kind_of(Time)
        )
        announcement.signed_url
      end
    end
  end
end
