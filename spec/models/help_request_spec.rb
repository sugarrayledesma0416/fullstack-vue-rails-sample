describe HelpRequest do
  describe 'validations' do
    it 'requires user' do
      help_request = build(:help_request, user_id: nil)
      expect(help_request).not_to be_valid
      expect(help_request.errors[:user_id]).to contain_exactly('is required')
      expect(help_request.errors[:user]).to contain_exactly('must exist')
    end

    it 'requires program' do
      help_request = build(:help_request, program_id: nil)
      expect(help_request).not_to be_valid
      expect(help_request.errors[:program_id]).to contain_exactly('is required')
      expect(help_request.errors[:program]).to contain_exactly('must exist')
    end

    it 'requires activity' do
      help_request = build(:help_request, activity_id: nil)
      expect(help_request).not_to be_valid
      expect(help_request.errors[:activity_id]).to contain_exactly('is required')
      expect(help_request.errors[:activity]).to contain_exactly('must exist')
    end

    it 'requires request_type be one of the valid request types' do
      request = build(:help_request, request_type: 'invalid_type')
      expect(request).not_to be_valid
      expect(request.errors[:request_type]).to contain_exactly(
        "'invalid_type' must be one of: #{HelpRequest::REQUEST_TYPES.join(', ')}"
      )
    end
  end

  describe 'scopes' do
    describe '.by_section_and_activity' do
      it 'returns only help requests for the specified section and activity' do
        section = create(:section)
        activity = create(:activity)

        target_help_request    = create(:help_request, :activity => activity, :section => section)
        other_section_request  = create(:help_request, :activity => activity, :section => create(:section))
        other_activity_request = create(:help_request, :activity => create(:activity), :section => section)

        expect(HelpRequest.by_section_and_activity(section, activity)).to eq([target_help_request])
      end
    end

    describe 'by_user_and_activity' do
      it 'returns only help requests for the specified user and activity' do
        user     = create(:student)
        activity = create(:activity)

        target_help_request    = create(:help_request, :activity => activity, :user => user)
        other_user_request     = create(:help_request, :activity => activity, :user => create(:student))
        other_activity_request = create(:help_request, :activity => create(:activity), :user => user)

        expect(HelpRequest.by_user_and_activity(user, activity)).to eq([target_help_request])
      end
    end

    describe '.for_question_label' do
      it 'returns only help requests for the specified question label' do
        target_help_request = create(:help_request, :helpable_item_id => 'question_1_prompt')
        other_target_help_request = create(:help_request, :helpable_item_id => 'question_1')
        other_help_request  = create(:help_request, :helpable_item_id => 'question_10_prompt')

        help_requests = HelpRequest.for_question_label('question_1')
        expect(help_requests).to match_array([target_help_request, other_target_help_request])
        expect(help_requests).not_to include other_help_request
      end
    end

    describe '.by_user' do
      it 'returns only help requests for the specified user' do
        user = create(:student)

        target_help_request = create(:help_request, :user => user)
        other_user_request  = create(:help_request, :user => create(:student))

        expect(HelpRequest.by_user(user)).to eq([target_help_request])
      end
    end

    describe 'when including EmojiRemovable' do
      it 'removes emojis from the student_comment and instructor_comment' do
        help_request = create(:help_request, :student_comment => 'Hello 🤔', :instructor_comment => 'Hello 🤔')
        expect(help_request.student_comment).to eq('Hello')
        expect(help_request.instructor_comment).to eq('Hello')
      end

      it 'does not remove if no emojis are present' do
        help_request = create(:help_request, :student_comment => 'Hello', :instructor_comment => 'Hello')
        expect(help_request.student_comment).to eq('Hello')
        expect(help_request.instructor_comment).to eq('Hello')
      end
    end

    describe '.by_section' do
      it 'returns only help requests for the specified section' do
        section = create(:section)

        target_help_request    = create(:help_request, :section => section)
        other_section_request  = create(:help_request, :section => create(:section))

        expect(HelpRequest.by_section(section)).to eq([target_help_request])
      end
    end

    describe '.unprocessed' do
      it 'returns only help requests with a status of "submitted"' do
        open_request      = create(:help_request, :status => 'submitted')
        denied_request    = create(:help_request, :status => 'denied')
        responded_request = create(:help_request, :status => 'responded')
        expect(HelpRequest.unprocessed).to eq([open_request])
      end
    end

    describe '.processed' do
      it "returns processed help requests only" do
        open_request      = create(:help_request, :status => 'submitted')
        denied_request    = create(:help_request, :status => 'denied')
        responded_request = create(:help_request, :status => 'responded')
        expect(HelpRequest.processed).to eq([denied_request, responded_request])
      end
    end

    describe '.instructor_respondable' do
      it 'returns only help requests with request type of request_view or request_help' do
        review_request           = create(:review_request)
        help_request             = create(:help_request)
        technical_problem_report = create(:technical_problem_report)
        content_problem_report   = create(:content_problem_report)
        expect(HelpRequest.instructor_respondable).to match_array([review_request, help_request])
      end
    end

    describe '.reported_problems' do
      it 'returns only help requests with request type of report_content_problem or report_technical_problem' do
        review_request           = create(:review_request)
        help_request             = create(:help_request)
        technical_problem_report = create(:technical_problem_report)
        content_problem_report   = create(:content_problem_report)
        expect(HelpRequest.reported_problems).to match_array([technical_problem_report, content_problem_report])
      end
    end

    describe '.by_request_type' do
      it 'returns only help requests with the specified request type' do
        review_request           = create(:review_request)
        help_request             = create(:help_request)
        technical_problem_report = create(:technical_problem_report)
        content_problem_report   = create(:content_problem_report)

        expect(HelpRequest.by_request_type('request_review')).to eq([review_request])
        expect(HelpRequest.by_request_type(['request_review', 'request_help'])).to match_array([review_request, help_request])
      end
    end

    describe '.by_section_activity_and_request_type' do
      it 'returns only help requests for the specified section and activity' do
        section = create(:section)
        activity = create(:activity)

        target_help_request         = create(:help_request, :activity => activity, :section => section)
        other_section_help_request  = create(:help_request, :activity => activity, :section => create(:section))
        other_activity_help_request = create(:help_request, :activity => create(:activity), :section => section)
        target_review_request         = create(:review_request, :activity => activity, :section => section)
        other_section_review_request  = create(:review_request, :activity => activity, :section => create(:section))
        other_activity_review_request = create(:review_request, :activity => create(:activity), :section => section)

        expect(HelpRequest.by_section_activity_and_request_type(section, activity, 'request_help')).to eq([target_help_request])
        expect(HelpRequest.by_section_activity_and_request_type(section, activity, 'request_review')).to eq([target_review_request])
      end
    end
  end

  describe '.by_active_enrollments' do
    it 'retrieves the help and review request for enrolled students only' do
      section = create(:section)
      other_section = create(:section)
      user = create(:student)
      other_user = create(:student)

      create(:active_enrollment, section: other_section, user: other_user)
      create(:dropped_enrollment, section: section, user: user)

      create(:help_request, section: section, user: user)
      expected_help_request = create(:help_request, section: other_section, user: other_user)

      expect(described_class.by_active_enrollments.to_a).to eq [expected_help_request]
    end
  end

  describe '.instructor_respondable_by_user_and_section' do
    it 'returns only help and review request for the enrolled students in the specified section' do
      section = create(:section)
      other_section = create(:section)
      user = create(:student)
      other_student = create(:student)

      create(:active_enrollment, section: other_section, user: user)
      create(:active_enrollment, section: section, user: other_student)
      create(:dropped_enrollment, section: section, user: user)

      other_user_help_request  = create(:help_request, section: section, user: other_student)

      create(:review_request, section: section, user: user)
      create(:help_request, section: section, user: user)
      create(:technical_problem_report, section: section, user: user)
      create(:content_problem_report, section: section, user: user)
      create(:help_request, section: create(:section), user: user)

      students = [other_student, user]
      sections = [other_section, section]

      expectation = described_class.instructor_respondable_by_user_and_section(students, sections)

      expect(expectation).to eq [other_user_help_request]
    end
  end

  describe '.instructor_respondable_by_section_and_activity' do
    it 'returns only help and review requests for the specified section and activity' do
      section  = create(:section)
      activity = create(:activity)
      review_request           = create(:review_request, :section => section, :activity => activity)
      help_request             = create(:help_request, :section => section, :activity => activity)
      technical_problem_report = create(:technical_problem_report, :section => section, :activity => activity)
      content_problem_report   = create(:content_problem_report, :section => section, :activity => activity)
      other_section_request    = create(:help_request, :section => create(:section), :activity => activity )
      other_activity_request   = create(:help_request, :section => section, :activity => create(:activity) )
      expect(HelpRequest.instructor_respondable_by_section_and_activity(section, activity)).to match_array([help_request, review_request])
    end
  end

  describe '.instructor_respondable_by_section_user_activity_and_question' do
    context 'when question is specified' do
      it 'returns only help and review requests for the specified section, user, activity, and question label' do
        section  = create(:section)
        section_2  = create(:section)
        user     = create(:student)
        activity = create(:activity)
        target_question_label = 'question_1'
        other_question_label  = 'question_2'

        help_request   = create(:help_request, :section => section, :user => user, :activity => activity, :helpable_item_id => target_question_label)
        review_request = create(:review_request, :section => section, :user => user, :activity => activity, :helpable_item_id => target_question_label)
        create(:technical_problem_report, :user => user, :activity => activity, :helpable_item_id => target_question_label)
        create(:content_problem_report, :user => user, :activity => activity, :helpable_item_id => target_question_label)
        create(:help_request, :section => section_2, :user => user, :activity => activity, :helpable_item_id => other_question_label)
        create(:help_request, :section => section_2, :user => user, :activity => create(:activity), :helpable_item_id => target_question_label)
        create(:help_request, :section => section_2, :user => create(:student), :activity => activity, :helpable_item_id => target_question_label)

        results = HelpRequest.instructor_respondable_by_section_user_activity_and_question(section, user, activity, target_question_label)
        expect(results).to match_array([help_request, review_request])
      end
    end

    context 'when a nil question is specified' do
      it 'returns only help and review requests for any question label for the specified section, user and activity' do
        section  = create(:section)
        section_2  = create(:section)
        user     = create(:student)
        activity = create(:activity)
        question_label_1 = 'question_1'
        question_label_2 = 'question_2'

        help_request   = create(:help_request, :section => section, :user => user, :activity => activity, :helpable_item_id => question_label_1)
        review_request = create(:review_request, :section => section, :user => user, :activity => activity, :helpable_item_id => question_label_1)
        question_2_request = create(:help_request, :section => section, :user => user, :activity => activity, :helpable_item_id => question_label_2)
        create(:technical_problem_report, :user => user, :activity => activity, :helpable_item_id => question_label_1)
        create(:content_problem_report, :user => user, :activity => activity, :helpable_item_id => question_label_1)
        create(:help_request, :section => section_2, :user => user, :activity => create(:activity), :helpable_item_id => question_label_1)
        create(:help_request, :section => section_2, :user => create(:student), :activity => activity, :helpable_item_id => question_label_1)

        results = HelpRequest.instructor_respondable_by_section_user_activity_and_question(section, user, activity, nil)
        expect(results).to match_array([help_request, review_request, question_2_request])
      end
    end
  end

  describe '.reported_problems_by_section' do
    let(:course) { create(:course) }

    it 'returns only content problems and technical problems for the specified section' do
      section = create(:section)
      review_request           = create(:review_request, section: section)
      help_request             = create(:help_request, section: section)
      technical_problem_report = create(:technical_problem_report, section: section)
      content_problem_report   = create(:content_problem_report, section: section)
      other_section_problem    = create(
        :technical_problem_report,
        section: create(:section)
      )
      expect(described_class.reported_problems_by_section(section)).to match_array(
        [
          technical_problem_report,
          content_problem_report
        ]
      )
    end

    it 'works when specified section is a scope' do
      course = build_stubbed(:course)
      section = create(:section, course: course)
      other_course = build_stubbed(:course)
      other_section = create(:section, course: other_course)
      content_problem_report = create(:content_problem_report, section: section)
      other_section_problem  = create(:content_problem_report, section: other_section)
      expect(described_class.reported_problems_by_section(Section.by_course(course.id))).to eq(
        [
          content_problem_report
        ]
      )
    end
  end

  describe '.count_unprocessed_by_request_type_section_and_students' do
    let(:section) { create(:section) }
    let(:other_section) { create(:section) }
    let(:student){ create(:student) }
    let(:other_student){ create(:student) }
    let(:another_student){ create(:student) }

    before do
      create(:review_request, :section => section, :user => student)
      create(:review_request, :section => other_section, :user => other_student)
      create(:review_request, :section => other_section, :user => another_student)
      create(:help_request, :section => section, :user => student)
      create(:technical_problem_report, :section => section, :user => student)
      section.students << student
      other_section.students << other_student
      other_section.students << another_student
    end

    context 'when no count options are specified' do
      it 'counts only help requests for the specified request type, section and students' do
        expect(HelpRequest.count_unprocessed_by_request_type_section_and_students('request_review', section, student)).to eq(1)

        students = [student, other_student]
        expect(HelpRequest.count_unprocessed_by_request_type_section_and_students('request_review', [section, other_section], students)).to eq 2
        expect(HelpRequest.count_unprocessed_by_request_type_section_and_students(['request_review', 'request_help'], [section, other_section], students)).to eq 3
        expect(HelpRequest.count_unprocessed_by_request_type_section_and_students(['request_review', 'request_help'], [other_section], another_student)).to eq 1
      end

      it 'only counts requests on sections where the student is active' do
        create(:review_request, section: other_section, user: student)
        expect(HelpRequest.count_unprocessed_by_request_type_section_and_students('request_review', [section, other_section], student)).to eq 1
      end
    end

    context 'when count options specifying grouping are specified' do
      it 'returns counts grouped by the specified columns' do
        create(:review_request, :section => section, :user => student)

        students = [student, other_student]
        count_opts = {group: 'help_requests.section_id'}

        result = HelpRequest.count_unprocessed_by_request_type_section_and_students('request_review', [section, other_section], students, count_opts)
        expect(result).to eq({ section.id => 2, other_section.id => 1 })
      end
    end

    context 'when count options specifying distinct values are specified' do
      it 'returns counts of distinct values for the specified fields' do
        create(:review_request, :section => section, :user => student)

        students = [student, other_student]
        count_opts = {select: 'distinct help_requests.section_id'}

        result = HelpRequest.count_unprocessed_by_request_type_section_and_students('request_review', [section, other_section], students, count_opts)
        expect(result).to eq 2
      end
    end

    context 'when count options specifying both grouping and distinct values are specified' do
      it 'returns counts of distinct values by group for the specified fields' do
        create(:review_request, :section => section, :user => student)

        students = [student, other_student]
        count_opts = { select: 'distinct help_requests.user_id', group: 'help_requests.section_id' }

        result = HelpRequest.count_unprocessed_by_request_type_section_and_students(
                   'request_review',
                   [section, other_section],
                   students, count_opts
                 )
        expect(result).to eq({ section.id => 1, other_section.id => 1 })
      end
    end
  end

  describe '.destroy_review_requests_for' do
    it 'deletes review requests associated with the activity, section and user' do
      student = create(:student)
      section = create(:section)
      activity = create(:activity)
      help_request = create(:help_request, :user => student, :section => section, :activity => activity)
      review_request = create(:review_request, :user => student, :section => section, :activity => activity)
      another_help_request = create(:help_request, :user => student, :section => section, :activity => activity)
      HelpRequest.destroy_review_requests_for(student, section, activity)

      requests = HelpRequest.where(user_id: student.id, section_id: section.id, activity_id: activity.id)
      expect(requests).not_to include review_request
      expect(requests).to match_array([help_request, another_help_request])
    end
  end

  describe '.processed_instructor_respondable_by_section_and_activity' do
    it 'returns only processed help requests with request type of request_view or request_help, for the specified section and activity' do
      activity = create(:activity)
      section  = create(:section)

      review_request           = create(:review_request, :section => section, :activity => activity, :status => 'responded')
      help_request             = create(:help_request,   :section => section, :activity => activity, :status => 'denied')
      technical_problem_report = create(:technical_problem_report, :section => section, :activity => activity, :status => 'responded')
      content_problem_report   = create(:content_problem_report, :section => section, :activity => activity, :status => 'responded')
      other_activity_request   = create(:help_request, :section => section, :activity => create(:activity), :status => 'responded' )
      other_section_request    = create(:help_request, :section => create(:section), :activity => activity, :status => 'responded' )
      unprocessed_request      = create(:help_request, :section => section, :activity => activity, :status => 'submitted' )
      content_problem_report   = create(:content_problem_report, :section => section, :activity => activity, :status => 'responded' )
      technical_problem_report = create(:technical_problem_report, :section => section, :activity => activity, :status => 'responded' )
      expect(HelpRequest.processed_instructor_respondable_by_section_and_activity(section, activity)).to match_array([review_request, help_request])
    end
  end

  describe '#processed?' do
    it 'returns true if status is responded' do
      expect(build_stubbed(:help_request, :status => 'responded')).to be_processed
    end

    it 'returns true if status is rejected' do
      expect(build_stubbed(:help_request, :status => 'denied')).to be_processed
    end

    it 'returns false if status is submitted' do
      expect(build_stubbed(:help_request, :status => 'submitted')).not_to be_processed
    end
  end

  describe '#problem_report?' do
    it 'is true for content problems' do
      expect(build_stubbed(:content_problem_report)).to be_problem_report
    end

    it 'is true for technical problems' do
      expect(build_stubbed(:technical_problem_report)).to be_problem_report
    end

    it 'is false for review requests' do
      expect(build_stubbed(:review_request)).not_to be_problem_report
    end

    it 'is false for help requests' do
      expect(build_stubbed(:help_request)).not_to be_problem_report
    end
  end

  describe '#technical_problem?' do
    it 'is true for only for technical problem reports' do
      expect(build_stubbed(:technical_problem_report)).to be_technical_problem
      expect(build_stubbed(:content_problem_report)).not_to be_technical_problem
      expect(build_stubbed(:review_request)).not_to be_technical_problem
      expect(build_stubbed(:help_request)).not_to be_technical_problem
    end
  end

  describe '#content_problem?' do
    it 'is true for only for content problem reports' do
      expect(build_stubbed(:content_problem_report)).to be_content_problem
      expect(build_stubbed(:technical_problem_report)).not_to be_content_problem
      expect(build_stubbed(:review_request)).not_to be_content_problem
      expect(build_stubbed(:help_request)).not_to be_content_problem
    end
  end

  describe '#student_name' do
    it 'returns nil if there is no user' do
      expect(build(:help_request, :user => nil).student_name).to be_nil
    end

    it 'returns the full name of the user' do
      user = build_stubbed(:student)
      expect(build_stubbed(:help_request, :user => user).student_name).to eq(user.full_name)
    end
  end

  describe '#instructor_name' do
    it 'returns nil if there is no user' do
      expect(build(:help_request, :user => nil).instructor_name).to be_nil
    end

    it 'returns the full name of the user' do
      user = build_stubbed(:instructor)
      expect(build_stubbed(:help_request, :instructor => user).instructor_name).to eq(user.full_name)
    end
  end

  describe '#dispatch_notification' do
    let(:section) { build_stubbed(:section) }
    let(:activity) { build_stubbed(:activity) }
    let(:user) { build_stubbed(:user) }

    it 'dispatches a notification for the help_request activity, specifing section and user' do
      help_request = create(:help_request, :activity => activity, :user => user, :section => section)

      expect(activity.notifications).to receive(:dispatch).with('HelpRequestResponse', hash_including(:user => user, :section => section) )

      help_request.dispatch_notification
    end
  end

  context 'callbacks' do
    let(:program) { create(:program) }
    let(:section) { create(:section) }
    let(:activity) { create(:activity) }
    let(:user) { create(:user) }
    let(:http_referer) { 'A quick brown fox!' }

    describe 'before_save' do
      it 'truncates the http_referer value if length greater than 255' do
        http_referer_255 = http_referer * 24
        help_request = build(
          :help_request,
          activity: activity,
          http_referer: http_referer_255,
          program: program,
          section: section,
          user: user
        )
        help_request.save
        expect(help_request.errors).to be_empty
        expect(help_request.http_referer).to eq http_referer_255.slice(0, 255)
        expect(help_request.http_referer.length).to eq 255
      end

      it 'does not truncate the http_referer value if its length is less than 255' do
        help_request = build(
          :help_request,
          activity: activity,
          http_referer: http_referer,
          program: program,
          section: section,
          user: user
        )
        help_request.save
        expect(help_request.errors).to be_empty
        expect(HelpRequest.find(help_request.id).http_referer).to eq http_referer
      end
    end
  end
end
