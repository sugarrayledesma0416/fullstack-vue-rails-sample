describe QuestionByQuestionPresenter do
  let(:instructor) { build_stubbed(:instructor) }
  let(:program) { build_stubbed(:program) }
  let(:student) { create(:student) }
  let(:course) { create(:course, owner: instructor) }
  let(:section) { create(:section, course: course) }
  let(:activity) { build_stubbed(:activity) }
  let(:grading_set) { double('GradingSet', :activity => activity, :students_to_grade => []) }
  let(:grading_feedback) { double(GradingFeedback) }
  let(:show_auto_graded_questions){ '1' }
  let(:previous_revision_id) { 1234 }
  let(:params) { {} }
  let(:presenter) do
    QuestionByQuestionPresenter.new(
      instructor,
      grading_set,
      program,
      [section],
      params,
      show_auto_graded_questions
    )
  end
  let(:question) { double('Question', :label => 'question_1') }

  describe "#prepare" do
    before do
      allow(presenter).to receive(:questions_to_grade).and_return([question])
    end

    let(:student_1) { build_stubbed(:student) }
    let(:student_2) { build_stubbed(:student) }
    let(:question) { double('Question', :label => 'question_1') }
    let(:params) { { :question_label => 'question_1' } }

    it "moves already graded students into a students_graded array" do
      allow(grading_feedback).to receive(:question_points).with(student_1, question.label).and_return(10)
      allow(grading_feedback).to receive(:question_points).with(student_2, question.label).and_return(nil)
      expect(GradingFeedback).to receive(:new).and_return(grading_feedback)
      allow(presenter).to receive(:current_question).and_return(question)
      allow(presenter).to receive(:students_to_grade).and_return([student_1, student_2])
      presenter.prepare
      expect(presenter.students_to_grade).to eql [student_2]
      expect(presenter.students_graded).to eql [student_1]
    end

    it "sets the activity revision ID to that of the attempts" do
      attempt = double('Attempt',
                       results: [{ response: 'partner_chat_response' }],
                       cms_revision_id: previous_revision_id)
      allow(presenter).to receive(:student_attempts).and_return('foo' => attempt)
      allow(activity).to receive(:partner_chat?).and_return(false)
      allow(activity).to receive(:content_object).and_return(Struct.new(:has_rubric?).new)
      presenter.prepare
      expect(presenter.activity.cms_revision_id).to eq(previous_revision_id)
    end

    describe 'when activity is a partner chat' do
      before do
        allow(activity).to receive(:partner_chat?).and_return(true)
        allow(presenter).to receive_messages(
          students: [student],
          teammate_attempt: nil,
          add_attempt_section_when_missing: nil,
          partner_chat_responses: [],
          questions_to_grade: [question]
        )
      end

      context 'with multiple students and distinct partners' do
        let(:other_student) { create(:student) }
        let(:partner_for_student) { build_stubbed(:user) }
        let(:partner_for_other_student) { build_stubbed(:user) }

        before do
          allow(presenter).to receive(:students).and_return([student, other_student])
          allow(presenter).to receive(:teammate_id).with(student).and_return(partner_for_student.id)
          allow(presenter).to receive(:teammate_id)
            .with(other_student)
            .and_return(partner_for_other_student.id)
          allow(User).to receive(:where).and_return(
            [
              partner_for_student,
              partner_for_other_student
            ]
          )
          presenter.prepare
        end

        it 'includes both students and their teammates in students_to_submit' do
          expect(presenter.students_to_submit).to contain_exactly(
            student,
            other_student,
            partner_for_student,
            partner_for_other_student
          )
        end
      end

      context 'when partner is an instructor' do
        it 'assigns instructor as teammate' do
          allow(presenter).to receive(:teammate_id).with(student).and_return(instructor.id)
          allow(User).to receive(:where).with(id: [instructor.id]).and_return([instructor])

          expect(presenter.prepare.teammate(student)).to eq(instructor)
        end
      end

      context 'when partner is a student' do
        it 'assigns student as teammate' do
          partner_student = build_stubbed(:student)
          allow(presenter).to receive(:teammate_id).with(student).and_return(partner_student.id)
          allow(User).to receive(:where)
            .with(id: [partner_student.id])
            .and_return([partner_student])

          presenter.prepare

          expect(presenter.teammate(student)).to eq(partner_student)
        end
      end

      it "returns nil when the student's teammate cannot be found" do
        allow(presenter).to receive(:teammate_id).with(student).and_return(instructor.id)
        allow(User).to receive(:where).with(id: [instructor.id]).and_return([])

        expect(presenter.prepare.teammate(student)).to be_nil
      end
    end
  end

  describe '#current_question' do
    let(:params) { { :question_label => 'question_1' } }
    let(:question) { double('Question', :label => 'question_1') }

    it 'returns the current question to grade when grading question by question' do
      allow(presenter).to receive(:questions_to_grade).and_return([question])

      expect(presenter.current_question).to eql question
    end

    it "when activity type = composition assigns a composition attachment when there is an attachment related to the activity and user" do
      allow(activity).to receive(:activity_type).and_return('composition')
      composition_attachment = build_stubbed(:composition_attachment)
      allow(CompositionAttachment).to receive(:find_by_user_id_and_activity_id).and_return(composition_attachment)
      expect(composition_attachment).to eql composition_attachment
    end
  end

  describe '#done?' do
    context 'when done early' do
      it 'returns true' do
        allow(presenter).to receive(:done_early?).and_return(true)

        expect(presenter.done?).to be_truthy
      end
    end

    context 'when there is no next student' do
      it 'returns true' do
        allow(presenter).to receive(:next_question).and_return(:no_next_element_found)

        expect(presenter.done?).to be_truthy
      end
    end

    context 'when not done early and there is a next student' do
      let(:question) { double('Question') }

      it 'returns false' do
        allow(presenter).to receive(:done_early?).and_return(false)
        allow(presenter).to receive(:next_question).and_return(question)

        expect(presenter.done?).to be_falsey
      end
    end
  end

  describe '#grading_status' do
    it 'returns the grading status of questions' do
      expect(grading_set).to receive(:grading_status_of_questions)
        .with(activity.questions).and_return('valid grading status')
      expect(presenter.grading_status).to eql 'valid grading status'
    end
  end

  describe '#last_item?' do
    let(:question) { double('Question') }

    context 'when current student is the last student to grade and the instructor is finishing their grading' do
      let(:params) { { commit: 'Done', jump_to: nil } }

      it 'returns true' do
        allow(presenter).to receive(:questions_to_grade).and_return([question])
        allow(presenter).to receive(:current_question).and_return(question)

        expect(presenter.last_item?).to be_truthy
      end
    end

    context 'when the current student is not the last student to grade' do
      let(:params) { { commit: 'Done', jump_to: nil } }

      it 'returns false' do
        other_question = double('Question')
        allow(presenter).to receive(:questions_to_grade).and_return([question])
        allow(presenter).to receive(:current_question).and_return(other_question)

        expect(presenter.last_item?).to be_falsey
      end
    end

    context 'when the instructor is moving to the previous student to grade' do
      let(:params) { { commit: '< Save & Previous', jump_to: nil } }

      it 'returns false' do
        allow(presenter).to receive(:questions_to_grade).and_return([question])

        expect(presenter.last_item?).to be_falsey
      end
    end

    context 'when the instructor is jumping to another student to grade' do
      let(:params) { { commit: 'Done', jump_to: 'valid jump_to value' } }

      it 'returns false' do
        allow(presenter).to receive(:questions_to_grade).and_return([question])

        expect(presenter.last_item?).to be_falsey
      end
    end
  end

  describe '#next_element' do
    let(:question) { double('Question', :label => 'question_1') }

    it 'returns a hash that contains a student id' do
      allow(presenter).to receive(:next_question).and_return(question)
      results = { :question_label => question.label }

      expect(presenter.next_element).to eql results
    end
  end

  describe '#partner_chat_responses' do
    it 'returns the partner chat recordings for all students' do
      attempt = double('Attempt', :results => [{ :response => 'partner_chat_response' }])
      expect(presenter).to receive(:student_attempt).with(student).and_return(attempt)
      allow(presenter).to receive(:students).and_return([student])

      expect(presenter.partner_chat_responses).to eql ['partner_chat_response']
    end
  end

  describe '#has_nothing_to_grade?' do
    it 'returns false when there is at least one student attempt' do
      attempt = build_stubbed(:attempt, user: student, activity: activity)
      allow(presenter).to receive(:student_attempts).and_return(attempt)

      expect(presenter).not_to have_nothing_to_grade
    end

    it 'returns true when there is no student attempt' do
      allow(presenter).to receive(:student_attempts).and_return([])

      expect(presenter).to have_nothing_to_grade
    end
  end

  describe '#student_attempts' do
    it 'returns the attempts for the students to grade and students graded' do
      attempt = build_stubbed(:attempt, :user => student, :activity => activity)
      allow(presenter).to receive(:students).and_return([student])

      expect(Attempt).to receive(:find_submitted_attempts_for_activity_and_students).with([section], [student], activity, true).and_return([attempt])
      expect(presenter.student_attempts).to eql [attempt]
    end
  end

  describe '#student_attempt' do
    it 'returns an attempt for a student' do
      attempt = create(:attempt)
      allow(presenter).to receive(:student_attempts).and_return({ student.id.to_s => attempt })
      expect(presenter.student_attempt(student)).to eql attempt
    end

    context 'when the student attempt is not found' do
      before do
        allow(presenter).to receive(:student_attempts).and_return({})
        allow(VHLMonitor).to receive(:error)
      end

      it 'returns nil' do
        expect(presenter.student_attempt(student)).to be_nil
      end

      it 'logs an error' do
        presenter.student_attempt(student)

        expect(VHLMonitor).to have_received(:error).with(
          'Student attempt not found',
          student_id: student.id,
          available_attempts: [],
          sections: [section.id],
        )
      end
    end
  end

  describe '#has_student_attachment?' do
    let(:question){ double('Question', :label => 'question_1') }
    let(:partner){ create(:student) }
    let(:response){ double('Response', :user_id => student.id, :partner_id => partner.id) }
    let(:attempt){ double('Attempt', :results => [{ :response => response }]) }

    before do
      allow(attempt).to receive(:attachment_for).and_return(true)
    end

    it 'returns true if the student has an attachment in a composition question' do
      question = MaestroActivityEngine::ActivityContent::Composition::Item.new(rank: 1)
      expect(presenter).to receive(:student_attempt).with(student).and_return(attempt)
      allow(presenter).to receive(:students).and_return([student])
      expect(presenter.has_student_attachment?(student, question)).to eql true
    end

    it 'returns false if the student not has an attachment' do
      question = MaestroActivityEngine::ActivityContent::Composition::Item.new(rank: 1)
      allow(attempt).to receive(:attachment_for).and_return(false)
      expect(presenter).to receive(:student_attempt).with(student).and_return(attempt)
      allow(presenter).to receive(:students).and_return([student])
      expect(presenter.has_student_attachment?(student, question)).to eql false
    end

    it 'returns false if the student has an attachment and the question is not composition' do
      allow(presenter).to receive(:students).and_return([student])
      expect(presenter.has_student_attachment?(student, question)).to eql false
    end
  end

  describe '#students' do
    it 'returns an array of the students to grade plus the students graded' do
      other_student = create(:student)
      allow(presenter).to receive(:students_to_grade).and_return([student])
      allow(presenter).to receive(:students_graded).and_return([other_student])
      expect(presenter.students).to match_array([student, other_student])
    end
  end

  describe '#students_to_submit' do
    let(:teammate) { create(:student) }

    before do
      allow(presenter).to receive(:students).and_return([student])
    end

    it 'returns students to grade and students graded' do
      expect(presenter.students_to_submit).to eql [student]
    end

    context 'when activity is a partner chat' do
      before do
        activity.activity_type = 'partner_chat'
        allow(PartnerChatPresenter).to receive(:new)
          .and_return(instance_double(PartnerChatPresenter))

        allow(presenter).to receive_messages(
          questions_to_grade: [question],
          add_attempt_section_when_missing: nil,
          teammate_attempt: nil,
          partner_chat_responses: nil
        )

        allow(presenter).to receive(:teammate_id).with(student).and_return(teammate.id)

        presenter.prepare
      end

      it 'returns students to grade, students graded, and teammates' do
        expect(presenter.students_to_submit).to contain_exactly(student, teammate)
      end
    end
  end

  describe '#students_graded' do
    let(:question) { double('Question', :label => 'question_1') }
    let(:feedback) { double('GradingFeedback') }

    it 'returns the students that already have scores' do
      expect(feedback).to receive(:question_points).with(student, question.label).and_return(10)
      allow(presenter).to receive(:students_to_grade).and_return([student])
      allow(presenter).to receive(:questions_to_grade).and_return([question])
      allow(presenter).to receive(:feedback).and_return(feedback)
      presenter.prepare

      expect(presenter.students_graded).to eql [student]
      expect(presenter.students_to_grade).to eql []
    end

    it 'does not return students that have not been graded' do
      allow(presenter).to receive(:students_to_grade).and_return([student])
      allow(presenter).to receive(:questions_to_grade).and_return([question])
      allow(presenter).to receive(:feedback).and_return(feedback)
      expect(feedback).to receive(:question_points).with(student, question.label).and_return(nil)
      presenter.prepare

      expect(presenter.students_graded).to eql []
      expect(presenter.students_to_grade).to eql [student]
    end
  end

  describe '#teammate' do
    let(:activity) do
      create(:activity, activity_type: 'partner_chat')
    end
    let(:question) do
      instance_double('Question', label: 'question_1')
    end
    let(:grading_set) do
      instance_double('GradingSet', activity: activity, students_to_grade: [student])
    end
    let(:presenter) do
      described_class.new(
        instructor,
        grading_set,
        program,
        [], {},
        show_auto_graded_questions
      )
    end

    before do
      allow(presenter).to receive(:questions_to_grade).and_return([question])
    end

    context 'when the student recorded partner chat' do
      let(:partner) { create(:student) }
      let(:response) do
        instance_double(
          'PartnerChatResponse',
          user: student,
          partner: partner,
          user_id: student.id,
          partner_id: partner.id,
          partner_practice: true
        )
      end
      let(:attempt) do
        instance_double(
          Attempt,
          results: [{ response: response }]
        )
      end

      before do
        allow(presenter).to receive(:student_attempt).and_return(attempt)
        allow(presenter).to receive(:add_attempt_section_when_missing)
      end

      it 'returns the partner that the student recorded with' do
        allow(presenter).to receive(:teammate_attempt).and_return(
          build_stubbed(:attempt)
        )
        presenter.prepare

        expect(presenter.teammate(student)).to eql partner
      end

      it 'returns the partner when the partner has no attempt' do
        # This happens when the partner has been transfered to a section in a
        # different course
        allow(presenter).to receive(:teammate_attempt).and_return(nil)
        presenter.prepare

        expect(presenter.teammate(student)).to eql(partner)
      end
    end
  end

  describe '#teammate_attempts' do
    let(:activity) do
      create(:activity, activity_type: 'partner_chat')
    end
    let(:question) do
      instance_double('Question', label: 'question_1')
    end
    let(:grading_set) do
      instance_double('GradingSet', activity: activity, students_to_grade: [student])
    end
    let(:presenter) do
      described_class.new(
        instructor,
        grading_set,
        program,
        [], {},
        show_auto_graded_questions
      )
    end

    before do
      allow(presenter).to receive(:questions_to_grade).and_return([question])
    end

    context 'when the student recorded partner chat' do
      let(:partner) { create(:student) }
      let(:response) do
        instance_double(
          'PartnerChatResponse',
          user: student,
          partner: partner,
          user_id: student.id,
          partner_id: partner.id,
          partner_practice: true
        )
      end
      let(:attempt) do
        instance_double(
          Attempt,
          results: [{ response: response }]
        )
      end

      before do
        allow(presenter).to receive(:student_attempt).and_return(attempt)
        allow(presenter).to receive(:add_attempt_section_when_missing)
      end

      it "returns the partner's attempt that the student recorded with" do
        attempt = build_stubbed(:attempt)
        allow(presenter).to receive(:teammate_attempt).and_return(attempt)
        presenter.prepare

        expect(presenter.teammate_attempts[partner]).to eq(attempt)
      end

      it 'returns nil when the partner has no attempt' do
        # This happens when the partner has been transfered to a section in a
        # different course
        allow(presenter).to receive(:teammate_attempt).and_return(nil)
        presenter.prepare

        expect(presenter.teammate_attempts[partner]).to be_nil
      end
    end
  end

  describe "#original_partner?" do
    let(:user) { build_stubbed(:user) }
    let(:other_user) { build_stubbed(:user) }

    it "returns true when the student is the original partner for a partner chat activity" do
      expect(presenter).to receive(:original_partner).with(user).and_return(user)
      expect(presenter.original_partner?(user)).to be_truthy
    end

    it "returns false when the student is not the original partner for a partner chat activity" do
      expect(presenter).to receive(:original_partner).with(user).and_return(other_user)
      expect(presenter.original_partner?(user)).to be_falsey
    end
  end

  describe "#original_user_in_grading_set?" do
    let(:user) { build_stubbed(:user) }
    let(:partner) { build_stubbed(:user) }
    let(:question) { double('Question', :label => 'question_1') }
    let(:grading_set){ double('GradingSet',
                            :activity => activity,
                            :students_to_grade => [user]) }

    before do
      allow(GradingFeedback).to receive(:new).and_return(grading_feedback)
      allow(presenter).to receive(:questions_to_grade).and_return([question])
    end

    it "returns true when the partner chat original user is in the students to grade list" do
      allow(grading_feedback).to receive(:question_points).and_return(nil)
      presenter.prepare
      expect(presenter).to receive(:original_user).with(user).and_return(user)
      expect(presenter.original_user_in_grading_set?(user)).to be_truthy
    end

    it "returns true when the partner chat original user is in the students graded list" do
      allow(grading_feedback).to receive(:question_points).and_return(1)
      presenter.prepare
      expect(presenter).to receive(:original_user).with(user).and_return(user)
      expect(presenter.original_user_in_grading_set?(user)).to be_truthy
    end

    it "returns false when the partner chat original user is not in the students graded list nor students to grade list" do
      other_user = build_stubbed(:user)
      allow(grading_feedback).to receive(:question_points).and_return(nil)
      presenter.prepare
      expect(presenter).to receive(:original_user).with(user).and_return(other_user)
      expect(presenter.original_user_in_grading_set?(user)).to be_falsey
    end
  end

  describe "#filter_students" do
    let(:user) { build_stubbed(:user) }
    let(:partner) { build_stubbed(:user) }
    let(:question) { double('Question', :label => 'question_1') }

    before do
      allow(GradingFeedback).to receive(:new).and_return(grading_feedback)
      allow(grading_feedback).to receive(:question_points).and_return(nil)
    end

    describe "when the grading set contains two students who did a partner chat together" do
      it "removes the partner from the grading set" do
        grading_set = double('GradingSet',
                           :activity => activity,
                           :students_to_grade => [user, partner])
        presenter = QuestionByQuestionPresenter.new(instructor,
                                                    grading_set,
                                                    program,
                                                    [], {},
                                                    show_auto_graded_questions)
        allow(presenter).to receive(:questions_to_grade).and_return([question])
        presenter.prepare
        allow(presenter).to receive(:original_partner?).with(user).and_return(false)
        allow(presenter).to receive(:original_partner?).with(partner).and_return(true)
        allow(presenter).to receive(:original_user_in_grading_set?).and_return(true)
        presenter.filter_students
        expect(presenter.students_to_grade).to match_array([user])
      end
    end

    describe "when the grading set contains a student but not their partner chat collaborator" do
      it "does not remove the student from the grading set" do
        grading_set = double('GradingSet',
                           :activity => activity,
                           :students_to_grade => [partner])
        presenter = QuestionByQuestionPresenter.new(instructor,
                                                    grading_set,
                                                    program,
                                                    [], {},
                                                    show_auto_graded_questions)
        allow(presenter).to receive(:questions_to_grade).and_return([question])
        presenter.prepare
        allow(presenter).to receive(:original_partner?).with(partner).and_return(true)
        allow(presenter).to receive(:original_user_in_grading_set?).and_return(false)
        presenter.filter_students
        expect(presenter.students_to_grade).to eql [partner]
      end
    end
  end

  describe "#questions_to_grade" do
    context 'when activity is not of type true false enhanced' do
      let(:auto_graded_question){ double('MaestroActivityEngine::ActivityContent::FillInTheBlanks::Item') }
      let(:open_ended_question){ double('MaestroActivityEngine::ActivityContent::OpenEnded::Item') }

      before do
        allow(activity).to receive(:questions).and_return([auto_graded_question, open_ended_question])
        allow(presenter).to receive(:auto_graded_question?).with(auto_graded_question).and_return(true)
        allow(presenter).to receive(:auto_graded_question?).with(open_ended_question).and_return(false)
      end

      context "when show auto graded questions is true" do
        it "returns all questions for the activity including auto graded questions" do
          allow(presenter).to receive(:show_auto_graded_questions?) { true }
          expect(presenter.questions_to_grade).to match_array [auto_graded_question, open_ended_question]
        end
      end

      context "when show auto graded questions is false " do
        it "returns only instructor graded questions" do
          allow(presenter).to receive(:show_auto_graded_questions?) { false }
          expect(presenter.questions_to_grade).to match_array [open_ended_question]
        end
      end
    end

    context 'when activity is of type true false enhanced' do
      let(:student_2) { build_stubbed(:student) }
      let(:student_1_attempt) { double('Attempt') }
      let(:student_2_attempt) { double('Attempt') }
      let(:results_1) { double('Results') }
      let(:results_2) { double('Results') }
      let(:question_1) { double('TrueFalseEnhanced::Item', label: 'question_1') }
      let(:question_2) { double('TrueFalseEnhanced::Item', label: 'question_2') }

      before do
        allow(activity).to receive(:true_false_enhanced?) { true }
        allow(activity).to receive(:questions) { [question_1, question_2] }
        allow(presenter).to receive(:students) { [student, student_2] }
        allow(presenter).to receive(:student_attempt).with(student) { student_1_attempt }
        allow(presenter).to receive(:student_attempt).with(student_2) { student_2_attempt }
        allow(student_1_attempt).to receive(:results) { results_1 }
        allow(student_2_attempt).to receive(:results) { results_2 }
        allow(results_1).to receive(:correctness).with(question_1.label) { 'pending' }
        allow(results_1).to receive(:correctness).with(question_2.label) { 'correct' }
        allow(results_2).to receive(:correctness).with(question_1.label) { 'correct' }
      end

      it "returns answered questions that have not been graded" do
        allow(results_2).to receive(:correctness).with(question_2.label) { 'pending' }

        expect(presenter.questions_to_grade).to eq [question_1, question_2]
      end

      it "does not return answered questions that have been graded" do
        allow(results_2).to receive(:correctness).with(question_2.label) { 'correct' }

        expect(presenter.questions_to_grade).to eq [question_1]
      end
    end
  end

  describe '#render_student_response_for_question?' do
    it 'returns true for recording questions' do
      recording_question = MaestroActivityEngine::ActivityContent::Recording::Question.new
      allow(presenter).to receive(:current_question).and_return(recording_question)
      expect(presenter.render_student_response_for_question?).to be true
    end

    it 'returns true for open ended questions' do
      oe_question = MaestroActivityEngine::ActivityContent::OpenEnded::Item.new
      allow(presenter).to receive(:current_question).and_return(oe_question)
      expect(presenter.render_student_response_for_question?).to be true
    end

    it 'returns true for smartbook responses' do
      smartbook_response = Smartbook::Response.new('foo')
      allow(presenter).to receive(:current_question).and_return(smartbook_response)
      expect(presenter.render_student_response_for_question?).to be true
    end

    it 'returns false for other question types' do
      other_question_type = instance_double('Something')
      allow(presenter).to receive(:current_question).and_return(other_question_type)
      expect(presenter.render_student_response_for_question?).to be false
    end
  end

  describe '#has_rubric?' do
    it 'returns false' do
      expect(presenter.has_rubric?).to eq(false)
    end
  end
end
