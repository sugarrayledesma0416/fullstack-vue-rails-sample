describe ReviewWorkPresenter do
  include RspecJsContentHelpers
  let(:instructor) { build_stubbed(:instructor) }
  let(:activity) { build_stubbed(:activity) }
  let(:multi_type_activity) { create_multi_type_with_solo_video_recording_activity(program) }
  let(:student) { build_stubbed(:student) }
  let(:teammate) { build_stubbed(:student) }
  let(:score) { create(:gb_score_action, activity: activity, section: section) }
  let(:question) { double('Question', label: 'question_label') }
  let(:course) { create(:course) }
  let(:section) { create(:section, course: course) }
  let(:program) { create(:program) }
  let(:current_student_attempt) do
    create(
      :attempt_completed,
      user: student,
      activity: activity,
      section: section,
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let(:attempts_hash) { { current_student_attempt: current_student_attempt } }
  let(:pchat_results) do
    [
      {
        label: "question_1",
        correctness: "pending",
        points_possible: 10,
        points_earned: 0,
        response: double(
                    PartnerChatRecording,
                    id: 4,
                    user_id: student.id,
                    user: student,
                    partner_id: teammate.id,
                    partner: teammate,
                    recording_path: "recording_path",
                    activity_id: 42240,
                    partner_practice: false
                  ),
        submitted: true,
        auto_graded: false
      }
    ]
  end
  let!(:teammate_attempt) do
    create(
      :attempt_completed,
      user: teammate,
      activity: activity,
      section: section,
      cms_activity_id: activity.cms_activity_id,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let(:presenter) { ReviewWorkPresenter.new(instructor, score, attempts_hash) }

  before do
    allow(Activity).to receive(:find).with(any_args).and_return(activity, multi_type_activity)
    allow(Section).to receive(:find).with(section.id) { section }
    allow(activity).to receive(:activity_type) { 'recording_v2' }
    allow(User).to receive(:where).with(id: student.id).and_return([student])
    allow(User).to receive(:where).with(id: teammate.id).and_return([teammate])
  end

  describe "#show_comments" do
    it "returns true for partner_chat, virtual_chat, recording_v2, and solo video recording activities" do
      ['recording_v2', 'partner_chat', 'virtual_chat', 'solo_video_recording'].each do |type|
        allow(activity).to receive(:activity_type).and_return(type)
        expect(presenter.show_comments).to be_truthy
      end
    end

    it "returns false for other types" do
      ['fill_in_the_blanks', 'open_ended', 'multiple_choice'].each do |type|
        allow(activity).to receive(:activity_type).and_return(type)
        expect(presenter.show_comments).to be_falsey
      end
    end

    context 'with multi_type activities' do
      let(:mt_score) { create(:gb_score_action, activity: multi_type_activity, section: section) }
      let(:current_student_mt_attempt) do
        create(
          :attempt_completed,
          user: student,
          activity: multi_type_activity,
          section: section,
          cms_activity_id: multi_type_activity.cms_activity_id,
          cms_revision_id: multi_type_activity.cms_revision_id
        )
      end
      let(:mt_attempts_hash) { { current_student_attempt: current_student_mt_attempt } }
      let(:mt_presenter) { ReviewWorkPresenter.new(instructor, mt_score, mt_attempts_hash) }

      it "returns true for multi_types that includes a solo video recording" do
        expect(mt_presenter.show_comments).to be_truthy
      end

      it "returns false for multi_types that do not include a solo video recording" do
        allow(activity).to receive(:activity_type).and_return('multi_type')
        expect(presenter.show_comments).to be_falsey
      end
    end
  end

  describe "#questions_to_grade" do
    it "returns all the questions in the activity" do
      allow(activity).to receive(:activity_type).and_return('open_ended')
      expect(presenter.activity).to receive(:questions)
      presenter.questions_to_grade
    end
  end

  describe "#feedback" do
    let(:feedback_items) do
      [
        double(
          'FeedbackItem',
          question_label: 'question_1',
          user_id: student.id
        ),
        double(
          'FeedbackItem',
          question_label: 'question_1',
          user_id: teammate.id
        )
      ]
    end
    let(:question) { double('Question', label: 'question_1') }
    let(:grading_feedback) { double(GradingFeedback, feedback: feedback_items) }

    context "when there is a partner for the activity (the activity type is partner_chat)" do
      before do
        allow(activity).to receive(:activity_type) { 'partner_chat' }
        allow(current_student_attempt).to receive(:results) { pchat_results }
      end

      it "finds all feedback items for the user and partner" do
        allow(presenter).to receive(:questions_to_grade).and_return([question])
        expect(GradingFeedback)
          .to receive(:new)
          .with(
            activity: activity,
            questions: [question],
            students: [student, teammate],
            sections: [section]
          )
        presenter.feedback
      end
    end

    context "when there is not a partner for the activity" do
      it "finds all feedback items for only the user" do
        single_user_attempts = {
          current_student_attempt: build_stubbed(
                                     :attempt,
                                     user: student,
                                     activity: activity,
                                     section: section
                                   )
        }
        single_user_presenter = ReviewWorkPresenter.new(instructor, score, single_user_attempts)
        allow(single_user_presenter).to receive(:questions_to_grade).and_return([question])
        expect(GradingFeedback)
          .to receive(:new)
          .with(
            activity: activity,
            questions: [question],
            students: [student],
            sections: [section]
          )
        single_user_presenter.feedback
      end
    end
  end

  describe '#response_id', test_debt: true do
    it "returns string used to identify a student's response for a question" do
      expect(presenter.response_id(student, question)).to eq "#{question.label}_student_#{student.id}"
    end
  end

  describe "#recording_path" do
    context "when the instructor has already recorded a comment for that question" do
      it "returns the path to the recorded comment" do
        allow(presenter).to receive(:recording).and_return(nil)
        new_recording = double(Recording)
        expect(Recording).to receive(:new).and_return(new_recording)
        expect(new_recording).to receive(:generate_file_prefix).with(:instructor)
        presenter.recording_path(student, question)
      end
    end

    context "when the instructor has not recorded a comment" do
      it "returns a path to a stored recording" do
        new_recording = double(Recording)
        allow(presenter).to receive(:recording).and_return(new_recording)
        expect(new_recording).to receive(:recording_path).and_return('test_path')
        expect(presenter.recording_path(student, question)).to eql 'test_path'
      end
    end
  end

  describe "#new_recording?" do
    it "returns true when there is not a pre-existing recording for a given student and question" do
      allow(presenter).to receive(:recording).and_return(nil)
      expect(presenter.new_recording?(student, question)).to be_truthy
    end

    it "returns false when there is a pre-existing recording for a given student and question" do
      allow(presenter).to receive(:recording).and_return(double(Recording))
      expect(presenter.new_recording?(student, question)).to be_falsey
    end
  end

  describe "#students_to_submit" do
    context "when there is a teammate for the given activity" do
      before do
        allow(activity).to receive(:activity_type).and_return('partner_chat')
        allow(current_student_attempt).to receive(:results) { pchat_results }
      end

      it "returns a list of the teammates and the user" do
        expect(presenter.students_to_submit).to match_array([presenter.current_student] + presenter.teammates)
      end
    end

    context "when there is not a teammate for the given activity" do
      it "returns a list with only the user" do
        allow(presenter).to receive(:teammate).and_return(nil)
        expect(presenter.students_to_submit).to eql [presenter.current_student]
      end
    end
  end

  describe "#attempts_by_user_id" do
    it "return the attempts as a student_id keyed hash" do
      student_id = 1234
      attempt = double('Attempt', user_id: student_id, results: double('Results', points_earned: 3))
      allow(presenter).to receive(:attempts).and_return([attempt])
      expect(presenter.attempts_by_user_id).to eq({ student_id.to_s => attempt })
    end
  end

  describe "#gradeable?" do
    describe "when the given student is the current student" do
      it "returns true when the student is in a section that the instructor has access to" do
        allow(instructor).to receive(:gradeable_sections).and_return([section])
        expect(presenter.gradeable?(student)).to be_truthy
      end

      it "returns false when the student is not in a section that the instructor has access to" do
        expect(presenter.gradeable?(student)).to be_falsey
      end
    end

    describe "when the given student is the teammate" do
      before do
        allow(activity).to receive(:activity_type) { 'partner_chat' }
        allow(current_student_attempt).to receive(:results) { pchat_results }
      end

      it "returns true when the student is in a section that the instructor has access to" do
        allow(instructor).to receive(:gradeable_sections).and_return([section])
        expect(presenter.gradeable?(teammate)).to be_truthy
      end

      it "returns false when the student is not in a section that the instructor has access to" do
        expect(presenter.gradeable?(teammate)).to be_falsey
      end

      it 'does not raise an error if the teammate is now in a different course' do
        teammate_attempt.update(section_id: create(:section))
        expect{ presenter.gradeable?(teammate) }.not_to raise_error
      end
    end
  end

  describe "#multi_type_activity_view_manager" do
    it "returns a new multi type activity view manager" do
      expect(MultiTypeActivityViewManager).to receive(:new)
      presenter.multi_type_activity_view_manager
    end
  end

  describe '#assign_lossless_auth_token?' do
    it 'returns true when the activity is a smart book activity' do
      allow(activity).to receive(:activity_type).and_return('smart_book')

      expect(presenter.assign_lossless_auth_token?).to be true
    end

    it 'returns false when the activity is a static book activity' do
      allow(activity).to receive(:activity_type).and_return('static_book')

      expect(presenter.assign_lossless_auth_token?).to be false
    end

    it 'returns true when the activity is an AI virtual chat activity' do
      allow(activity).to receive(:activity_type).and_return('ai_virtual_chat')

      expect(presenter.assign_lossless_auth_token?).to be true
    end

    it 'returns false for other activity types' do
      expect(presenter.assign_lossless_auth_token?).to be false
    end
  end
end
