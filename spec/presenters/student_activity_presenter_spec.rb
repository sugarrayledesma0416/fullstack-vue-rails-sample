describe StudentActivityPresenter do
  let(:activity) { create(:activity) }
  let(:student) { build_stubbed(:student) }
  let(:instructor) { build_stubbed(:instructor) }
  let(:course) { build_stubbed(:course) }
  let(:section) { build_stubbed(:section, course: course) }
  let(:student_presenter) { described_class.new(activity, student, section) }
  let(:sb_activity) { build_stubbed(:activity, activity_type: 'smart_book') }
  let(:content_object) { create_activity_content('multi_type_activity_with_solo_video.xml') }

  def create_activity_content(xml_filename)
    xml = File.read("spec/fixtures/xml/#{xml_filename}")
    doc = Nokogiri::XML.parse(xml)
    MaestroActivityEngine::ActivityParser.create_parser(
      doc.to_s,
      MaestroActivityEngine::LinkedMediaItemStub
    ).parse
  end

  describe 'behaviours' do
    it 'should be a SharedActivityViewer' do
      expect(student_presenter).to be_a(SharedActivityViewer)
    end
  end

  describe '#notifications' do
    let(:strand) { create(:toc_entry) }

    it 'returns all the notifications for the current activity, student and section' do
      allow_any_instance_of(Lesson).to receive(:strand_for_toc_location).and_return(strand)

      # notification for a different user
      create(
        :activity_graded_notification,
        section:,
        user: create(:user),
        activity:,
      )
      # notification for a different section
      create(
        :activity_graded_notification,
        section: create(:section),
        user: student,
        activity:,
      )
      notification = create(
        :activity_graded_notification,
        section:,
        user: student,
        activity:,
        dismissed_at: 2.days.ago.to_date
      )
      unreviewed_notification = create(
        :activity_feedback_notification,
        section:,
        user: student,
        activity:
      )
      presenter = described_class.new(activity, student, section)
      expect(presenter.notifications).to contain_exactly(
        notification,
        unreviewed_notification
      )
    end
  end

  describe '#unreviewed_notifications' do
    let(:strand) { create(:toc_entry) }

    it 'returns the list of unreviewed notifications' do
      allow_any_instance_of(Lesson).to receive(:strand_for_toc_location).and_return(strand)

      create(
        :activity_graded_notification,
        section:,
        user: student,
        activity:,
        dismissed_at: 2.days.ago.to_date
      )
      unreviewed_notification = create(
        :activity_feedback_notification,
        section:,
        user: student,
        activity:
      )
      presenter = described_class.new(activity, student, section)
      expect(presenter.unreviewed_notifications).to contain_exactly(
        unreviewed_notification
      )
    end
  end

  describe '#assignment' do
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    let(:student) { create(:student) }

    it 'returns nil if there is no assignment for the current section and ' \
       'activity' do
      create(:assignment, assignable: create(:activity), section: section)
      create(:assignment, assignable: activity, section: create(:section))

      expect(student_presenter.assignment).to be_nil
    end

    it 'returns an assignment for the current section and activity that ' \
       'is assigned to all students' do
      assignment = create(
        :assignment,
        assignable: activity,
        individually_assignable: false,
        section: section
      )

      expect(student_presenter.assignment).to eq(assignment)
    end

    context 'when an assignment for the current section and activity is ' \
            'individually assignable,' do
      let!(:assignment) do
        create(
          :assignment,
          assignable: activity,
          individually_assignable: true,
          section: section
        )
      end

      it 'returns nil if it is not assigned for the current student' do
        expect(student_presenter.assignment).to be_nil
      end

      it 'returns the assignment if it is assigned for the current student' do
        IndividualAssignment.create!(
          activity_id: activity.id,
          section_id: section.id,
          user_id: student.id
        )

        expect(student_presenter.assignment).to eq(assignment)
      end
    end
  end

  describe '#allow_audio_transcripts?' do
    let(:instructor) { create(:instructor) }
    let(:course) { create(:course, allow_audio_transcripts: false) }
    let(:section) { create(:section, course:) }
    let(:student_presenter) { described_class.new(activity, student, section) }
    let(:instructor_presenter) { described_class.new(activity, instructor, section) }

    it 'returns true if the user is an instructor' do
      course.update!(allow_audio_transcripts: true)

      expect(instructor_presenter.allow_audio_transcripts?).to be true
    end

    context 'as a student' do
      it 'returns false if audio transcript is not allowed' do
        expect(student_presenter.allow_audio_transcripts?).to be false
      end

      it 'returns true if audio transcript is allowed' do
        course.update!(allow_audio_transcripts: true)

        expect(student_presenter.allow_audio_transcripts?).to be true
      end
    end
  end

  describe '#allows_expanded_notes?' do
    context 'when is an activity chat' do
      it 'returns false for partner chat activity' do
        activity.activity_type = 'partner_chat'
        expect(student_presenter.allows_expanded_notes?).to eq(false)
      end

      it 'returns false for virtual chat activity' do
        activity.activity_type = 'virtual_chat'
        expect(student_presenter.allows_expanded_notes?).to eq(false)
      end

      it 'returns false for video virtual chat activity' do
        activity.activity_type = 'video_virtual_chat'
        expect(student_presenter.allows_expanded_notes?).to eq(false)
      end
    end

    context 'when in not an activity chat' do
      it 'returns true for no chat activity' do
        activity.activity_type = 'other'
        expect(student_presenter.allows_expanded_notes?).to eq(true)
      end
    end

    context 'when it is a solo recording activity' do
      it 'returns false' do
        activity.activity_type = 'solo_video_recording'
        expect(student_presenter.allows_expanded_notes?).to eq(false)
      end
    end

    context 'when it is a multi_type containing a solo recording activity' do
      before do
        allow(activity).to receive(:content_object).and_return(content_object)
      end

      it 'returns false' do
        activity.activity_type = 'multi_type'
        activity.save!
        expect(student_presenter.allows_expanded_notes?).to eq(false)
      end
    end
  end

  describe 'activity_notes' do
    let(:other_instructor) { build_stubbed(:instructor) }
    let(:note) { build_stubbed(:activity_note) }

    it 'returns an empty array when there is no section' do
      presenter = StudentActivityPresenter.new(activity, student, section = nil)
      expect(presenter.activity_notes).to eq([])
    end

    it 'returns an empty array when section has no course' do
      section_without_course = build_stubbed(:section, :course => nil)
      presenter = StudentActivityPresenter.new(activity, student, section_without_course)
      expect(presenter.activity_notes).to eq([])
    end

    it 'returns notes for the current activity created by instructors responsible for current section' do
      instructor_ids = [instructor.id, other_instructor.id]
      expect(section).to receive(:responsible_instructor_ids).and_return(instructor_ids)
      expect(activity.activity_notes).to receive(:by_instructor).with(instructor_ids).and_return([note])
      expect(StudentActivityPresenter.new(activity, student, section).activity_notes).to eq([note])
    end

    it 'replaces the instructor id on the note_item_id when the activity is a virtual chat' do
      allow(activity).to receive(:virtual_chat?).and_return(true)
      note.note_item_id = "virtual_chat_user_#{instructor.id}_question_1"
      allow(activity.activity_notes).to receive(:by_instructor).and_return([note])
      returned_note = StudentActivityPresenter.new(activity, student, section).activity_notes.first
      expect(returned_note.note_item_id).to eq("virtual_chat_user_#{student.id}_question_1")
    end

    it 'replaces the instructor id on the note_item_id when the activity is a video virtual chat' do
      allow(activity).to receive(:video_virtual_chat?).and_return(true)

      note.note_item_id = "virtual_chat_user_#{instructor.id}_question_1"

      allow(activity.activity_notes).to receive(:by_instructor).and_return([note])

      returned_note = described_class.new(activity, student, section).activity_notes.first

      expect(returned_note.note_item_id).to eq "virtual_chat_user_#{student.id}_question_1"
    end
  end

  describe "#due_time_with_zone" do
    let(:student) { create(:student) }
    let(:course) do
      create(:course, start_date: Date.parse('2012-01-01'))
    end
    let(:section) do
      create(
        :section,
        course: course,
        time_zone: 'Pacific Time (US & Canada)',
        due_time: Time.parse('2000-01-01 08:00 UTC')
      )
    end
    let(:presenter) { StudentActivityPresenter.new(activity, student, section) }
    let!(:assignment) do
      create(
        :assignment,
        assignable: activity,
        individually_assignable: false,
        section: section,
        due_date: Date.parse('2013-02-14')
      )
    end

    context "when the current time zone does not match the section time zone" do
      it "returns the due time with time zone" do
        Time.use_zone('Central Time (US & Canada)') do
          expect(presenter.due_time_with_zone).to eq(" 8:00 AM PST")
        end
      end

      it "returns the custom due time if set with time zone" do
        assignment.update!(custom_due_time: Time.parse('2000-01-01 10:00 UTC'))

        Time.use_zone('Central Time (US & Canada)') do
          expect(presenter.due_time_with_zone).to eq("10:00 AM PST")
        end
      end
    end

    context "when the current time zone matches the section time zone" do
      it "returns just the due time" do
        Time.use_zone('Pacific Time (US & Canada)') do
          expect(presenter.due_time_with_zone).to eq(" 8:00 AM ")
        end
      end

      it "returns just the custom due time if set" do
        assignment.update!(custom_due_time: Time.parse('2000-01-01 10:00 UTC'))

        Time.use_zone('Pacific Time (US & Canada)') do
          expect(presenter.due_time_with_zone).to eq("10:00 AM ")
        end
      end
    end
  end

  describe "#has_smartbook_attempt_with_feedback?" do
    let(:sb_presenter) { described_class.new(sb_activity, student, section) }

    it 'returns false when activity is not a smartbook' do
      expect(student_presenter.has_smartbook_attempt_with_feedback?).to be false
    end

    it 'returns false when there are no feedback items on the attempt' do
      attempt = instance_double(Attempt, smartbook_responses_with_feedback: [])
      allow(attempt).to receive(:disable_enhanced_feedback=).and_return(nil)
      allow(Attempt).to receive(:find_or_create_with_scoring_ruleset).and_return(attempt)
      expect(sb_presenter.has_smartbook_attempt_with_feedback?).to be false
    end

    it 'returns true when there are feedback items on the attempt' do
      attempt = instance_double(Attempt, smartbook_responses_with_feedback: [instance_double(FeedbackItem), instance_double(FeedbackItem)])
      allow(attempt).to receive(:disable_enhanced_feedback=).and_return(nil)
      allow(Attempt).to receive(:find_or_create_with_scoring_ruleset).and_return(attempt)
      expect(sb_presenter.has_smartbook_attempt_with_feedback?).to be true
    end
  end

  describe StudentActivityPresenter::ActivityNotesSection do
    describe 'responsible_instructor_ids' do
      it 'returns unique responsible instructor and course owner ids' do
        course_owner         = create(:instructor)
        co_instructor        = create(:instructor)
        assistant_instructor = create(:instructor)
        course  = create(:course, :owner => course_owner)
        section = create(:section, :instructor => course_owner, :course => course)

        section.section_instructors.create(:role => 'Co-instructor', :instructor => co_instructor)
        section.section_instructors.create(role: '', instructor: assistant_instructor)

        section.extend(StudentActivityPresenter::ActivityNotesSection)

        expect(section.responsible_instructor_ids).to eq [course_owner.id, co_instructor.id]
      end
    end
  end

end
