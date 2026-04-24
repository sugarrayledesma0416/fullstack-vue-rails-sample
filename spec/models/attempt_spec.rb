describe Attempt, core: true do
  include GradebookEngineHelpers
  include CourseBuilder

  it 'creates a new instance given valid attributes' do
    expect do
      attempt = create(:attempt)
      expect(attempt.errors).to be_empty
    end.to change(Attempt, :count)
  end

  it 'requires user' do
    expect do
      attempt = build(:attempt, user: nil)
      attempt.save
      expect(attempt.errors[:user_id]).to contain_exactly('is required')
    end.not_to change(Attempt, :count)
  end

  it 'requires activity' do
    expect do
      attempt = build(:attempt, activity: nil)
      attempt.save
      expect(attempt.errors[:activity_id]).to contain_exactly('is required')
    end.not_to change(Attempt, :count)
  end

  it 'allows blank section' do
    attempt = create(:attempt, section: nil)
    expect(attempt.errors).to be_empty
  end

  describe 'scopes' do
    describe '.without_time_spent' do
      before(:each) do
        @without_time_spent = create(:attempt, time_spent: 0)
        @with_time_spent = create(:attempt, time_spent: 10)
      end

      it 'returns attempts with time spent equal to 0' do
        expect(Attempt.without_time_spent).to match_array([@without_time_spent])
      end
    end

    describe '.active' do
      it 'returns attempts with any status except reset' do
        submitted_attempt = create(:attempt_submitted)
        opened_attempt    = create(:attempt_opened)
        completed_attempt = create(:attempt_completed)
        unopened_attempt  = create(:attempt, status_code: AttemptStatus::CODE_UNOPENED)
        reset_attempt     = create(:attempt_reset)
        results = Attempt.active
        expect(results).to include submitted_attempt
        expect(results).to include opened_attempt
        expect(results).to include completed_attempt
        expect(results).to include unopened_attempt
        expect(results).to_not include reset_attempt
      end
    end

    describe '.was_reset' do
      it 'returns attempts with status of reset' do
        create(:attempt_submitted)
        reset_attempt = create(:attempt_reset)
        results = described_class.was_reset
        expect(results).to contain_exactly(reset_attempt)
      end
    end

    context 'submitted_attempts' do
      it 'should return attempt with status code is submitted' do
        section = build_stubbed(:section)
        student_1 = build_stubbed(:student)
        allow(section).to receive(:current_students_base).and_return([student_1])
        attempt_1 = create(:attempt,
                            section: section,
                            user: student_1,
                            activity: build_stubbed(:activity),
                            status_code: AttemptStatus::CODE_SUBMITTED)
        expect(Attempt.submitted_attempts(section, [attempt_1.activity])).to match_array([attempt_1])
      end

      it 'should return attempt with status code is completed ' do
        section = build_stubbed(:section)
        student_1 = build_stubbed(:student)
        allow(section).to receive(:current_students_base).and_return([student_1])
        attempt_1 = create(:attempt,
                            section: section,
                            user: student_1,
                            activity: build_stubbed(:activity),
                            status_code: AttemptStatus::CODE_COMPLETED)
        expect(Attempt.submitted_attempts(section, [attempt_1.activity])).to match_array([attempt_1])
      end

      it 'should return attempts only from the given section,activity, ' do
        section = build_stubbed(:section)
        student_1 = build_stubbed(:student)
        activity_1 = build_stubbed(:activity)
        allow(section).to receive(:current_students_base).and_return([student_1])
        attempt_1 = create(:attempt,
                            section: section,
                            user: student_1,
                            activity: activity_1,
                            status_code: AttemptStatus::CODE_COMPLETED)

        section_2 = build_stubbed(:section)
        allow(section_2).to receive(:current_students_base).and_return([student_1])
        # With different section:
        create(:attempt,
                section: section_2,
                user: student_1,
                activity: activity_1,
                status_code: AttemptStatus::CODE_COMPLETED)

        student_2 = build_stubbed(:student)
        # With different user:
        create(:attempt,
                section: section,
                user: student_2,
                activity: activity_1,
                status_code: AttemptStatus::CODE_COMPLETED)

        activity_2 = build_stubbed(:activity)
        # With different activity:
        create(:attempt,
                section: section,
                user: student_1,
                activity: activity_2,
                status_code: AttemptStatus::CODE_COMPLETED)

        expect(Attempt.submitted_attempts(section, [activity_1])).to match_array([attempt_1])
      end
    end

    describe '.submitted_or_completed' do
      it 'returns submitted or completed attempts' do
        section = create(:section)
        completed_attempt = create(:attempt_completed, section: section)
        submitted_attempt = create(:attempt_submitted, section: section)
        resetted_attempt = create(:attempt_reset, section: section)
        expect(Attempt.submitted_or_completed).to match_array([completed_attempt, submitted_attempt])
      end
    end

    describe '.by_section' do
      let(:section_1) { create(:section) }
      let(:section_2) { create(:section) }

      before do
        @attempt_in_section_1 = create(:attempt, section: section_1)
        @attempt_in_section_2 = create(:attempt, section: section_2)
      end

      it 'returns attempts in that section' do
        expect(Attempt.by_section(section_1)).to match_array([@attempt_in_section_1])
      end

      it 'returns attempts in those sections' do
        expect(Attempt.by_section(section_1, section_2)).to match_array([@attempt_in_section_1, @attempt_in_section_2])
      end
    end

    describe '.by_activities' do
      before(:each) do
        @activity_1 = create(:activity)
        @activity_2 = create(:activity)
        @attempt_1 = create(:attempt, activity: @activity_1)
        @attempt_2 = create(:attempt, activity: @activity_2)
      end

      it 'returns attempts for that activity' do
        expect(Attempt.by_activities(@activity_1)).to match_array([@attempt_1])
      end

      it 'returns attempts for all activities' do
        expect(Attempt.by_activities(@activity_1, @activity_2)).to match_array([@attempt_1, @attempt_2])
      end
    end

    describe '.by_student' do
      before(:each) do
        @student_1 = create(:student)
        @student_2 = create(:student)
        @attempt_1 = create(:attempt, user: @student_1)
        @attempt_2 = create(:attempt, user: @student_2)
      end

      it 'returns attempts for a student' do
        expect(Attempt.by_student(@student_1)).to match_array([@attempt_1])
      end

      it 'returns attempts in that section' do
        expect(Attempt.by_student(@student_1, @student_2)).to match_array([@attempt_1, @attempt_2])
      end
    end
  end

  describe '#results' do
    let(:completed_attempt) { create(:attempt_completed) }
    let(:saved_attempt) { create(:attempt) }
    let(:revision_activity) { create(:activity) }
    let(:response_01) do
      { label: result_labels[0],
        correctness: 'correct',
        response: 'First open ended answer' }
    end

    let(:response_02) do
      { label: result_labels[1],
        correctness: 'correct',
        response: 'Second open ended answer' }
    end

    let(:response_03) do
      { label: result_labels[2],
        correctness: 'incorrect',
        response: 'Another oe answer' }
    end

    let(:response_04_wol_1) do
      { label: result_labels[3],
        correctness: 'incorrect',
        response: 'haora' }
    end

    let(:response_04_wol_2) do
      { label: result_labels[4],
        correctness: 'incorrect',
        response: 'estava' }
    end

    let(:response_04_wol_3) do
      { label: result_labels[5],
        correctness: 'correct',
        response: 'estuve' }
    end

    let(:attempt_results) do
      [response_01, response_02, response_03,
       response_04_wol_1, response_04_wol_2, response_04_wol_3]
    end

    let(:answers) { [response_01, response_02, response_03] }
    let(:wol_answers) { [response_04_wol_1, response_04_wol_2, response_04_wol_3] }

    let(:processed_results) do
      double(MaestroActivityEngine::ActivityContent::Results, results: answers + wol_answers)
    end

    let(:result_labels) do
      [question_label('01', 'open_ended'),
       question_label('02', 'open_ended'),
       question_label('03', 'open_ended'),
       question_label('04_wol_1', 'fill_in_the_blanks'),
       question_label('04_wol_2', 'fill_in_the_blanks'),
       question_label('04_wol_3', 'fill_in_the_blanks')
      ]
    end

    let(:content_object) do
      double(
        'ContentObject',
        language: 'es',
        result_labels: result_labels,
        includes_solo_video_recording?: false
      )
    end

    before do
      allow(completed_attempt).to receive(:revision_activity).and_return(revision_activity)
      allow(revision_activity).to receive(:content_object).and_return(content_object)
      allow(completed_attempt).to receive(:activity).and_return(revision_activity)

      stub_request(:get, /submissions\?id\&partition_key=\d{4}\-\d{2}\-\d{2}/)
         .to_return(:status => 200, :body => "", :headers => {})
    end

    it 'returns all the results given in the attempt when the attempt has been submitted' do
      allow(content_object).to receive(:validate_responses).and_return(processed_results)
      allow(completed_attempt).to receive(:submission_migration_needed?).and_return(false)
      allow(completed_attempt).to receive(:submitted_values?).and_return(true)

      expect(completed_attempt.results.results).to eq answers + wol_answers
    end

    context 'when the attempt has saved responses and has not been submitted' do
      it 'creates a new Results instance' do
        allow(saved_attempt).to receive(:submitted_values?).and_return(false)
        allow(saved_attempt).to receive(:submission_migration_needed?).and_return(false)
        allow(saved_attempt).to receive(:saved_values?).and_return(true)

        expect(MaestroActivityEngine::ActivityContent::Results).to receive(:new).and_call_original

        saved_attempt.results
      end
    end

    context 'when results is called multiple times' do
      let(:attempt) { create(:attempt) }
      let(:results) { double(MaestroActivityEngine::ActivityContent::Results) }

      before do
        allow(attempt).to receive(:find_results).and_return(results)
      end

      it 'memoize the returned value' do
        attempt.results
        attempt.results

        expect(attempt).to have_received(:find_results).once
      end
    end
  end

  describe '#results_for_question' do
    it 'calculates the results only once' do
      attempt = create(:attempt)
      results = double(MaestroActivityEngine::ActivityContent::Results)
      allow(attempt).to receive(:results).and_return(results)
      expect(attempt).to receive(:results).once

      attempt.results_for_question('question_01')
      attempt.results_for_question('question_02')
    end
  end

  describe '#submission_partition_key' do
    let(:attempt) { create(:attempt)  }
    let(:date)    { '2014-01-03' }

    it 'returns a string based on the attempt created_at' do
      Timecop.freeze(Time.zone.parse("#{date} 08:00:00")) do
        expect(attempt.submission_partition_key).to eql(date)
      end
    end

    it 'returns a date adjusted for utc' do
      Timecop.freeze(Time.zone.parse("#{date} 22:00:00")) do
        expect(attempt.submission_partition_key).to eql(1.day.from_now.strftime('%Y-%m-%d'))
      end
    end

    it 'returns utc date when a user with a timezone mapping to the previous day submits' do
      date = Time.zone.parse('2015-06-29 08:37:27 UTC')
      Timecop.freeze(date) do
        attempt
      end

      Timecop.freeze(date) do
        Time.use_zone('Hawaii') do
          expect(Attempt.first.submission_partition_key).to eql('2015-06-29')
        end
      end
    end

    it 'returns utc date when a user with a timezone mapping to the next day submits' do
      date = Time.zone.parse('2015-06-29 23:37:27 UTC')
      Timecop.freeze(date) do
        attempt
      end

      Timecop.freeze(date) do
        Time.use_zone('Tokyo') do
          expect(Attempt.first.submission_partition_key).to eql('2015-06-29')
        end
      end
    end

    it 'returns a utc date when the record is new' do
      Timecop.freeze(Time.zone.parse("#{date} 08:00:00")) do
        new_attempt = build(:attempt)
        expect(new_attempt.submission_partition_key).to eq date
      end
    end
  end

  describe '.completed_or_submitted_by_students_sections_and_activity' do
    let(:student_1) { create(:student) }
    let(:student_2) { create(:student) }
    let(:section_1) { create(:section) }
    let(:section_2) { create(:section) }
    let(:activity) { create(:activity) }

    it 'returns a list of completed or submitted attempts for student, section and activity' do
      attempt = create(:attempt_completed, section: section_1, user: student_1, activity: activity)
      expect(Attempt.completed_or_submitted_by_students_sections_and_activity(student_1,
                                                                              section_1,
                                                                              activity)).to match_array([attempt])
    end

    it 'returns a list of completed or submitted attempts for students, sections and activities' do
      attempt_1  = create(:attempt_completed, section: section_1, user: student_1, activity: activity)
      attempt_2  = create(:attempt_completed, section: section_2, user: student_2, activity: activity)
      students   = [student_1, student_2]
      sections   = [section_1, section_2]
      results = Attempt.completed_or_submitted_by_students_sections_and_activity(students, sections, activity)
      expect(results).to match_array([attempt_1, attempt_2])
    end
  end

  describe '#help_requestable?' do
    let(:activity) { build_stubbed(:activity) }
    let(:attempt) { build_stubbed(:attempt, activity: activity) }

    context 'when uncompleted attempt' do
      before do
        allow(attempt).to receive(:completed?).and_return(false)
      end

      it 'returns true' do
        expect(attempt.help_requestable?).to be_truthy
      end
    end

    context 'when completed attempt' do
      before do
        allow(attempt).to receive(:completed?).and_return(true)
      end

      it 'returns true when activity is not submittable' do
        allow(activity).to receive(:submittable?).and_return(false)
        expect(attempt.help_requestable?).to be_truthy
      end

      it 'returns false when activity is submittable' do
        allow(activity).to receive(:submittable?).and_return(true)
        expect(attempt.help_requestable?).to be_falsey
      end
    end
  end

  describe '#review_requestable?' do
    let(:activity) { build_stubbed(:activity) }
    let(:attempt) { build_stubbed(:attempt, activity: activity) }

    it 'returns false if attempt is not completed' do
      allow(attempt).to receive(:completed?).and_return(false)
      allow(activity).to receive(:submittable?).and_return(true)
      expect(attempt.review_requestable?).to be_falsey
    end

    it 'returns false if activity is no submittable' do
      allow(attempt).to receive(:completed?).and_return(true)
      allow(activity).to receive(:submittable?).and_return(false)
      expect(attempt.review_requestable?).to be_falsey
    end

    it 'returns true if activity is submittable and attempt is completed' do
      allow(attempt).to receive(:completed?).and_return(true)
      allow(activity).to receive(:submittable?).and_return(true)
      expect(attempt.review_requestable?).to be_truthy
    end
  end

  describe '.activity_xml_file_paths' do
    let(:section) { create(:section) }

    context 'when there are no attempts for specified section' do
      it 'returns an empty array' do
        expect(Attempt.activity_xml_file_paths([section])).to eql []
      end
    end

    context 'when there are attempts for specified section' do
      it 'returns a de-duped list of activity xmls' do
        activity = create(:activity)
        attempt_1 = create(:attempt, section: section, activity: activity, cms_revision_id: 1000)
        attempt_2 = create(:attempt, section: section, activity: activity, cms_revision_id: 1000)
        expect(Attempt.activity_xml_file_paths([section]))
          .to eql [Activity.filepath_from_revision_id(attempt_1.cms_revision_id)]
      end
    end
  end

  describe '#find_or_create_ai_virtual_chat_session' do
    let!(:activity) { create(:activity, activity_type: 'ai_virtual_chat') }
    let(:user) { create(:user) }

    before do
      question = instance_double(
        MaestroActivityEngine::ActivityContent::AIVirtualChat::Item,
        initial_prompt: 'Hey there!'
      )
      content_object = instance_double(
        MaestroActivityEngine::ActivityContent::AIVirtualChatContent,
        activity_type: 'ai_virtual_chat',
        question:
      )
      allow_any_instance_of(Activity).to receive(:content_object).and_return(content_object)
    end

    context 'with a non-practice attempt,' do
      let(:attempt) { create(:attempt, activity:, user_id: user.id) }

      it 'returns nil if the attempt is not persisted' do
        unsaved_attempt = build(:attempt, practice: false)

        expect(unsaved_attempt.find_or_create_ai_virtual_chat_session).to be_nil
      end

      it 'returns a ConversationSession record if one exists with ' \
         'the id of the current attempt' do
        session = AI::ConversationSession.create!(
          activity_id: attempt.activity_id, attempt:, user_id: attempt.user_id
        )

        expect(attempt.find_or_create_ai_virtual_chat_session).to eq(session)
      end

      context 'when no ConversationSession exists with the id of ' \
              'the current attempt' do
        it 'creates and returns a new ConversationSession record' do
          session = attempt.find_or_create_ai_virtual_chat_session

          expect(session).to be_persisted
        end

        it 'sets the activity_id and user_id of the ConversationSession ' \
           'same values as the attempt' do
          session = attempt.find_or_create_ai_virtual_chat_session

          expect(session).to have_attributes(
            activity_id: attempt.activity_id, user_id: attempt.user_id
          )
        end
      end
    end

    context 'with a practice attempt,' do
      let(:attempt) do
        build(:attempt, activity_id: activity.id, practice: true, user_id: user.id)
      end

      it 'creates and returns a ConversationSession record' do
        session = attempt.find_or_create_ai_virtual_chat_session

        expect(session).to be_persisted
      end

      it 'does not set the attempt_id of the ConversationSession record' do
        session = attempt.find_or_create_ai_virtual_chat_session

        expect(session.attempt_id).to be_nil
      end

      it 'sets the activity_id and user_id of the ConversationSession ' \
         'same values as the attempt' do
        session = attempt.find_or_create_ai_virtual_chat_session

        expect(session).to have_attributes(
          activity_id: attempt.activity_id, user_id: attempt.user_id
        )
      end
    end
  end

  describe '#mark_as_started' do
    it 'sets the status code to code started' do
      attempt = create(:attempt, status_code: nil)
      attempt.mark_as_started!
      expect(attempt.reload.status_code).to eql(AttemptStatus::CODE_STARTED)
    end
  end

  describe '#time_left_in_seconds' do
    let(:attempt) { create(:attempt) }
    it 'return 0, when there is no assignment' do
      attempt = create(:attempt)
      expect(attempt.time_left_in_seconds).to eql(0)
    end

    context 'when the activity is assigned' do
      let(:course) { create_course_with_stubs }
      let(:section) { create(:section, course: course) }
      let(:assignment) { create(:assignment, section: section) }

      it 'return 0, when there is no time_limit on assignment' do
        allow(attempt).to receive(:assignment).and_return(assignment)
        expect(attempt.time_left_in_seconds).to eql(0)
      end

      context 'when there is a time limit on assignment' do
        before(:each) do
          assignment.assigned_assessment_detail = AssignedAssessmentDetail.new
          assignment.assigned_assessment_detail.time_limit = 10
        end

        context 'when start_time is not set' do
          it 'return the time limit on assignment' do
            allow(attempt).to receive(:start_time).and_return(nil)
            allow(attempt).to receive(:assignment).and_return(assignment)
            expect(attempt.time_left_in_seconds).to eql(assignment.assigned_assessment_detail.time_limit * 60)
          end
        end

        context 'when time lapsed is more than the assignment time limit' do
          it 'return zero' do
            Timecop.freeze(Time.now) do
              allow(attempt).to receive(:start_time).and_return(12.minutes.ago)
              allow(attempt).to receive(:assignment).and_return(assignment)
              expect(attempt.time_left_in_seconds).to eql(0)
            end
          end
        end

        context 'when time lapsed is less than the assignment time limit' do
          it 'return time left' do
            Timecop.freeze(Time.now) do
              allow(attempt).to receive(:start_time).and_return(6.minutes.ago)
              allow(attempt).to receive(:assignment).and_return(assignment)
              expect(attempt.time_left_in_seconds).to eql(240)
            end
          end
        end
      end
    end
  end

  describe '#assignment_max_attempts' do
    let(:course) { create_course_with_stubs }
    let(:section) { create(:section, course: course) }
    let(:activity) { create(:activity) }

    context 'when assignment is assigned' do
      it 'returns the assignment max attempts' do
        allow(activity).to receive(:max_attempts).and_return(4)
        category = create(:category, max_attempts: 5)
        assignment = create(:assignment, section: section, assignable: activity, category: category)
        attempt = create(:attempt, section: section, activity: activity)
        expect(attempt.assignment_max_attempts).to eql 5
      end
    end

    context 'when there is no assignment' do
      it 'returns the activity max attempts' do
        attempt = create(:attempt, activity: activity)
        allow(activity).to receive(:max_attempts).and_return(5)
        expect(attempt.assignment_max_attempts).to eql 5
      end
    end
  end

  describe '#last_possible?' do
    it 'should return true if attempt track has 1 remaining attempt' do
      activity = create(:activity)
      allow(activity).to receive(:max_attempts).and_return(1)
      attempt = build(:attempt, activity: activity)
      expect(attempt.last_possible?).to be_truthy
    end

    it 'should return false unless attempt track has 1 remaining attempt' do
      activity = create(:activity)
      allow(activity).to receive(:max_attempts).and_return(2)
      attempt = build(:attempt, activity: activity)
      expect(attempt.last_possible?).to be_falsey
    end
  end

  describe '#current_view' do
    let(:activity) { build_stubbed(:activity) }
    let(:attempt)  { Attempt.new }

    before(:each) do
      allow(attempt).to receive(:attempt_track).and_return(double(AttemptTrack, max: 2))
      allow(attempt).to receive(:activity).and_return(activity)
      allow(attempt).to receive(:santillana?).and_return(false)
    end

    it 'should return show if activity is started' do
      attempt.status_code = AttemptStatus::CODE_STARTED
      expect(attempt.current_view).to eql :show
    end

    it 'should return complete if activity is completed' do
      attempt.status_code = AttemptStatus::CODE_COMPLETED
      expect(attempt.current_view).to eql :complete
    end

    it 'should return submit if submitted and there are saved values' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      attempt.save_record_length = 100
      expect(attempt.current_view).to eql :submit
    end

    it 'should return decide if submitted and there are no saved values' do
      attempt.status_code = AttemptStatus::CODE_SUBMITTED
      expect(attempt.current_view).to eql :decide
    end

    it 'should return show if never opened' do
      expect(attempt.current_view).to eql :show
    end

    it 'should return show if activity is read_only' do
      allow(activity).to receive(:submittable?).and_return(false)
      expect(attempt.current_view).to eql :show
    end

    it 'returns show if the activity is a santillana activity' do
      allow(attempt).to receive(:santillana?).and_return(true)
      expect(attempt.current_view).to eq(:show)
    end
  end

  describe "#attempt_track" do
    let(:attempt_track) { double(AttemptTrack, :complete= => true, :practice= => true, :attempt_number= => 1) }
    let(:section) { create(:section) }
    let(:activity) { create(:activity) }
    let(:assignment) { create(:assignment, section: section, assignable: activity) }
    let(:max_attempt_policy) { double(MaxAttemptPolicy) }
    let!(:question_bank_topic) { create(:question_bank_topic) }
    let(:json) do
      File.read(
        File.join('spec', 'fixtures', 'json', 'open_ended_question_bank.json')
      )
    end

    let!(:question_bank) do
      create(
        :question_bank,
        content_json: json,
        question_bank_topic: question_bank_topic,
        upload_filename: 'fake_file.csv'
      )
    end

    before do
      allow(MaxAttemptPolicy).to receive(:new).and_return(max_attempt_policy)
    end

    context 'when attempt activity is a view-only activity that is not submittable' do
      it 'returns a new AttemptTrack instance initialized with max attempts set to zero' do
        allow(max_attempt_policy).to receive(:unsubmittable?).and_return(true)
        attempt = create(:attempt, activity: activity)
        expect(AttemptTrack).to receive(:new).with(0, 0).and_return(attempt_track)
        attempt.attempt_track
      end
    end

    context 'when attempt activity is a question bank' do
      it 'returns a new AttemptTrack instance initialized with max attempts set to zero' do
        allow(max_attempt_policy).to receive(:unsubmittable?).and_return(true)
        attempt = create(:attempt, activity: question_bank)
        expect(AttemptTrack).to receive(:new).with(0, 0).and_return(attempt_track)
        attempt.attempt_track
      end
    end

    context 'when activity is submittable' do
      it 'returns a new AttemptTrack instance initialized with max attempts defined by the max attempt policy' do
        max_attempts = 9
        allow(max_attempt_policy).to receive(:unsubmittable?).and_return(false)
        allow(max_attempt_policy).to receive(:max_attempts).and_return(max_attempts)

        attempt = create(:attempt, activity: activity)
        expect(AttemptTrack).to receive(:new).with(anything, max_attempts).and_return(attempt_track)
        attempt.attempt_track
      end
    end
  end

  describe '#create_completed' do
    before(:each) do
      @activity = create(:activity)
      @student = create(:student)
      @course = create(:course)
      @section = create(:section, course: @course)
      allow(GradebookEngine::GradebookAPI).to receive(:submit)
    end

    it 'creates a new record, set to complete status' do
      @attempt = Attempt.create_completed(@student, @activity, @section)
      expect(@attempt.user_id).to eql @student.id
      expect(@attempt.section_id).to eql @section.id
      expect(@attempt.activity_id).to eql @activity.id
      expect(@attempt.cms_activity_id).to eql @activity.cms_activity_id
      expect(@attempt.cms_revision_id).to eql @activity.cms_revision_id
      expect(@attempt.status_code).to eql 2
    end

    context 'when activity is gradable' do
      it 'should not set a score for the attempt submission' do
        allow(@activity).to receive(:gradable?).and_return(true)
        @attempt = Attempt.create_completed(@student, @activity, @section)
        conditions = {
          user_id: @student.id,
          section_id: @section.id,
          scorable_id: @activity.id,
          scorable_type: @activity.class.to_s
        }

        expect(GradebookEngine::GradebookAPI).not_to have_received(:submit)
      end
    end

    context 'when activity is non-gradable' do
      it 'should set a score for the attempt submission' do
        allow_any_instance_of(::Gradebook::Submission).to receive(:update_new_gradebook)
        allow(@activity).to receive(:gradable?).and_return(false)
        @attempt = Attempt.create_completed(@student, @activity, @section)
        conditions = {
          user_id: @student.id,
          section_id: @section.id,
          scorable_id: @activity.id,
          scorable_type: @activity.class.to_s
        }

        expect(GradebookEngine::GradebookAPI)
          .to have_received(:submit)
          .with(@student.id, @section.id, @activity.id, @section.school_id,
                hash_including(points_earned: 1,
                               attempt_count: 1))
      end
    end
  end

  describe '.find_or_create_with_scoring_ruleset' do
    let(:user)     { create(:student)  }
    let(:activity) { create(:activity) }
    let(:section)  { create(:section)  }
    let(:ruleset) { create(:scoring_ruleset) }

    context 'when an attempt already exists with the specified user, section id, and activity' do
      it 'does not create a new attempt' do
        create(:attempt, user: user, activity: activity, section: section)
        expect do
          Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id)
        end.to_not change(Attempt, :count)
      end

      it 'returns the existing attempt' do
        attempt = create(:attempt, user: user, activity: activity, section: section)
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id)
        expect(result).to eql attempt
      end

      it 'finds the existing attempt when a section id of zero is specified' do
        attempt = create(:attempt, user: user, activity: activity, section_id: 0)
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, 0)
        expect(result).to eql attempt
      end

      it 'does not change the scoring ruleset of the attempt if submitted' do
        scoring_ruleset = create(:scoring_ruleset)
        create(:attempt, user: user,
                          activity: activity,
                          section: section,
                          scoring_ruleset: scoring_ruleset,
                          status_code: AttemptStatus::CODE_SUBMITTED)
        expect(Attempt.find_or_create_with_scoring_ruleset(user,
                                                           activity,
                                                           section.id).scoring_ruleset).to eql scoring_ruleset
      end

      it 'changes the scoring ruleset of the attempt if not submitted' do
        scoring_ruleset = create(:scoring_ruleset)
        create(:attempt, user: user,
                          activity: activity,
                          section: section,
                          scoring_ruleset: scoring_ruleset,
                          status_code: AttemptStatus::CODE_OPENED)
        expect(Attempt.find_or_create_with_scoring_ruleset(user,
                                                           activity,
                                                           section.id).scoring_ruleset).not_to eql scoring_ruleset
      end
    end

    context 'when attempts exist that match some but not all of the specified parameters' do
      before do
        @other_user_attempt     = create(:attempt, user: create(:student), activity: activity, section: section)
        @other_activity_attempt = create(:attempt, user: user, activity: create(:activity), section: section)
        @other_section_attempt  = create(:attempt, user: user, activity: activity, section: create(:section))
      end

      it 'creates a new attempt' do
        expect do
          result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id)
        end.to change(Attempt, :count)
      end

      it 'does not return any of the existing attempts' do
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id)
        expect([@other_user_attempt, @other_activity_attempt, @other_section_attempt]).to_not include result
      end
    end

    context 'when no attempt exists with the specified user, section, and activity' do
      it 'returns a newly created attempt with the specified user, section, and activity' do
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id)
        expect(result.user).to eql user
        expect(result.activity).to eql activity
        expect(result.section).to eql section
      end

      it 'returns a newly created attempt with section_id 0 when section id of 0 is specified' do
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, 0)
        expect(result.user).to eql user
        expect(result.activity).to eql activity
        expect(result.section_id).to eql 0
      end

      it 'sets the cms_revision_id of the new attempt to the revision_id of the activity' do
        allow(activity).to receive(:revision_id).and_return(12_345)
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, 0)
        expect(result.cms_revision_id).to eql activity.revision_id
      end

      context 'when no scoring ruleset is specified' do
        it 'assigns the default scoring ruleset to the new attempt returned' do
          result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id, scoring_ruleset = nil)
          expect(result.scoring_ruleset).to eql ScoringRuleset.default
        end
      end

      context 'when a scoring ruleset is specified' do
        it 'assigns that scoring ruleset to the attempt returned' do
          result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id, ruleset)
          expect(result.scoring_ruleset).to eql ruleset
        end
      end
    end

    context 'when insertion fails because a duplicate record already exists' do
      it 'returns the existing duplicate record instead of raising an error' do
        existing_record = create(:attempt, user: user,
                                           activity: activity,
                                           section: section,
                                           scoring_ruleset: ruleset,
                                           status_code: AttemptStatus::CODE_COMPLETED)
        result = Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id, ruleset)
        expect(result).to eql existing_record
        expect(result.scoring_ruleset).to eql ruleset
      end
    end

    context 'when insertion fails for any reason besides a duplicate record' do
      it 'raises the exception' do
        allow(Attempt).to receive(:create!).and_raise(ActiveRecord::StatementInvalid.new('Mysql2::Error: Some other problem'))
        expect do
          Attempt.find_or_create_with_scoring_ruleset(user, activity, section.id, ruleset)
        end.to raise_error(ActiveRecord::StatementInvalid)
      end
    end
  end

  describe '.find_or_new' do
    let(:user) { create(:student) }
    let(:section) { create(:section) }
    let(:activity) { create(:activity) }
    let(:attempt) { create(:attempt) }

    it 'finds and returns an existing active attempt for the specified user, activity, and section id' do
      expect(Attempt).to receive(:active_attempt).with(user, section.id, activity).and_return(attempt)
      expect(Attempt.find_or_new(user, activity, section.id)).to eql attempt
    end

    it 'creates an attempt with open status when the attempt is for an instructor and a partner chat activity' do
      instructor = create(:instructor)
      pchat = create(:activity, activity_type: 'partner_chat')

      result = described_class.find_or_new(instructor, pchat, 0)

      expect(result.status_code).to eq AttemptStatus::CODE_OPENED
    end

    it 'creates an attempt with open status when the attempt is for an instructor and infogap patner chat activity' do
      instructor = create(:instructor)
      infogap_pchat = create(:activity, activity_type: 'infogap_partner_chat')

      result = described_class.find_or_new(instructor, infogap_pchat, 0)

      expect(result.status_code).to eq AttemptStatus::CODE_OPENED
    end

    context 'when no active attempt exists' do
      before do
        allow(Attempt).to receive(:active_attempt).and_return(nil)
      end

      it 'creates a new, opened attempt with the specified user, activity, and section' do
        result = Attempt.find_or_new(user, activity, section.id)
        expect(result.user).to eql user
        expect(result.activity).to eql activity
        expect(result.cms_activity_id).to eql activity.cms_activity_id
        expect(result.cms_revision_id).to eql activity.cms_revision_id
        expect(result.section).to eql section
        expect(result.scoring_ruleset).to_not be_nil
        expect(result.status_code).to eql AttemptStatus::CODE_OPENED
      end

      it 'does not save the newly created attempt' do
        expect do
          Attempt.find_or_new(user, activity, section.id)
        end.to_not change(Attempt, :count)
      end
    end
  end

  describe '#completed_activity_ids' do
    before(:each) do
      @user = create(:user)
      @section = create(:section)
      @activity = create(:activity)

      create(
        :attempt_completed,
        activity: @activity,
        cms_activity_id: @activity.cms_activity_id,
        cms_revision_id: @activity.cms_revision_id,
        section: @section,
        user: @user
      )
    end

    context 'when user is not in a section,' do
      it 'returns an empty array' do
        expect(
          described_class.completed_activity_ids(@user, nil, [@activity])
        ).to eq([])
      end
    end

    context 'when user is in a section,' do
      it 'returns an array of completed activity ids' do
        expect(
          described_class.completed_activity_ids(@user, @section, [@activity])
        ).to eq([@activity.id])
      end
    end
  end

  describe '#all_submitted_and_completed_activities' do
    before do
      @user = create(:user)
      @section = create(:section)
      @activity = create(:activity)

      create(
        :attempt_completed,
        activity: @activity,
        cms_activity_id: @activity.cms_activity_id,
        cms_revision_id: @activity.cms_revision_id,
        section: @section,
        user: @user
      )
    end

    context 'when user is not in a section,' do
      it 'returns an empty array' do
        expect(
          described_class.all_submitted_and_completed_activities(@user, nil)
        ).to eq([])
      end
    end

    context 'when user is in a section,' do
      it 'returns an array of all completed activity ids' do
        expect(
          described_class.all_submitted_and_completed_activities(@user, @section.id)
        ).to eq([@activity])
      end
    end
  end

  describe '#status_for_activities' do
    before do
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
      @activity = build_stubbed(:activity)
    end

    context 'when user is not in a section' do
      it 'returns a hash of statuses keyed by activity id' do
        create(
          :attempt_submitted,
          activity: @activity,
          cms_activity_id: @activity.cms_activity_id,
          cms_revision_id: @activity.cms_revision_id,
          section_id: 0,
          user: @user
        )

        expect(
          described_class.status_for_activities(@user, nil, [@activity])
        ).to eq(@activity.id => :incomplete)
        expect(
          described_class.status_for_activities(@user, 0, [@activity])
        ).to eq(@activity.id => :incomplete)
        expect(
          described_class.status_for_activities(@user, [nil], [@activity])
        ).to eq(@activity.id => :incomplete)
      end
    end

    context 'when user is in a section' do
      it 'returns a hash of statuses keyed by activity id' do
        create(
          :attempt_submitted,
          activity: @activity,
          cms_activity_id: @activity.cms_activity_id,
          cms_revision_id: @activity.cms_revision_id,
          section: @section,
          user: @user
        )
        expect(
          described_class.status_for_activities(@user, @section, [@activity])
        ).to eq(@activity.id => :incomplete)
      end
    end
  end

  describe '.attempts_for_activities' do
    let(:user) { build_stubbed(:user) }
    let(:activities) { [create(:activity)] }

    it 'returns attempts for the specified user, section, and activities' do
      section = build_stubbed(:section)
      attempt = build_stubbed(:attempt)
      expect(Attempt).to receive(:find_attempts_for_activities).with(user, section, activities).and_return([attempt])
      Attempt.attempts_for_activities(user, section, activities)
    end

    context 'when the section is section zero' do
      it 'returns an empty hash' do
        section = Section.section_zero
        expect(Attempt.attempts_for_activities(user, section, activities)).to eql({})
      end
    end
  end

  describe '#find_submitted_attempts_for_activities' do
    let(:student) { build_stubbed(:student) }
    let(:activities) { [build_stubbed(:activity)] }
    let(:section) { build_stubbed(:section) }

    it 'calls find_attempts_for_activities with additional status_code conditions' do
      expected_conditions = { status_code: [AttemptStatus::CODE_SUBMITTED, AttemptStatus::CODE_COMPLETED] }
      expect(Attempt).to receive(:find_attempts_for_activities).with(student, section, activities, expected_conditions)
      Attempt.find_submitted_attempts_for_activities(student, section, activities)
    end
  end

  describe '#find_attempts_for_activities' do
    let(:student) { build_stubbed(:student) }
    let(:activities) { [build_stubbed(:activity)] }
    let(:section) { build_stubbed(:section) }

    it 'returns all attempts for a student, section and activities' do
      expected_conditions = { user_id: student,
                              section_id: section,
                              activity_id: activities }
      expect(Attempt).to receive(:where).with(expected_conditions)
      Attempt.find_attempts_for_activities(student, section, activities)
    end

    it 'accepts query parameters' do
      expected_conditions = { user_id: student,
                              section_id: section,
                              activity_id: activities,
                              status_code: AttemptStatus::CODE_COMPLETED }
      expect(Attempt).to receive(:where).with(expected_conditions)
      Attempt.find_attempts_for_activities(student, section, activities, status_code: AttemptStatus::CODE_COMPLETED)
    end
  end

  describe '#mark_as_completed' do
    it 'updates the time spent value and sets status to completed' do
      attempt = create(:attempt, status_code: nil)
      attempt.mark_as_completed(1.minute.ago.to_i, Time.now)
      attempt.reload
      expect(attempt.status).to eq :completed
      expect(attempt.expanded_status).to eq :completed
      expect(attempt.time_spent).to eq 60
    end
  end

  describe '#write_results' do
    let(:attempt) { create(:attempt, user: @user,
                                 section: @section,
                                 activity: @activity,
                                 cms_activity_id: @activity.cms_activity_id,
                                 cms_revision_id: @activity.cms_revision_id)}
    let(:write_response) { double('response', :id => '101', :any? => true )}

    before do
      stub_request(:post, '.*\/submissions').to_return(status: 200, body: { id: 10_000 }.to_json, headers: {})
      @user = build_stubbed(:user)
      @section = build_stubbed(:section)
      @activity = build_stubbed(:activity)
      @content_object = double('ContentObject', result_labels: %w(label_01 label_02 label_03))
      allow(@activity).to receive(:content_object).and_return(@content_object)
      @results = [{ label: 'label_01', correctness: 'correct', response: 'right answer' },
                  { label: 'label_02', correctness: 'correct', response: 'right answer' },
                  { label: 'label_03', correctness: 'incorrect', response: 'wrong answer' }]
      allow(@results).to receive(:keys).and_return(%w(label_01 label_02 label_03))

      allow(@results).to receive :attachment_ids
      allow(CompositionAttachment).to receive(:remove_draft_flags_from)
      @filepath = File.join('datafiles', Rails.env, 'responses', "#{@section.id}/#{@user.id}.xml")
    end

    context 'sets correct status' do
      before do
        allow(attempt.results_datastore).to receive(:write)
      end

      it 'when write as submitted' do
        attempt.write_results(@results, true, :submitted, 0, 60)
        expect(attempt.status_code).to eq 2
      end

      it 'when write as unsubmitted' do
        attempt.write_results(@results, true, :unsubmitted, 0, 60)
        expect(attempt.status_code).to eq 0
      end
    end

    it "doesn't write results into xml files" do
      expect(SubmissionClient::Submission).to receive(:create).and_return(write_response)
      expect(ResultsXmlDatastore).not_to receive(:write)

      attempt.write_results(@results, true, :submitted, 0, 60)
      expect(File.exist?(@filepath)).to be_falsey
    end

    context 'when complete results' do
      it 'does not raise an error' do
        allow(attempt.results_datastore).to receive(:write)
        attempt.write_results(@results, true, :submitted, 0, 60)
      end

      it 'updates the attempt record with completion status' do
        allow(attempt.results_datastore).to receive(:submission_id).and_return(1_010_101)
        allow(attempt.results_datastore).to receive(:write)
        expect(attempt).to receive(:set_attempt).with(true, :submitted, 0, 60)
        attempt.write_results(@results, true, :submitted, 0, 60)
      end

      it 'adds time spent' do
        allow(attempt.results_datastore).to receive(:submission_id).and_return(1_010_101)
        allow(attempt.results_datastore).to receive(:write)
        attempt.write_results(@results, true, :submitted, 0, 60)
        expect(attempt.time_spent).to eql 60
        attempt.write_results(@results, true, :submitted, 0, 55)
        expect(attempt.time_spent).to eql 115
      end

      it 'removes draft flag from attachment record when it is present' do
        allow(attempt.results_datastore).to receive(:submission_id).and_return(1_010_101)
        allow(attempt.results_datastore).to receive(:write)

        attachment = build_stubbed :composition_attachment
        allow(@results).to receive(:attachment_ids).and_return([attachment.id])
        expect(CompositionAttachment).to receive(:remove_draft_flags_from).with([attachment.id])
        attempt.write_results(@results, true, :submitted, 0, 60)
      end

      context 'with a standards test' do
        let(:standards_results) do
          {
            'question_guid_1' => {
              label: 'question_01',
              points_earned: 2,
              points_possible: 4
            }
          }
        end

        before do
          allow(attempt.results_datastore).to receive(:submission_id).and_return(1_010_101)
          allow(attempt.results_datastore).to receive(:write)
          allow(attempt.activity).to receive(:standards_test?).and_return(true)
          allow(@results).to receive(:standards_results).and_return(standards_results)
          allow(StandardsResults).to receive(:create_or_update)
        end

        it 'stores standards results if auto-graded' do
          allow(attempt.activity).to receive(:auto_graded?).and_return(true)
          attempt.write_results(@results, true, :submitted, 0, 60)

          expect(StandardsResults).to have_received(:create_or_update).with(
            section_id: attempt.section_id,
            cms_activity_id: attempt.cms_activity_id,
            user_id: attempt.user_id,
            results_data: standards_results
          )
        end

        it 'does not store standards results if grading is instructor or mixed' do
          allow(attempt.activity).to receive(:auto_graded?).and_return(false)
          attempt.write_results(@results, true, :submitted, 0, 60)

          expect(StandardsResults).not_to have_received(:create_or_update)
        end
      end
    end

    context 'when incomplete results' do
      before do
        allow(@results).to receive(:keys).and_return(%w(label_01 label_02))
      end

      it 'raises an error' do
        expect { attempt.write_results(@results, true, :submitted, 0, 60) }
          .to raise_error(RuntimeError, 'Submitted params are not complete.')
      end
    end
  end

  describe "#results_datastore" do
    let(:attempt) { create(:attempt, status_code: AttemptStatus::CODE_SUBMITTED,
                                      submission_id: 456) }

    before do
      allow(SubmissionMigrator).to receive(:sync_api)
    end

    it "returns a results datastore object" do
      expect(SubmissionMigrator).to_not receive(:sync_api)
      expect(attempt.results_datastore.class).to eq ResultsApiDatastore
    end

    it "migrates xml results data to api results data when needed" do
      attempt.update(offset_bytes: 25, record_length: 100, submission_id: nil)
      expect(SubmissionMigrator).to receive(:sync_api).with(attempt).twice
      attempt.results_datastore

      attempt.update(offset_bytes: nil, record_length: nil, submission_id: nil,
                                save_offset_bytes: 25, save_record_length: 100, saved_submission_id: nil)
      attempt.results_datastore
    end
  end

  describe '.reset_attempt' do
    let(:user) { create(:student) }
    let(:section) { create(:section) }

    context 'when an internal activity is specified' do
      let(:lesson) { create(:lesson_with_toc_entries) }
      let(:activity) { create(:activity, lesson: lesson) }
      let(:attempt) do
        create(:attempt, user: user, section: section, activity: activity)
      end

      it 'looks up the active attempt for the specified user, section, and activity' do
        expect(described_class).to receive(:active_attempt)
          .with(user, section, activity)
          .and_return(attempt)
        described_class.reset_attempt(user, section, activity)
      end

      context 'when an attempt exists for the given params' do
        before do
          allow(described_class).to receive(:active_attempt)
            .with(user, section, activity)
            .and_return(attempt)
        end

        it 'resets an active attempt found for the specified user, section, and activity' do
          expect(attempt).to receive(:reset_attempt)
          described_class.reset_attempt(user, section, activity)
        end

        it 'resets the activity graded notifications' do
          ActivityGradedNotification.create!(activity: activity, user: user, section: section)
          ActivityGradedNotification.create!(activity: activity, user: create(:student), section: section)
          expect{ described_class.reset_attempt(user, section, activity) }
            .to change(ActivityGradedNotification, :count).by(-1)
        end

        it 'resets the feedback items' do
          attempt.feedback_items.create!(
            question_label: 'question_label', points_earned: 20, user: user, section: section
          )
          expect{ described_class.reset_attempt(user, section, activity) }
            .to change(attempt.feedback_items, :count).by(-1)
        end

        it 'changes any request_review related to the submission to a request_help' do
          review_request = create(:review_request, user: user, activity: activity, section: section)
          expect(review_request.request_type).to eql 'request_review'
          described_class.reset_attempt(user, section, activity)
          review_request.reload
          expect(review_request.request_type).to eql 'request_help'
        end
      end

      it 'raises an error when no active attempt is found' do
        allow(described_class).to receive(:active_attempt)
          .with(user, section, activity)
          .and_return(nil)
        expect do
          described_class.reset_attempt(user, section, activity)
        end.to raise_error(/Attempt not found/)
      end
    end

    context 'with a standards assessment' do
      let(:lesson) { create(:lesson_with_toc_entries) }
      let(:activity) { create(:activity, lesson: lesson) }
      let!(:attempt) do
        create(
          :attempt_completed,
          activity: activity,
          section: section,
          user: user
        )
      end
      let!(:standards_results) do
        create(
          :standards_results,
          cms_activity_id: activity.cms_activity_id,
          section_id: section.id,
          user_id: user.id
        )
      end

      before do
        allow(activity).to receive(:standards_test?).and_return(true)
      end

      it 'removes the standards results record' do
        expect { Attempt.reset_attempt(user, section, activity) }
          .to change(StandardsResults, :count).by(-1)
      end
    end
  end

  describe '#reset_attempt' do
    let(:user) { create(:student) }
    let(:section) { create(:section) }
    let(:activity) { create(:activity) }

    context 'when the attempt has saved data' do
      let(:original_save_offset) { 100 }
      let(:original_save_length) { 500 }
      let(:original_time_spent) { 300 }
      let(:attempt) do
        create(
          :attempt_submitted,
          activity: activity,
          user: user,
          section: section,
          time_spent: original_time_spent,
          :save_offset_bytes => original_save_offset,
          :save_record_length => original_save_length
        )
      end

      before do
        attempt.reset_attempt
        attempt.reload
      end

      it 'changes the attempt status to opened' do
        # we don't set a status of CODE_RESET when the request has saved data, otherwise
        # the user would never be able to access their saved responses again since reset
        # attempts aren't picked up when user goes back into the activity
        expect(attempt.status_code).to eql AttemptStatus::CODE_OPENED
        expect(attempt).to_not be_reset
      end

      it 'preserves the saved responses' do
        expect(attempt.save_offset_bytes).to eq(original_save_offset)
        expect(attempt.save_record_length).to eq(original_save_length)
      end

      it 'removes any responses that were submitted' do
        expect(attempt.offset_bytes).to be_nil
        expect(attempt.record_length).to be_nil
      end

      it 'resets the attempt number to zero' do
        expect(attempt.attempt_number).to eq(0)
      end

      it 'maintains the original time spent' do
        expect(attempt.time_spent).to eq(original_time_spent)
      end
    end

    context 'when the attempt does not have saved data' do
      let(:original_offset) { 100 }
      let(:original_length) { 500 }
      let(:original_time_spent) { 300 }
      let(:attempt) do
        create(:attempt_submitted, activity: activity, user: user, section: section,
                                    offset_bytes: original_offset, record_length: original_length,
                                    save_offset_bytes: nil, save_record_length: nil,
                                    time_spent: original_time_spent)
      end
      it 'sets the attempt status to reset' do
        attempt.reset_attempt
        attempt.reload
        expect(attempt).to be_reset
      end

      it 'removes any previously reset attempts the user already had for the specified activity and section' do
        create(:attempt_reset, activity: activity, user: user, section: section)
        attempt.reset_attempt
        all_reset_attempts = Attempt.was_reset
        expect(all_reset_attempts).to contain_exactly(attempt)
      end
    end

    context 'when the activity is a smartbook' do
      let(:activity) { create(:activity, activity_type: 'smart_book') }
      let(:state_deleter_mock) { instance_double(Xapi::StateDeleter, delete: true)}
      let(:attempt) { create(:attempt_submitted, activity: activity) }

      before do
        allow(Xapi::StateDeleter).to receive(:new).with(attempt).and_return(state_deleter_mock)
        allow(Xapi::Statement).to receive(:delete_statements_by_attempt)
      end

      it 'removes saved state for a smartbook activity' do
        attempt.reset_attempt
        expect(state_deleter_mock).to have_received(:delete)
      end

      it 'removes saved statements' do
        attempt.reset_attempt
        expect(Xapi::Statement).to have_received(:delete_statements_by_attempt).with(attempt)
      end
    end

    context 'when the activity is an AI virtual chat activity' do
      let(:activity) { create(:activity, activity_type: 'ai_virtual_chat') }
      let(:attempt) { create(:attempt_submitted, activity:) }

      it 'restarts the conversation session' do
        session = create(:ai_conversation_session, activity:, attempt:, user: attempt.user)
        initial_message = create(
          :ai_conversation_session_message,
          role: 'assistant',
          session:
        )
        message_1 = create(:ai_conversation_session_message, session:)
        message_2 = create(:ai_conversation_session_message, session:)

        attempt.reset_attempt

        expect(
          AI::ConversationSessionMessage.where(id: initial_message.id)
        ).to exist
        expect(
          AI::ConversationSessionMessage.where(
            id: [message_1.id, message_2.id]
          )
        ).not_to exist
      end
    end
  end

  describe '.active_attempt' do
    let(:user) { create(:student) }
    let(:section) { create(:section) }
    let(:activity) { create(:activity) }

    it 'finds an attempt for the specified user, section, and activity' do
      attempt = create(:attempt_submitted, activity: activity, user: user, section: section)
      expect(Attempt.active_attempt(user, section, activity)).to eql attempt
    end

    it 'finds a matching attempt when ids are specified instead of objects' do
      attempt = create(:attempt_submitted, activity: activity, user: user, section: section)
      expect(Attempt.active_attempt(user.id, section.id, activity.id)).to eql attempt
    end

    it 'does not return attempts if all specified params do not match' do
      create(:attempt_submitted, activity: create(:activity), user: user, section: section)
      create(:attempt_submitted, activity: activity, user: create(:student), section: section)
      create(:attempt_submitted, activity: activity, user: user, section: create(:section))

      expect(Attempt.active_attempt(user, section, activity)).to be_nil
    end

    it 'finds an open attempt for the specified user, section, and activity' do
      attempt = create(:attempt_opened, activity: activity, user: user, section: section)
      expect(Attempt.active_attempt(user, section, activity)).to eql attempt
    end

    it 'finds a completed attempt for the specified user, section, and activity' do
      attempt = create(:attempt_completed, activity: activity, user: user, section: section)
      expect(Attempt.active_attempt(user, section, activity)).to eql attempt
    end

    it 'does not find an attempt that has been reset' do
      create(:attempt_reset, activity: activity, user: user, section: section)
      expect(Attempt.active_attempt(user, section, activity)).to be_nil
    end

    context 'when the attempt that is found was for a different version of the activity' do
      let(:old_version) { (activity.cms_revision_id - 1) }

      context 'when the attempt has already been submitted' do
        it 'does not update the cms_revision_id of the attempt' do
          create(:attempt_submitted, activity: activity, user: user, section: section,
                                      cms_revision_id: old_version)
          expect(Attempt.active_attempt(user, section, activity).cms_revision_id).to eq old_version
        end
      end

      context 'when the attempt has been opened, but not submitted' do
        let(:open_attempt) do
          create(:attempt_opened, activity: activity, user: user, section: section,
                                   cms_revision_id: old_version)
        end

        it 'updates the cms_revision_id of the attempt to the current version of the activity' do
          open_attempt
          expect(Attempt.active_attempt(user, section, activity).cms_revision_id).to eq activity.cms_revision_id
        end

        context 'when responses have been saved' do
          it 'does not update the cms revision id' do
            allow(Attempt).to receive(:active).and_return([open_attempt])

            open_attempt.update(save_record_length: 1)
            expect(Attempt.active_attempt(user, section, activity).cms_revision_id).to eq old_version
          end
        end
      end
    end
  end

  describe '.find_by_student_section_and_activity' do
    before(:each) do
      @student  = create(:student)
      @section  = create(:section)
      @activity = create(:activity)
    end

    it 'should return the attempt completed by the specified student for the specified activity and section if one exists' do
      attempt = create(:attempt, activity: @activity,
                                  user: @student,
                                  section: @section,
                                  cms_activity_id: @activity.cms_activity_id,
                                  cms_revision_id: @activity.cms_revision_id,
                                  status_code: 1)
      expect(Attempt.find_by_student_section_and_activity(@student, @section, @activity)).to eql attempt
    end

    it 'should return nil if there are no attempts for the specified activity' do
      expect(Attempt.find_by_student_section_and_activity(@student, @section, @activity)).to be_nil
    end
  end

  describe '.activity_attempts' do
    before(:each) do
      @user = create(:user)
      @section = create(:section)
      @activity = create(:activity)
    end

    it 'should return an array of attempts for the specified activities' do
      attempt = create(:attempt, activity: @activity,
                                  user: @user,
                                  section: @section,
                                  cms_activity_id: @activity.cms_activity_id,
                                  cms_revision_id: @activity.cms_revision_id,
                                  status_code: 1)

      attempts = Attempt.activity_attempts(@section, @user, [@activity])
      expect(attempts).to match_array([attempt])
    end

    it 'should return an empty collection when there are no attempts for the activity' do
      attempts = Attempt.activity_attempts(@section, @user, [@activity])
      expect(attempts).to be_empty
    end

    it 'does not return any attempts that have been reset' do
      attempt = create(:attempt, user: @user,
                       section: @section,
                       activity: @activity,
                       status_code: AttemptStatus::CODE_RESET)
      expect(Attempt.activity_attempts(@section, @user, [@activity])).to be_empty
    end
  end

  describe '#effective_scoring_ruleset' do
    it 'retrieves the modified ruleset from the activity' do
      activity = build_stubbed(:activity)
      allow(activity).to receive(:content_object).and_return('valid_object')
      attempt = create(:attempt, activity: activity, scoring_ruleset: ScoringRuleset.new)
      expect(activity.content_object).to receive(:effective_ruleset).with(attempt.scoring_ruleset)
      attempt.effective_scoring_ruleset
    end
  end

  describe "#convert_response_to_partner_chat_recording" do
    context "when the activity is a partner_chat" do
      let(:activity) { build(:activity, activity_type: 'partner_chat',
                                                cms_revision_id: 100,
                                                cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                                        cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { %(<activity activity_type="partner_chat" language="fr" title="title">
                              <dl/>
                              <items>
                                <style/>
                                <item/>
                              </items>
                            </activity>)}

      before do
        activity.content = xml_content
        activity.save
      end

      it "sets the content object's finder class to PartnerChatRecording" do
        attempt.convert_response_to_partner_chat_recording
        expect(attempt.activity.content_object.finder_class).to eq PartnerChatRecording
      end

      context "when attempt cms_revision_id is different from activity" do
        it "sets the finder_class on the activity content_object for the attempt cms_revision_id" do
          attempt.cms_revision_id = activity.cms_revision_id =- 1
          activity.content = xml_content  # write prior version
          attempt.convert_response_to_partner_chat_recording
          expect(attempt.activity.content_object.finder_class)
            .to eq attempt.revision_activity.content_object.finder_class
        end
      end
    end

    context "when activity is not a partner chat" do
      let(:activity) { build(:activity, activity_type: 'open_ended',
                                                cms_revision_id: 200,
                                                cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                                        cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { File.read(File.join(Rails.root, 'spec/fixtures/xml', 'open_ended.xml')) }

      it "returns nil" do
        activity.content = xml_content
        activity.save

        expect(attempt.convert_response_to_partner_chat_recording.nil?).to be_truthy
      end
    end
  end

  describe "#convert_response_to_group_chat_recording" do
    context "when the activity is a group_chat" do
      let(:activity) { build(:activity, activity_type: 'group_chat',
                                                cms_revision_id: 101,
                                                cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                                        cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { %(<activity activity_type="group_chat" language="fr" title="title">
                              <dl/>
                              <items>
                                <style/>
                                <item/>
                              </items>
                            </activity>)}

      before do
        activity.content = xml_content
        activity.save
      end

      it "sets the content object's finder class to GroupChatRecording" do
        attempt.convert_response_to_group_chat_recording
        expect(attempt.activity.content_object.finder_class).to eq GroupChatRecording
      end

      context "when attempt cms_revision_id is different from activity" do
        it "sets the finder_class on the activity content_object for the attempt cms_revision_id" do
          attempt.cms_revision_id = activity.cms_revision_id =- 1
          activity.content = xml_content  # write prior version
          attempt.convert_response_to_group_chat_recording
          expect(attempt.activity.content_object.finder_class)
            .to eq attempt.revision_activity.content_object.finder_class
        end
      end
    end

    context "when activity is not a group chat" do
      let(:activity) { build(:activity, activity_type: 'open_ended',
                                                cms_revision_id: 201,
                                                cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                                        cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { File.read(File.join(Rails.root, 'spec/fixtures/xml', 'open_ended.xml')) }

      it "returns nil" do
        activity.content = xml_content
        activity.save

        expect(attempt.convert_response_to_group_chat_recording.nil?).to be_truthy
      end
    end
  end

  describe "#convert_response_to_solo_video_recording" do
    context "when the activity is a solo video recording" do
      let(:activity) { build(:activity, activity_type: 'solo_video_recording',
                             cms_revision_id: 100,
                             cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                             cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { %(<activity activity_type="solo_video_recording" language="fr" title="title">
                              <dl/>
                              <items>
                                <style/>
                                <item/>
                              </items>
                            </activity>)}

      before do
        activity.content = xml_content
        activity.save
      end

      it "sets the content object's finder class to SoloVideoRecording" do
        attempt.convert_response_to_solo_video_recording
        expect(attempt.activity.content_object.finder_class).to eq SoloVideoRecording
      end

      context "when attempt cms_revision_id is different from activity" do
        it "sets the finder_class on the activity content_object for the attempt cms_revision_id" do
          attempt.cms_revision_id = activity.cms_revision_id =- 1
          activity.content = xml_content  # write prior version
          attempt.convert_response_to_solo_video_recording
          expect(attempt.activity.content_object.finder_class)
            .to eq attempt.revision_activity.content_object.finder_class
        end
      end
    end

    context "when activity is not a solo_video_recording" do
      let(:activity) { build(:activity, activity_type: 'open_ended',
                             cms_revision_id: 200,
                             cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                             cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { File.read(File.join(Rails.root, 'spec/fixtures/xml', 'open_ended.xml')) }

      it "returns nil" do
        activity.content = xml_content
        activity.save

        expect(attempt.convert_response_to_solo_video_recording.nil?).to be_truthy
      end
    end

    context "when the activity contains a solo video recording" do
      let(:activity) { build(:activity, activity_type: 'multi_type',
                             cms_revision_id: 100,
                             cdn: false) }
      let(:attempt) { create(:attempt, activity: activity,
                             cms_revision_id: activity.cms_revision_id) }
      let(:xml_content) { File.read(File.join(Rails.root, 'spec/fixtures/xml', 'multi_type_activity_with_solo_video.xml')) }


      before do
        activity.content = xml_content
        activity.save
      end

      it "sets the content object's finder class to SoloVideoRecording" do
        attempt.convert_response_to_solo_video_recording
        expect(attempt.activity.content_object.solo_video_recording_subactivity.finder_class).to eq SoloVideoRecording
      end

      context "when attempt cms_revision_id is different from activity" do
        it "sets the finder_class on the activity content_object for the attempt cms_revision_id" do
          attempt.cms_revision_id = activity.cms_revision_id =- 1
          activity.content = xml_content  # write prior version
          attempt.convert_response_to_solo_video_recording
          expect(attempt.activity.content_object.solo_video_recording_subactivity.finder_class)
            .to eq attempt.revision_activity.content_object.solo_video_recording_subactivity.finder_class
        end
      end
    end
  end

  describe '#time_spent' do
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    let(:user) { create(:user) }

    it 'defaults to 0' do
      attempt = described_class.create!(
        activity: activity,
        cms_activity_id: activity.cms_activity_id,
        cms_revision_id: activity.cms_revision_id,
        scoring_ruleset: ScoringRuleset.default,
        section: section,
        user: user
      )
      expect(attempt.time_spent).to be_zero
    end

    it 'cannot be less than zero' do
      attempt = described_class.new(
        activity: activity,
        cms_activity_id: activity.cms_activity_id,
        cms_revision_id: activity.cms_revision_id,
        scoring_ruleset: ScoringRuleset.default,
        section: section,
        time_spent: -25,
        user: user
      )
      attempt.valid?
      expect(attempt.errors[:time_spent]).to eq(['must be greater than -1'])
    end

    it 'cannot be nil' do
      attempt = described_class.new(
        activity: activity,
        cms_activity_id: activity.cms_activity_id,
        cms_revision_id: activity.cms_revision_id,
        scoring_ruleset: ScoringRuleset.default,
        section: section,
        time_spent: nil,
        user: user
      )
      attempt.valid?
      expect(attempt.errors[:time_spent]).to eq(['must be a number'])
    end
  end

  describe '#points_earned_for_feedback_item' do
    let(:attempt) { build_stubbed(:attempt) }
    let(:feedback_item) { double(FeedbackItem, question_label: 'question_01', points_earned: 9.0) }

    before do
      allow(attempt).to receive(:feedback_items).and_return([feedback_item])
    end

    it 'returns points_earned for the feedback_item' do
      expect(attempt.points_earned_for_feedback_item('question_01')).to eql 9.0
    end

    it "returns nil when feedback item doesn't exist" do
      expect(attempt.points_earned_for_feedback_item('question_02')).to be_nil
    end
  end

  describe '#feedback_item' do
    let(:activity) { create(:activity) }
    let(:section) { create(:section) }
    let(:student) { create(:student) }
    let(:attempt) do
      create(:attempt, user: student, section: section, activity: activity)
    end

    it 'returns the feedback_item record for the specified question_label ' \
       'if one exists' do
      question_1 = instance_double(
        MaestroActivityEngine::ActivityContent::OpenEnded::Item,
        label: 'question_01'
      )

      feedback_item = FeedbackItem.create!(
        attempt: attempt,
        points_earned: 9.0,
        question_label: question_1.label,
        section: section,
        user: student
      )
      expect(attempt.feedback_item(question_1.label)).to eq(feedback_item)
    end

    it 'returns nil if no feedback_item record exists for the specified ' \
       'question label' do
      question_1 = instance_double(
        MaestroActivityEngine::ActivityContent::OpenEnded::Item,
        label: 'question_01'
      )
      expect(attempt.feedback_item(question_1.label)).to be_nil
    end
  end

  describe '#process_instructor_grading' do
    let(:student) { build_stubbed(:student) }
    let(:course) { create_course_with_stubs }
    let(:section) { create(:section, course: course) }
    let(:lesson) { create(:lesson_with_toc_entries) }
    let(:activity) { create(:activity, lesson: lesson) }
    let(:attempt) do
      create(:attempt, user: student, section: section, activity: activity)
    end
    let(:assignment) { double(Assignment, grade_availability: nil) }
    let(:question_1) { double('Question', label: 'question_01') }
    let(:question_2) { double('Question', label: 'question_02') }
    let(:question_1_points_assigned) { 9.0 }
    let(:score_action) { instance_double(GradebookEngine::ScoreAction) }
    let(:cartridge_consumer_guid) { SecureRandom.uuid }
    let(:cartridge_params) { { cartridge_consumer_guid: cartridge_consumer_guid } }

    before do
      allow(lesson).to receive(:strand_for_toc_location) {
        create(:toc_entry)
      }
      allow(attempt).to receive(:assignment).and_return(assignment)
      create(:gb_activity, id: activity.id)
      create(:gb_section, id: section.id)
      create(:gb_user, id: student.id)

      stub_const(
        'Results',
        Struct.new(:results, :standards_results) do
          def keys
            results.pluck(:label)
          end

          def points_earned(label)
            result = results.find { |res| res[:label] == label }
            result ? result[:points_earned] : nil
          end
        end
      )

      FeedbackItem.create!(
        attempt: attempt,
        points_earned: question_1_points_assigned,
        question_label: question_1.label,
        section: section,
        user: student
      )
    end

    context 'when feedback_item records with scores exist for all questions,' do
      let(:results) { [] }

      before do
        allow(activity).to receive(:instructor_graded_questions) { [question_1] }
        allow(activity).to receive(:questions) { [question_1] }
        allow(attempt).to receive(:all_questions_have_scores?) { true }
        allow(attempt).to receive(:results).and_return(results)
        allow(results).to receive(:auto_graded_points_earned).and_return(0)
        allow(attempt).to receive(:activity).and_return(activity)
        allow(activity).to receive(:activity_type).and_return('open_ended')
      end

      context 'when a score_action record exists,' do
        let(:assignment) do
          create(:assignment, section: section, assignable: activity)
        end
        let!(:score_action) do
          create(
            :gb_score_action,
            activity_id: activity.id,
            school_id: 123,
            section_id: section.id,
            summation: {
              pending: true,
              points_earned: 0.0,
              points_possible: 10,
              submitted_at: Time.zone.now,
              rubric_graded: false
            },
            user: student
          )
        end

        before do
          allow(assignment).to receive(:credit_only?).and_return(false)
          allow(Assignment).to receive(:find_with_course_category) { assignment }
          allow(attempt).to receive(:assignment) { assignment }
        end

        it 'creates a new score_action that is not pending and sets the points earned' do
          current_score_action = latest_score_action(
            activity_id: score_action.activity_id,
            section_id: score_action.section_id,
            user_id: score_action.user_id
          )
          expect(current_score_action).to be_pending
          expect(current_score_action.points_earned).to eql 0.0
          expect(current_score_action.summation['rubric_graded']).to be_falsey

          attempt.process_instructor_grading(cartridge_params: cartridge_params)

          new_current_score_action = latest_score_action(
            activity_id: score_action.activity_id,
            section_id: score_action.section_id,
            user_id: score_action.user_id
          )

          expect(new_current_score_action).to_not be_pending
          expect(new_current_score_action.points_earned)
            .to eql question_1_points_assigned
        end

        it 'creates a new activity graded notification if grades will be ' \
           'available at some point' do
          allow(assignment).to receive(:grade_availability) { :on_specific_date }

          expect do
            attempt.process_instructor_grading(cartridge_params: cartridge_params)
          end.to change(ActivityGradedNotification, :count).by(1)
        end

        it 'does not create a new activity graded notification if grades ' \
           'will not be available' do
          allow(assignment).to receive(:grade_availability).and_return(:never)

          expect do
            attempt.process_instructor_grading(cartridge_params: cartridge_params)
          end.to change(ActivityGradedNotification, :count).by(0)
        end

        it 'updates the rubric_graded flag if the activity was graded with a rubric' do
          attempt.process_instructor_grading(
            cartridge_params: cartridge_params,
            rubric_graded: true
          )

          new_current_score_action = latest_score_action(
            activity_id: score_action.activity_id,
            section_id: score_action.section_id,
            user_id: score_action.user_id
          )

          expect(new_current_score_action.summation['rubric_graded']).to be_truthy
        end

        context 'when the activity is not assigned' do
          it 'does not create a notification' do
            allow(attempt).to receive(:assignment).and_return(nil)

            expect do
              attempt.process_instructor_grading(cartridge_params: cartridge_params)
            end.to change(ActivityGradedNotification, :count).by(0)
          end
        end

        context 'when results is nil for a given attempt,' do
          before do
            allow(attempt).to receive(:results).and_return(nil)
          end

          it 'does not fail' do
            # previously this case caused a 500 error.
            # will try to fix the root cause where we have attempts with no
            # results included in a grading set but to prevent this causing
            # problems if any other users have data in this state, will try to
            # deal gracefully with nil results
            expect do
              attempt.process_instructor_grading(cartridge_params: cartridge_params)
            end.not_to raise_error
          end

          it 'updates points earned as if results had zero points earned' do
            attempt.process_instructor_grading(cartridge_params: cartridge_params)

            new_score_action = latest_score_action(activity_id: score_action.activity_id,
                                                   section_id: score_action.section_id,
                                                   user_id: score_action.user_id)

            expect(new_score_action.points_earned).to eql question_1_points_assigned
          end
        end

        context 'when there are results for a given attempt and they have ' \
                'some auto graded points,' do
          before do
            allow(activity).to receive(:questions)
              .and_return([question_1, question_2])
          end

          it 'includes the auto graded points earned into the student score' do
            auto_graded_points_earned = 1.0
            allow(results).to receive(:points_earned)
              .with('question_02')
              .and_return(auto_graded_points_earned)
            expect(score_action.points_earned).to eql 0.0

            attempt.process_instructor_grading(cartridge_params: cartridge_params)

            new_score_action = latest_score_action(activity_id: score_action.activity_id,
                                                   section_id: score_action.section_id,
                                                   user_id: score_action.user_id)

            expect(new_score_action.points_earned)
              .to eq(question_1_points_assigned + auto_graded_points_earned)
          end
        end
      end

      context 'when no score_action record exists,' do
        it 'looks for a score_action record, and returns without trying to update scores' do
          expect(GradebookEngine::GradebookAPI).to receive(:find_score).and_return(nil)
          expect(::Gradebook::InstructorGrading).not_to receive(:new)

          attempt.process_instructor_grading(cartridge_params: cartridge_params)
        end
      end
    end

    context 'when some questions do not have feedback_item records,' do
      before do
        allow(activity).to receive(:instructor_graded_questions)
          .and_return([question_1, question_2])
        allow(attempt).to receive(:all_questions_have_scores?).and_return(false)
      end

      it 'returns before trying to find and update a score record' do
        expect(GradebookEngine::GradebookAPI).not_to receive(:find_score)
        expect(::Gradebook::InstructorGrading).not_to receive(:new)

        attempt.process_instructor_grading(cartridge_params: cartridge_params)
      end
    end

    context 'when some questions have feedback_item records that do not have points,' do
      before do
        allow(activity).to receive(:instructor_graded_questions)
          .and_return([question_1, question_2])
        allow(activity).to receive(:activity_type).and_return('open_ended')

        FeedbackItem.create!(
          attempt: attempt,
          points_earned: nil,
          question_label: question_2.label,
          section: section,
          user: student
        )
      end

      it 'returns before trying to find and update a score record' do
        expect(GradebookEngine::GradebookAPI).not_to receive(:find_score)
        expect(::Gradebook::InstructorGrading).not_to receive(:new)

        attempt.process_instructor_grading(cartridge_params: cartridge_params)
      end
    end

    context 'when the activity includes items aligned with standards' do
      let(:activity) { build_stubbed(:activity, activity_type: 'exam') }
      let!(:score_action) do
        create(
          :gb_score_action,
          activity_id: activity.id,
          school_id: 123,
          section_id: section.id,
          user: student
        )
      end

      let(:standards_results) do
        {
          'question-guid-1' => {
            label: 'question_01',
            points_earned: 2.0,
            points_possible: 4
          },
          'question-guid-2' => {
            label: 'question_02',
            points_earned: 5.0,
            points_possible: 5
          }
        }.with_indifferent_access
      end

      let(:results) do
        Results.new(
          [
            {
              label: 'question_01',
              correctness: 'graded',
              question_guid: 'question-guid-1',
              points_possible: 4,
              points_earned: 2.0,
              response: 'student response'
            },
            {
              label: 'question_02',
              correctness: 'graded',
              question_guid: 'question-guid-2',
              points_possible: 5,
              points_earned: 5.0,
              response: 'student response'
            }
          ],
          standards_results
        )
      end

      before do
        allow(activity).to receive(:questions).and_return(
          [
            double('Question', label: 'question_01', question_guid: 'question-guid-1'),
            double('Question',  label: 'question_02', question_guid: 'question-guid-2'),
          ]
        )
        allow(attempt).to receive(:all_questions_have_scores?).and_return(true)
        allow(attempt).to receive(:update_grading_notification_for_activity)
        allow(attempt).to receive(:results).and_return(results)
      end

      it 'creates or updates a StandardsResults record' do
        expect {
          attempt.process_instructor_grading(cartridge_params: cartridge_params)
        }.to change(StandardsResults, :count).by(1)
        expect(StandardsResults.last.results_data).to eq(
          results.standards_results
        )
      end
    end
  end

  describe '.all_questions_have_scores?' do
    let(:feedback_items) do
      [build_stubbed(:feedback_item, question_label: 'question_01',
                                    points_earned: 10),
       build_stubbed(:feedback_item, question_label: 'question_02',
                                    points_earned: 9),
       build_stubbed(:feedback_item, question_label: 'question_03',
                                    points_earned: nil)]
    end
    let(:instructor_graded_questions) do
      [double('Question', label: 'question_01'),
       double('Question', label: 'question_02'),
       double('Question', label: 'question_03')]
    end
    let(:attempt) { build_stubbed(:attempt_completed) }
    let(:activity) { build_stubbed(:activity) }

    before do
      allow(activity).to receive(:instructor_graded_questions)
        .and_return(instructor_graded_questions)
      allow(attempt).to receive(:activity).and_return(activity)
      allow(activity).to receive(:activity_type).and_return('open_ended')
      allow(activity).to receive(:content_object).and_return(Struct.new(:has_rubric?).new(false))
    end

    it 'returns false when there is at least one question that has not been graded' do
      allow(attempt).to receive(:feedback_items).and_return(feedback_items)
      expect(attempt.all_questions_have_scores?).to be_falsey
    end

    context 'when all instructor graded questions are graded' do
      before do
        # grade the last question
        feedback_items[2].points_earned = 8.5
      end

      it 'returns true' do
        allow(attempt).to receive(:feedback_items).and_return(feedback_items)
        expect(attempt.all_questions_have_scores?).to be_truthy
      end

      it 'returns true when there are mixed auto and instructor graded feedback scores' do
        # add a 4th question representing an autograded item since
        # the label does not exist in instructor_graded_questions
        feedback_items.push build_stubbed(:feedback_item, question_label: 'question_04',
                                                         points_earned: 2)
        allow(attempt).to receive(:feedback_items).and_return(feedback_items)
        expect(attempt.all_questions_have_scores?).to be_truthy
      end

      it 'ignores feedback_items without a question_label' do
        feedback_items.push build_stubbed(:feedback_item, question_label: nil,
                                                         points_earned: nil,
                                                         comment: 'Activity level comment')
        allow(attempt).to receive(:feedback_items).and_return(feedback_items)
        expect(attempt.all_questions_have_scores?).to be_truthy
      end
    end
  end

  describe '#add_time_spent' do
    before(:each) do
      @user = build_stubbed(:student)
      @section = build_stubbed(:section)
      @activity = build_stubbed(:activity)
      @attempt = create(:attempt, user: @user,
                                   section: @section,
                                   activity: @activity,
                                   time_spent: 124)
    end

    it 'should add seconds to time_spent' do
      @attempt.add_time_spent(0, 60)
      attempt = Attempt.first
      expect(attempt.time_spent).to eql 184
    end
  end

  describe '#submission_length' do
    let(:user) { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }
    let(:activity) { build_stubbed(:activity) }

    let(:attempt) do
      create(
        :attempt,
        activity: activity,
        section: section,
        time_spent: 124,
        user: user
      )
    end

    let(:results) do
      [
        { label: 'label_01', correctness: 'correct',
          response: 'First open ended answer' },
        { label: 'label_02', correctness: 'correct',
          response: 'Second open ended answer' },
        { label: 'label_03', correctness: 'incorrect',
          response: 'Another oe answer' }
      ]
    end

    before do
      allow(attempt).to receive(:results).and_return(results)
      allow(results).to receive(:instructor_graded_score_pending?)
        .and_return(true)
    end

    it 'returns the total number of characters in all submitted answers' do
      expect(attempt.submission_length).to eq(64)
    end

    it 'returns nil for activities without instructor graded content' do
      allow(results).to receive(:instructor_graded_score_pending?)
        .and_return(false)
      expect(attempt.submission_length).to be_nil
    end

    it 'counts entitized characters as one character and ignores html tags' do
      results.first[:response] = 'First open &eacute;nded answer'
      results.last[:response] = 'Another <b>oe</b> answer'
      expect(attempt.submission_length).to eq(64)
    end

    it 'does not count leading and trailing white space' do
      results[0][:response] = '  First open &eacute;nded answer  '
      results[1][:response] = ' Second open ended answer'
      results[2][:response] = 'Another <b>oe</b> answer '
      expect(attempt.submission_length).to eq(64)
    end

    it 'does not count attachments' do
      attachment_result = {
        correctness: 'correct',
        is_attachment: true,
        label: 'label_01',
        response: '1234'
      }
      results.replace([attachment_result])
      expect(attempt.submission_length).to eq(0)
    end

    it 'does not count PartnerChatRecordings' do
      partner_recording_result = {
        correctness: 'correct',
        label: 'label_01',
        response: build(:partner_chat_recording)
      }
      results.replace([partner_recording_result])
      expect(attempt.submission_length).to eq(0)
    end

    it 'converts non-string responses to strings' do
      non_string_response_result = {
        correctness: 'correct',
        is_attachment: false,
        label: 'label_01',
        response: 1234
      }
      results.replace([non_string_response_result])
      expect(attempt.submission_length).to eq(4)
    end
  end

  describe '#find_submitted_attempts_for_activity_and_students' do
    let(:user) { build_stubbed(:user) }
    let(:section) { build_stubbed(:section) }
    let(:activity_type) { 'open_ended' }
    let(:activity) { create(:activity) }
    let(:result_labels) do
      [question_label('01', 'open_ended'),
       question_label('02', 'open_ended')
      ]
    end

    before do
      allow(activity).to receive(:smart_book?).and_return(false)
    end

    it 'should return a hash of attempts indexed by student_id' do
      attempt = create(:attempt, activity: activity,
                                  user: user,
                                  section: section,
                                  status_code: 1)

      attempts = Attempt.find_submitted_attempts_for_activity_and_students(
        [section], [user], activity
      )
      expect(attempts.is_a?(Hash)).to be_truthy
      expect(attempts[user.id.to_s]).to eql attempt
    end

    it 'should return an empty hash if no attempts are found' do
      attempts = Attempt.find_submitted_attempts_for_activity_and_students(
        [section], [user], build_stubbed(:activity)
      )
      expect(attempts.is_a?(Hash)).to be_truthy
      expect(attempts).to be_empty
    end

    context 'when cache_results is true' do
      let(:user_2)  { build_stubbed(:user) }
      let(:cacher) { instance_double(ResultsApiDatastore::MultipleAttempts, cacheable?: true) }
      let(:attempts) do
        [create(:attempt, activity: activity,
                           user: user_2,
                           section: section,
                           submission_id: 10_101,
                           status_code: 1),
         create(:attempt, activity: activity,
                           user: user,
                           section: section,
                           submission_id: 20_101,
                           status_code: 1)]
      end
      let(:response_1) { double(:submission, attempt_id: attempts[0].id, data: 'Data 1', keys: []) }
      let(:response_2) { double(:submission, attempt_id: attempts[1].id, data: 'Data 2', keys: []) }
      let(:object) { double('ContentObject', result_labels: result_labels) }
      let(:new_attempts) do
        Attempt.find_submitted_attempts_for_activity_and_students(
          [section], [user, user_2], activity, true
        )
      end

      before do
        # Why stubbing the activity object does not work?
        allow_any_instance_of(Activity).to receive(:activity_content)
          .and_return(double(ActivityContent, content_object: object))

        allow(cacher).to receive(:stored_response).with(attempts[0]).and_return(response_1)
        allow(cacher).to receive(:stored_response).with(attempts[1]).and_return(response_2)

        allow(ResultsApiDatastore::MultipleAttempts).to receive(:new).and_return(cacher)
      end

      it 'caches results for all the attempts' do
        expect(new_attempts[user_2.id.to_s].stored_responses.data).to eql(response_1.data)
      end

      context 'when it is an attempt for a smartbook activity' do
        let(:activity) { create(:activity, activity_type: 'smart_book') }
        let(:data_storable) do
          instance_double(ResultsApiDatastore, stored_responses: stored_responses)
        end
        let(:stored_responses) do
          { 'statements' => ['statement_1_attrs', 'statement_2_attrs'] }
        end
        let(:statement_1) { instance_double(Xapi::Statement) }
        let(:statement_2) { instance_double(Xapi::Statement) }
        let(:smartbook_responses) do
          instance_double(Smartbook::Responses, answered: answered_responses)
        end
        let(:answered_responses) { 'answered responses' }

        before do
          allow(DataStorable).to receive(:build).and_return(data_storable)
          allow(Xapi::Statement).to receive(:new).with('statement_1_attrs')
            .and_return(statement_1)
          allow(Xapi::Statement).to receive(:new).with('statement_2_attrs')
            .and_return(statement_2)
          allow(Smartbook::Responses).to receive(:new)
            .with([statement_1, statement_2]).and_return(smartbook_responses)
        end

        it 'caches answered interactions results for all the attempts' do
          expect(new_attempts[user_2.id.to_s].stored_responses).to eql(answered_responses)
        end
      end
    end
  end

  describe '#<' do
    before(:each) do
      @user_1 = build_stubbed(:user)
      @user_2 = build_stubbed(:user)
      @section = build_stubbed(:section)
      @activity = build_stubbed(:activity)
    end

    it 'should compare updated_at and return false if its more recent' do
      attempt_1 = create(:attempt, activity: @activity, user: @user_1, section: @section, updated_at: 2.day.ago)
      attempt_2 = create(:attempt, activity: @activity, user: @user_2, section: @section, updated_at: 4.day.ago)
      expect((attempt_1 < attempt_2)).to be_falsey
    end

    it 'should compare updated_at and return true if its older' do
      attempt_1 = create(:attempt, activity: @activity, user: @user_1, section: @section, updated_at: 4.day.ago)
      attempt_2 = create(:attempt, activity: @activity, user: @user_2, section: @section, updated_at: 2.day.ago)
      expect((attempt_1 < attempt_2)).to be_truthy
    end
  end

  describe '#current_total_points' do
    let(:user) { build_stubbed(:student) }
    let(:section) { build_stubbed(:section) }
    let(:activity) { build_stubbed(:activity) }
    let(:attempt) do
      create(:attempt, user: user, section: section, activity: activity)
    end

    context 'when the activity is not a smartbook' do
      let(:revision_activity) { build_stubbed(:activity) }
      let(:score) { create(:score, user: user) }
      let(:results) { double('Results') }
      let(:question_1) { double('question', label: 'question_01') }
      let(:question_2) { double('question', label: 'question_02') }
      let(:question_3) { double('question', label: 'question_03') }
      let(:feedback_item_1) { double('FeedbackItem', points_earned: 11) }

      before do
        allow(attempt).to receive(:revision_activity).and_return(revision_activity)
        allow(revision_activity). to receive(:questions).and_return(questions)
        allow(attempt).to receive(:results).and_return(results)
        allow(attempt).to receive(:feedback_item).with('question_01').and_return(feedback_item_1)
      end

      context 'when a feedback item exists,' do
        let(:questions) { [question_1] }

        before do
          allow(results).to receive(:points_earned).with('question_01').and_return(3.0)
        end

        it 'uses points earned from feed back item' do
          expect(attempt.current_total_points).to eq 11.0
        end
      end

      context 'when feedback item does not exist,' do
        let(:questions) { [question_1, question_2] }

        before do
          allow(results).to receive(:points_earned).with('question_01').and_return(3)
          allow(results).to receive(:points_earned).with('question_02').and_return(5)
          allow(attempt).to receive(:feedback_item).with('question_02').and_return(nil)
        end

        it 'uses points earned from results' do
          expect(attempt.current_total_points).to eq 16.0
        end
      end

      context 'when points earned in feedback item is nil' do
        let(:questions) { [question_1, question_2, question_3] }
        let(:feedback_item_2) { double('FeedbackItem', points_earned: nil) }

        before do
          allow(results).to receive(:points_earned).with('question_01').and_return(3)
          allow(results).to receive(:points_earned).with('question_02').and_return(5)
          allow(results).to receive(:points_earned).with('question_03').and_return(7)
          allow(attempt).to receive(:feedback_item).with('question_02').and_return(feedback_item_2)
          allow(attempt).to receive(:feedback_item).with('question_03').and_return(nil)
        end

        it 'uses points earned from results' do
          expect(attempt.current_total_points).to eq 23.0
        end
      end

      context 'when there are no results' do
        let(:questions) { [question_1] }
        let(:results) { }
        let(:feedback_item_1) { }

        it 'does not raise error' do
          expect(attempt.current_total_points).to eq 0.0
        end
      end
    end

    context 'when the activity is a table_activity with inline_open_ended' do
      let(:revision_activity) { build_stubbed(:activity, activity_type: 'table_activity') }
      let(:score) { create(:score, user: user) }
      let(:results) { double('Results') }
      let(:question_1) do
        double(
          'question',
          label: 'question_01',
          type: 'inline_open_ended',
          wols: [wol_1, wol_2]
        )
      end

      let(:wol_1) { double('wol', label: 'question_01_wol_1') }
      let(:wol_2) { double('wol', label: 'question_01_wol_2') }
      let(:feedback_item_1) { double('FeedbackItem', points_earned: 1.2) }
      let(:feedback_item_2) { double('FeedbackItem', points_earned: 1.8) }

      before do
        allow(attempt).to receive(:revision_activity).and_return(revision_activity)
        allow(revision_activity). to receive(:questions).and_return([question_1])
        allow(attempt).to receive(:results).and_return(results)
        allow(attempt).to receive(:feedback_item).with('question_01_wol_1')
          .and_return(feedback_item_1)
        allow(attempt).to receive(:feedback_item).with('question_01_wol_2')
          .and_return(feedback_item_2)
      end

      context 'when a feedback item exists,' do
        before do
          allow(results).to receive(:points_earned).with('question_01_wol_1')
            .and_return(2.0)
        end

        it 'uses points earned from feed back item' do
          expect(attempt.current_total_points).to eq(3.0)
        end
      end

      context 'when feedback item does not exist,' do
        before do
          allow(results).to receive(:points_earned).with('question_01_wol_1').and_return(1.4)
          allow(results).to receive(:points_earned).with('question_01_wol_2').and_return(1.5)
          allow(attempt).to receive(:feedback_item).with('question_01_wol_1').and_return(nil)
          allow(attempt).to receive(:feedback_item).with('question_01_wol_2').and_return(nil)
        end

        it 'uses points earned from results' do
          expect(attempt.current_total_points).to eq(2.9)
        end
      end

      context 'when points earned in feedback item is nil' do
        let(:feedback_item_1) { double('FeedbackItem', points_earned: nil) }

        before do
          allow(results).to receive(:points_earned).with('question_01_wol_1').and_return(2)
          allow(results).to receive(:points_earned).with('question_01_wol_2').and_return(1)
          allow(attempt).to receive(:feedback_item).with('question_01_wol_1')
            .and_return(feedback_item_1)
          allow(attempt).to receive(:feedback_item).with('question_01_wol_2').and_return(nil)
        end

        it 'uses points earned from results' do
          expect(attempt.current_total_points).to eq(3.0)
        end
      end

      context 'when there are no results' do
        let(:results) { }
        let(:feedback_item_1) { }
        let(:feedback_item_2) { }

        it 'does not raise error' do
          expect(attempt.current_total_points).to eq(0.0)
        end
      end
    end

    context 'when the activity is a smartbook,' do
      let(:points_earned) { 42.33 }
      let(:smartbook_score_calculator) do
        instance_double(Smartbook::ScoreCalculator, points_earned: points_earned)
      end

      before do
        allow(activity).to receive(:smart_book?).and_return(true)
        allow(Smartbook::ScoreCalculator).to receive(:new)
          .and_return(smartbook_score_calculator)
      end

      it 'returns the points earned calculated by the smartbook score calculator' do
        expect(attempt.current_total_points).to eq(points_earned)
      end
    end
  end

  describe '#newer_submission' do
    let(:activity) { build_stubbed(:activity) }
    let(:user) { build_stubbed(:user) }
    let(:section) { build_stubbed(:section) }

    it 'return self other ather is nil' do
      attempt = create(:attempt)
      expect(attempt.newer_submission(nil)).to eql attempt
    end

    it 'should raise error when user ids dont match' do
      attempt_1 = create(:attempt)
      attempt_2 = create(:attempt)
      expect do
        attempt_1.newer_submission(attempt_2)
      end.to raise_error(/uncomparable attempt records/)
    end

    it 'should raise error when cms_activity_ids dont match' do
      user = build_stubbed(:user)
      attempt_1 = create(:attempt, user: user)
      attempt_2 = create(:attempt, user: user)
      expect do
        attempt_1.newer_submission(attempt_2)
      end.to raise_error(/uncomparable attempt records/)
    end

    it 'should raise error when section dont match' do
      attempt_1 = create(:attempt_submitted, user: user, activity: activity, section: create(:section))
      attempt_2 = create(:attempt_completed, user: user, activity: activity, section: create(:section))
      expect do
        attempt_1.newer_submission(attempt_2)
      end.to raise_error(/uncomparable attempt records/)
    end

    context 'when one attempt is completed and other is not' do
      it 'returns the completed attempt' do
        completed_attempt = create(:attempt_completed,
                                    user: user,
                                    activity: activity,
                                    section: section,
                                    cms_activity_id: activity.cms_activity_id,
                                    cms_revision_id: activity.cms_revision_id)
        submitted_attempt = create(:attempt_submitted,
                                    user: user,
                                    activity: activity,
                                    section: section,
                                    cms_activity_id: activity.cms_activity_id,
                                    cms_revision_id: activity.cms_revision_id)
        expect(completed_attempt.newer_submission(submitted_attempt)).to eql completed_attempt
        expect(submitted_attempt.newer_submission(completed_attempt)).to eql completed_attempt
      end
    end

    context 'when one attempt is submitted and other is not' do
      it 'returns the submitted attempt' do
        opened_attempt = create(:attempt_opened,
                                 user: user,
                                 activity: activity,
                                 section: section,
                                 cms_activity_id: activity.cms_activity_id,
                                 cms_revision_id: activity.cms_revision_id)
        submitted_attempt = create(:attempt_submitted,
                                    user: user,
                                    activity: activity,
                                    section: section,
                                    cms_activity_id: activity.cms_activity_id,
                                    cms_revision_id: activity.cms_revision_id)
        expect(opened_attempt.newer_submission(submitted_attempt)).to eql submitted_attempt
        expect(submitted_attempt.newer_submission(opened_attempt)).to eql submitted_attempt
      end
    end
  end

  describe '#newest_submitted_attempts' do
    it 'should call class method submitted_attempts' do
      section = build_stubbed(:section)
      activity = build_stubbed(:activity)
      allow(Attempt).to receive(:submitted_attempts).and_return({})
      expect(Attempt).to receive(:submitted_attempts).and_return([])
      Attempt.newest_submitted_attempts(section, [activity])
    end

    it 'should return uniq records for each user id activity id combo ' do
      user = build_stubbed(:user)
      section = build_stubbed(:section)
      activity = build_stubbed(:activity)
      @attempt_1 = create(:attempt,
                           user: user,
                           activity: activity,
                           section: section,
                           status_code: AttemptStatus::CODE_COMPLETED)
      @attempt_2 = create(:attempt,
                           user: user,
                           activity: activity,
                           section: section,
                           status_code: AttemptStatus::CODE_SUBMITTED)

      allow(Attempt).to receive(:submitted_attempts).and_return([@attempt_1, @attempt_2])
      expect(Attempt.newest_submitted_attempts(section, [activity])).to eql [@attempt_1]
    end
  end

  describe "#stored_responses" do
    let(:activity) { create(:activity, activity_type: 'foo') }
    let(:user) { create(:user) }
    let(:section) { create(:section) }
    let(:attempt) do
      create(
        :attempt,
        activity: activity,
        scoring_ruleset: create(:scoring_ruleset),
        section: section,
        user: user
      )
    end

    let(:result_labels) do
      [
        question_label('01', 'open_ended'),
        question_label('02', 'open_ended'),
        question_label('03', 'open_ended')
      ]
    end

    before do
      allow(activity).to receive(:result_labels).and_return(result_labels)
      allow(STATS_PROXY).to receive(:relay)
    end

    context 'when all keys are present,' do
      let(:responses) do
        { 'question_01' => 'foo', 'question_02' => 'bar', 'question_03' => 'baz' }
      end
      let(:datastore) do
        instance_double(ResultsApiDatastore, stored_responses: responses)
      end

      it 'retrieves the stored(submitted) responses' do
        allow(attempt).to receive(:results_datastore).and_return(datastore)

        attempt.stored_responses

        expect(STATS_PROXY).to have_received(:relay).with(
          'type' => 'logstash_object',
          activity_id: activity.id,
          activity_type: activity.activity_type,
          all_keys_missing: false,
          application: :m3,
          attempt_number: 0,
          data_source: :stored_responses,
          environment: Rails.env,
          form_id: '',
          missing_keys_detail: {},
          mode: :review,
          navigator_user_agent: nil,
          percent_keys_missing: 0.0,
          section_id: section.id,
          status: 0,
          user_id: user.id,
          vhl_component: 'missing_submission_keys'
        )
        expect(datastore).to have_received(:stored_responses)
      end
    end

    context 'when there is a missing key,' do
      let(:responses_missing_key) do
        { 'question_01' => 'foo', 'question_03' => 'bar' }
      end
      let(:datastore) do
        instance_double(ResultsApiDatastore, stored_responses: responses_missing_key)
      end

      it 'notifies stats server what key is missing' do
        allow(attempt).to receive(:results_datastore).and_return(datastore)

        attempt.stored_responses

        expect(STATS_PROXY).to have_received(:relay).with(
          'type' => 'logstash_object',
          activity_id: activity.id,
          activity_type: activity.activity_type,
          all_keys_missing: false,
          application: :m3,
          attempt_number: 0,
          data_source: :stored_responses,
          environment: Rails.env,
          form_id: '',
          missing_keys_detail: { 'open_ended' => ['question_02'] },
          mode: :review,
          navigator_user_agent: nil,
          percent_keys_missing: 33.3,
          section_id: section.id,
          status: 0,
          user_id: user.id,
          vhl_component: 'missing_submission_keys'
        )
      end
    end

    context 'when all keys are missing,' do
      let(:datastore) do
        instance_double(ResultsApiDatastore, stored_responses: {})
      end

      it 'notifies stats server that all keys are missing' do
        expected_missing_keys = {
          'open_ended' => %w[question_01 question_02 question_03]
        }
        allow(attempt).to receive(:results_datastore).and_return(datastore)

        attempt.stored_responses

        expect(STATS_PROXY).to have_received(:relay).with(
          'type' => 'logstash_object',
          activity_id: activity.id,
          activity_type: activity.activity_type,
          all_keys_missing: true,
          application: :m3,
          attempt_number: 0,
          data_source: :stored_responses,
          environment: Rails.env,
          form_id: '',
          missing_keys_detail: expected_missing_keys,
          mode: :review,
          navigator_user_agent: nil,
          percent_keys_missing: 100.0,
          section_id: section.id,
          status: 0,
          user_id: user.id,
          vhl_component: 'missing_submission_keys'
        )
      end
    end
  end

  describe '#validate_responses' do
    let(:user) { create(:user) }
    let(:section) { create(:section) }
    let(:activity_content) do
      File.read(File.join(Rails.root, 'spec', 'fixtures', 'xml', 'open_ended.xml'))
    end
    let(:activity) { create(:activity, content: activity_content) }
    let(:attempt) do
      create(
        :attempt,
        activity: activity,
        cms_revision_id: activity.cms_revision_id,
        scoring_ruleset: create(:scoring_ruleset),
        section: section,
        user: user
      )
    end
    let(:request) { { 'HTTP_USER_AGENT' => 'valid user agent string' } }

    before do
      allow(STATS_PROXY).to receive(:relay)
    end

    context 'when some keys are missing,' do
      context 'when missing answers are not permitted' do
        before do
          allow(activity).to receive(:allow_missing_answers?).and_return(false)
        end

        it 'notifies stats server what keys are missing' do
          attempt.validate_responses(
            activity,
            HashWithIndifferentAccess.new(
              question_01: 'foo',
              question_03: 'bar',
              question_04: 'buz'
            ),
            request
          )

          expect(STATS_PROXY).to have_received(:relay).with(
            'type' => 'logstash_object',
            activity_id: activity.id,
            activity_type: activity.activity_type,
            all_keys_missing: false,
            application: :m3,
            attempt_number: 0,
            data_source: :validate_responses,
            environment: Rails.env,
            form_id: '',
            missing_keys_detail: { 'open_ended' => ['question_02'] },
            mode: :submitted,
            navigator_user_agent: request['HTTP_USER_AGENT'],
            percent_keys_missing: 25.0,
            section_id: section.id,
            status: 0,
            user_id: user.id,
            vhl_component: 'missing_submission_keys'
          )
        end

        it 'fills in the missing keys' do
          submitted_values = HashWithIndifferentAccess.new(
            question_01: 'foo',
            question_03: 'baz',
            question_04: 'buz'
          )
          expected_values = submitted_values.merge(
            HashWithIndifferentAccess.new(question_02: '')
          )
          allow(activity.content_object).to receive(:validate_responses)

          attempt.validate_responses(activity, submitted_values, request)

          expect(activity.content_object).to have_received(:validate_responses)
            .with(expected_values, anything, :submitted, nil, [])
        end
      end

      context 'when missing answers are permitted' do
        before do
          allow(activity).to receive(:allow_missing_answers?).and_return(true)
        end

        it 'passes the submitted values thru without modification' do
          submitted_values = HashWithIndifferentAccess.new(
            question_01: 'foo',
            question_03: 'baz',
            question_04: 'buz'
          )
          allow(activity.content_object).to receive(:validate_responses)

          attempt.validate_responses(activity, submitted_values, request)

          expect(activity.content_object).to have_received(:validate_responses)
            .with(submitted_values, anything, :submitted, nil, [])
        end
      end
    end

    context 'when all keys are missing,' do
      it 'notifies the stats server' do
        expected_missing_keys = {
          'open_ended' => %w[question_01 question_02 question_03 question_04]
        }
        attempt.validate_responses(
          activity,
          HashWithIndifferentAccess.new,
          request
        )
        expect(STATS_PROXY).to have_received(:relay).with(
          'type' => 'logstash_object',
          activity_id: activity.id,
          activity_type: activity.activity_type,
          all_keys_missing: true,
          application: :m3,
          attempt_number: 0,
          data_source: :validate_responses,
          environment: Rails.env,
          form_id: '',
          missing_keys_detail: expected_missing_keys,
          mode: :submitted,
          navigator_user_agent: request['HTTP_USER_AGENT'],
          percent_keys_missing: 100.0,
          section_id: section.id,
          status: 0,
          user_id: user.id,
          vhl_component: 'missing_submission_keys'
        )
      end

      it 'fills in all the missing keys' do
        expected_values = HashWithIndifferentAccess.new(
          question_01: '',
          question_02: '',
          question_03: '',
          question_04: ''
        )
        allow(activity.content_object).to receive(:validate_responses)

        attempt.validate_responses(activity, HashWithIndifferentAccess.new, request)

        expect(activity.content_object).to have_received(:validate_responses).with(
          expected_values,
          anything,
          :submitted,
          nil,
          []
        )
      end
    end

    context 'when no keys are missing,' do
      it 'notifies the stats server even if no keys are missing' do
        attempt.validate_responses(
          activity,
          HashWithIndifferentAccess.new(
            question_01: 'foo',
            question_02: 'bar',
            question_03: 'baz',
            question_04: 'buz'
          ),
          request
        )

        expect(STATS_PROXY).to have_received(:relay).with(
          'type' => 'logstash_object',
          activity_id: activity.id,
          activity_type: activity.activity_type,
          all_keys_missing: false,
          application: :m3,
          attempt_number: 0,
          data_source: :validate_responses,
          environment: Rails.env,
          form_id: '',
          missing_keys_detail: {},
          mode: :submitted,
          navigator_user_agent: request['HTTP_USER_AGENT'],
          percent_keys_missing: 0.0,
          section_id: section.id,
          status: 0,
          user_id: user.id,
          vhl_component: 'missing_submission_keys'
        )
      end

      it 'passes on the submitted values' do
        allow(activity.content_object).to receive(:validate_responses)

        submitted_values = HashWithIndifferentAccess.new(
          question_01: 'foo',
          question_02: 'bar',
          question_03: 'baz',
          question_04: 'buz'
        )
        attempt.validate_responses(activity, submitted_values, request)

        expect(activity.content_object).to have_received(:validate_responses)
          .with(submitted_values, anything, :submitted, nil, [])
      end
    end
  end

  describe '#propagate_time_spent_to_score' do
    let(:gradebook_api_class) { GradebookEngine::GradebookAPI }
    let(:school) { build_stubbed(:school) }
    let(:score) { create(:gb_score_action) }
    let(:submission) { double(Gradebook::Submission, submit_nongradable: true) }

    let(:user) { build_stubbed(:user) }
    let(:section) { build_stubbed(:section) }
    let(:activity) { build_stubbed(:activity) }
    let(:attempt) do
      build(
        :attempt,
        activity: activity,
        section: section,
        status_code: AttemptStatus::CODE_SUBMITTED,
        time_spent: 146,
        user: user
      )
    end

    before do
      allow(activity).to receive(:gradable?).and_return(true)
      allow(section).to receive(:school).and_return(school)
      allow(section).to receive(:school_id).and_return(school.id)
      allow(Gradebook::Submission).to receive(:new).and_return(submission)
      allow(gradebook_api_class).to receive(:find_score).and_return(nil)
      allow(gradebook_api_class).to receive(:update_time_spent).and_return(true)
    end

    context 'with a gradeable activity,' do
      context 'when the attempt is not submitted,' do
        it 'does not propagate the time_spent' do
          attempt.status_code = AttemptStatus::CODE_OPENED
          attempt.propagate_time_spent_to_score
          expect(gradebook_api_class).not_to have_received(:update_time_spent)
        end
      end

      context 'when the attempt has been submitted' do
        it 'updates time spent in the gradebook' do
          attempt.status_code = AttemptStatus::CODE_SUBMITTED
          attempt.propagate_time_spent_to_score
          expect(gradebook_api_class).to have_received(:update_time_spent)
            .with(user.id, section.id, activity.id, school.id,
                  time_spent: attempt.time_spent)
        end
      end
    end

    context 'when activity is not gradable' do
      before do
        allow(activity).to receive(:gradable?).and_return(false)
      end

      context 'when the attempt is not submitted,' do
        before do
          attempt.status_code = AttemptStatus::CODE_OPENED
        end

        it 'submits the score as non-gradable' do
          attempt.propagate_time_spent_to_score
          expect(submission).to have_received(:submit_nongradable)
          expect(Gradebook::Submission).to have_received(:new)
        end

        context 'when the activity is completable,' do
          before do
            allow(activity).to receive(:activity_type)
              .and_return('learning_engine')
          end

          it "doesn't update time spent" do
            attempt.propagate_time_spent_to_score
            expect(GradebookEngine::GradebookAPI).not_to have_received(:update_time_spent)
          end

          it "doesn't create a submission" do
            attempt.propagate_time_spent_to_score
            expect(Gradebook::Submission).not_to have_received(:new)
          end
        end
      end
    end
  end

  describe '.transfer_work' do
    let(:section_from) { create(:section) }
    let(:section_to) { create(:section) }
    let(:student) { create(:student) }
    let!(:attempts) do
      [create(:attempt, user: student, section: section_from),
       create(:attempt, user: student, section: section_from),
       create(:attempt, user: create(:student), section: section_from),
       create(:attempt, user: create(:student), section: section_to)]
    end

    it "moves only one student's work" do
      expect(Attempt.by_section(section_from).count).to eql 3
      expect(Attempt.by_section(section_to).count).to eql 1
      Attempt.transfer_work(student, section_from, section_to)
      expect(Attempt.by_section(section_from).count).to eql 1
      expect(Attempt.by_section(section_to).count).to eql 3
    end

    it 'moves the students attempts from old section to new' do
      expect(student.attempts_by_section(section_from).count).to eql 2
      Attempt.transfer_work(student, section_from, section_to)
      expect(student.attempts_by_section(section_from).count).to eql 0
      expect(student.attempts_by_section(section_to).count).to eql 2
    end
  end

  describe '#revision_activity' do
    let(:activity) { FactoryBot.build_stubbed(:activity) }
    let(:attempt) { FactoryBot.build_stubbed(:attempt, activity: activity) }

    it 'returns an activity with the correct version' do
      expect(attempt.activity).to receive(:ensure_correct_version).with(attempt.cms_revision_id)
      expect(attempt.revision_activity).to be_eql(attempt.activity)
    end
  end

  describe '#teammates_from_results' do
    let(:user) { create(:student) }
    let(:partner) { create(:student) }
    let(:activity) { build_stubbed(:activity, activity_type: 'composition') }
    let(:attempt) { build_stubbed(:attempt, activity: activity) }
    let(:response) { double('Response', user_id: user.id, partner_id: partner.id) }
    let(:results) { [response: response] }

    before do
      allow(attempt).to receive(:results).and_return(results)
    end

    it 'returns nil if the activity is not a partner_chat or a group_chat' do
      expect(attempt.teammates_from_results).to be_nil
    end

    context 'when the attempted activity is a partner chat activity' do
      let(:activity) { build_stubbed(:activity, activity_type: 'partner_chat') }

      it 'uses the results partner id to return the teammate, ' \
         'when the user who submitted the activity is the same user as the attempt' do
        allow(attempt).to receive(:user).and_return(user)
        expect(attempt.teammates_from_results).to eq [partner]
      end

      it 'uses the results user id to return the teammate, ' \
         'when the user in the attempt is the partner'do
        allow(attempt).to receive(:user).and_return(partner)
        expect(attempt.teammates_from_results).to eq [user]
      end
    end

    context 'when the attempted activity is a group chat activity' do
      let(:activity) { build_stubbed(:activity, activity_type: 'group_chat') }
      let(:response) do
        double('Response', user_id: user.id, participants: [partner.id.to_s, other_partner.id.to_s])
      end
      let(:other_partner) { create(:student) }

      it 'returns the partners if the user that submitted is the same user in the attempt' do
        allow(attempt).to receive(:user).and_return(user)
        expect(attempt.teammates_from_results).to match_array [partner, other_partner]
      end

      it 'returns the student that submitted the activity and the other partners, ' \
         'when the user in the attempt is a partner user' do
        allow(attempt).to receive(:user).and_return(partner)
        expect(attempt.teammates_from_results).to match_array [user, other_partner]
      end
    end
  end

  describe '#hash_key' do
    let(:attempt) { build_stubbed(:attempt) }

    context 'when an attempt has section_id zero' do
      before do
        attempt.section_id = 0
      end

      it 'does not raise an exception' do
        attempt.hash_key
      end

      it 'returns the a string composed of the section id, activity id and activity class' do
        expect(attempt.hash_key).to eql "0_#{attempt.activity_id}_#{attempt.activity.class}"
      end
    end

    context 'when an attempt is for a regular activity' do
      it 'includes the activity type in the returned value' do
        expect(attempt.hash_key).to eql "#{attempt.section_id}_#{attempt.activity_id}_Activity"
      end
    end
  end

  describe '#smartbook_responses' do
    let(:sb_activity) { build_stubbed(:activity, activity_type: 'smart_book') }
    let(:attempt) { build_stubbed(:attempt, activity: sb_activity) }
    let(:datastore) { instance_double(ResultsApiDatastore, stored_responses: nil) }

    it 'returns nil if there are no stored_responses' do
      allow(attempt).to receive(:results_datastore).and_return(datastore)
      expect(attempt.smartbook_responses).to eql nil
    end
  end

  describe '#smartbook_responses_with_feedback_items' do
    let(:attempt) { build_stubbed(:attempt) }
    let(:response1) { instance_double(Smartbook::Response, label: 'question_1') }
    let(:response2) { instance_double(Smartbook::Response, label: 'question_2') }
    let(:response3) { instance_double(Smartbook::Response, label: 'question_3') }
    let(:smartbook_responses) { instance_double(Smartbook::Responses) }
    let(:feedback_item1) { instance_double(FeedbackItem, question_label: 'question_1') }
    let(:feedback_item2) { instance_double(FeedbackItem, question_label: 'question_2') }

    before do
      allow(attempt).to receive(:smartbook_responses).and_return(smartbook_responses)
      allow(attempt).to receive(:feedback_items).and_return([feedback_item2, feedback_item1])
    end

    it 'returns only those responses that have feedback items' do
      allow(smartbook_responses).to receive(:answered).and_return(
        [response3, response1, response2]
      )
      expect(attempt.smartbook_responses_with_feedback).to eql(
        [[response1, feedback_item1], [response2, feedback_item2]]
      )
    end

    it 'returns empty array when no response has a feedback item' do
      allow(smartbook_responses).to receive(:answered).and_return(
        [response3]
      )
      expect(attempt.smartbook_responses_with_feedback).to eql []
    end

    it 'returns empty array when there are no responses' do
      allow(attempt).to receive(:smartbook_responses).and_return(nil)
      expect(attempt.smartbook_responses_with_feedback).to eql []
    end
  end

  describe '#results_points_earned' do
    let(:results) { double(MaestroActivityEngine::ActivityContent::Results ) }
    let(:smartbook_responses) { double(Smartbook::Responses ) }
    let(:attempt)  { create(:attempt, activity: build_stubbed(:activity)) }
    let(:sb_activity) { create(:activity, activity_type: 'smart_book')}
    let(:sb_attempt)  { create(:attempt, activity: sb_activity) }

    before do
      allow(attempt).to receive(:results).and_return(results)
      allow(results).to receive(:points_earned).and_return(70.0)
      allow(sb_attempt).to receive(:smartbook_responses).and_return(smartbook_responses)
      allow(smartbook_responses).to receive(:points_earned).and_return(95.0)
    end

    context 'when activity is not a smartbook' do
      it 'returns the points earned from the Activity::Content::Results instance' do
        expect(attempt.results_points_earned('question_1')).to eq 70.0
      end
    end

    context 'when activity is a smartbook' do
      it 'returns the points earned from the SmartBook::Responses instance' do
        expect(sb_attempt.results_points_earned('question_1')).to eq 95.0
      end
    end
  end

  describe Attempt::TimeSpentDeltaCalculator do
    describe '#time_spent_delta' do
      it 'returns the difference between two timestamps in seconds' do
        time_spent_calculator = Attempt::TimeSpentDeltaCalculator.new(1_358_586_076, 1_358_586_176)
        expect(time_spent_calculator.time_spent_delta).to eql 100
      end

      it 'returns zero if the start_time is not defined' do
        time_spent_calculator = Attempt::TimeSpentDeltaCalculator.new(nil, 1_358_586_176)
        expect(time_spent_calculator.time_spent_delta).to eql 0
      end

      it 'returns zero if the end_time is not defined' do
        time_spent_calculator = Attempt::TimeSpentDeltaCalculator.new(1_358_586_076, nil)
        expect(time_spent_calculator.time_spent_delta).to eql 0
      end

      it 'returns zero if the delta is not positive' do
        time_spent_calculator = Attempt::TimeSpentDeltaCalculator.new(-1_358_586_076, nil)
        expect(time_spent_calculator.time_spent_delta).to eql 0
      end

      it 'returns zero if both the start_time and end_time are undefined' do
        time_spent_calculator = Attempt::TimeSpentDeltaCalculator.new(nil, nil)
        expect(time_spent_calculator.time_spent_delta).to eql 0
      end
    end
  end

  def question_label(label_suffix, activity_type)
    MaestroActivityEngine::ActivityContent::Common::QuestionLabel.new("question_#{label_suffix}", activity_type)
  end
end
