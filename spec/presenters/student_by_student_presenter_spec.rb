describe StudentByStudentPresenter do
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:students) { [student_1, student_2] }
  let(:course) { create(:course, owner: instructor) }
  let(:section) { create(:section, course: course) }
  let(:activity) { create(:activity) }
  let(:grading_set) do
    create(
      :grading_set,
      activity: activity,
      program: program,
      instructor: instructor,
      student_id_list: students.map(&:id).uniq.join(',')
    )
  end
  let!(:attempt_student_1) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student_1
    )
  end
  let!(:attempt_student_2) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student_2
    )
  end
  let(:show_auto_graded_questions) { '1' }
  let(:focus) { instance_double(Focus, sections: [section]) }
  let(:task_set) do
    instance_double(
      InstructorGradingTasksPresenter::GradingTaskSet,
      students_for_activity: students
    )
  end
  let(:grading_tasks_presenter) do
    instance_double(
      InstructorGradingTasksPresenter,
      task_set: task_set,
      current_task: nil
    )
  end
  let(:params) { {} }
  let(:presenter) do
    described_class.new(
      instructor,
      grading_set,
      program,
      [section],
      grading_tasks_presenter,
      params,
      show_auto_graded_questions
    )
  end

  before do
    create(:active_enrollment, section: section, user: student_1)
    create(:active_enrollment, section: section, user: student_2)
  end

  RSpec.shared_examples 'chat grading' do
    it 'sorts the students to grade' do
      presenter.prepare
      expect(chat_presenter).to have_received(:sort_students)
        .with([partner, student])
    end

    context 'when no student id is specified in the parameters,' do
      it 'sets current_student to the first student to grade' do
        expect(presenter.prepare.current_student).to eql student
      end

      it "sets teammate to the current student's partner" do
        expect(presenter.prepare.teammates.to_a).to eq [partner]
      end
    end

    context 'when a student id is specified,' do
      let(:params) { { student_id: student.id } }

      it 'sets current_student to the specified student' do
        expect(presenter.prepare.current_student).to eq(student)
      end

      it "sets teammate to the specified student's partner" do
        expect(presenter.prepare.teammates.to_a).to eq [partner]
      end
    end
  end

  describe 'when grading a partner chat activity' do
    let(:activity) { create(:activity, activity_type: 'partner_chat') }
    let(:student) { student_1 }
    let(:partner) { student_2 }
    let(:student_attempt) { attempt_student_1 }
    let(:partner_attempt) { attempt_student_2 }
    let(:student_response) do
      instance_double(
        PartnerChatRecording,
        user: student,
        partner: partner,
        user_id: student.id,
        partner_id: partner.id
      )
    end
    let(:partner_response) { student_response }
    let(:partner_chat_presenter) do
      instance_double(PartnerChatPresenter, sort_students: [])
    end

    before do
      allow(grading_set).to receive(:students_to_grade).and_return(
        [partner, student_1]
      )
      allow(student_attempt).to receive(:results).and_return(
        [
          { response: student_response }
        ]
      )
      allow(partner_attempt).to receive(:results).and_return(
        [
          { response: partner_response }
        ]
      )
      allow(presenter).to receive(:current_student_attempt).and_return(student_attempt)
      allow(PartnerChatPresenter).to receive(:new).and_return(partner_chat_presenter)
      allow(partner_chat_presenter).to receive(:sort_students)
        .and_return([student, partner])
      allow(presenter).to receive(:add_attempt_section_when_missing)

      allow(presenter).to receive(:student_attempts).and_return(
        student.id.to_s => student_attempt,
        partner.id.to_s => partner_attempt
      )
    end

    include_examples 'chat grading' do
      let(:chat_presenter) { partner_chat_presenter }
    end

    it 'creates a partner chat presenter' do
      presenter.prepare
      expect(PartnerChatPresenter).to have_received(:new)
        .with([student_response])
    end

    describe 'when the student has completed a partner chat with a student who is not in the grading set' do
      let(:students) { [student] }

      it 'builds the correct partner chat presenter' do
        presenter.prepare
        expect(PartnerChatPresenter).to have_received(:new)
          .with([student_response])
      end
    end
  end

  describe 'when grading a group chat activity' do
    let(:student) { student_1 }
    let(:partner) { student_2 }
    let(:student_attempt) { attempt_student_1 }
    let(:partner_attempt) { attempt_student_2 }
    let(:student_response) do
      instance_double(
        GroupChatRecording,
        activity: activity,
        participants: [partner.id],
        partner_users: { partner.id => partner },
        user: student,
        user_id: student.id
      )
    end
    let(:partner_response) { student_response }
    let(:activity) { create(:group_chat_activity) }
    let(:group_chat_presenter) do
      instance_double(GroupChatPresenter, sort_students: [student, partner])
    end

    before do
      allow(student_attempt).to receive(:results).and_return([response: student_response])
      allow(partner_attempt).to receive(:results).and_return([response: partner_response])
      allow(presenter).to receive(:student_attempts).and_return(
        student.id.to_s => student_attempt,
        partner.id.to_s => partner_attempt
      )
      allow(grading_set).to receive(:students_to_grade).and_return([partner, student])
      allow(presenter).to receive(:current_student_attempt).and_return(student_attempt)
      allow(GroupChatPresenter).to receive(:new).and_return(group_chat_presenter)
    end

    include_examples 'chat grading' do
      let(:chat_presenter) { group_chat_presenter }
    end

    it 'creates a group chat presenter' do
      presenter.prepare
      expect(GroupChatPresenter).to have_received(:new)
        .with([student_response])
    end

    context 'when a chat partner is in a different section of the same course' do
      let(:other_section_same_course) { create(:section, course:) }

      before do
        create(:active_enrollment, section: other_section_same_course, user: partner)
        partner_attempt.update!(section: other_section_same_course)
      end

      it 'includes the partner attempt in the result' do
        result = presenter.prepare.teammate_attempts

        expect(result).to eq({ partner => partner_attempt })
      end
    end

    context 'when a chat partner is in a different course' do
      let(:other_section) { create(:section, course: create(:course)) }

      before do
        partner_attempt.update!(section: other_section)
      end

      it 'excludes the partner attempt from the result' do
        result = presenter.prepare.teammate_attempts

        expect(result[partner]).to be_nil
      end
    end

    context 'when there are multiple group chat partners' do
      let(:student_3) { create(:student) }
      let!(:student_3_attempt) do
        create(
          :attempt_submitted,
          activity: activity,
          section:,
          user: student_3
        )
      end

      before do
        allow(student_response).to receive(:partner_users).and_return(
          {
            partner.id => partner,
            student_3.id => student_3
          }
        )
      end

      it 'includes all partner attempts in the result' do
        result = presenter.prepare.teammate_attempts

        expect(result).to eq(
          {
            partner => partner_attempt,
            student_3 => student_3_attempt
          }
        )
      end
    end
  end

  describe '#current_student' do
    it 'returns the current student to grade' do
      expect(presenter.prepare.current_student).to eq(student_1)
    end

    context 'when a student id is specified,' do
      let(:params) { { student_id: student_2.id } }

      it 'returns the specified student' do
        expect(presenter.prepare.current_student).to eq(student_2)
      end
    end

    context 'when there is no student to grade,' do
      let(:students) { [] }

      it 'returns nil' do
        expect(presenter.prepare.current_student).to be_nil
      end
    end
  end

  describe '#composition_attachment' do
    it 'when activity type = composition assigns a composition attachment when there is an attachment related to the activity and user' do
      allow(activity).to receive(:activity_type).and_return('composition')
      composition_attachment = build_stubbed(:composition_attachment)
      allow(CompositionAttachment).to receive(:find_by_user_id_and_activity_id).and_return(composition_attachment)
      expect(composition_attachment).to eql composition_attachment
    end
  end

  describe '#current_student_attempt' do
    it 'returns the attempt for current student to grade' do
      expect(presenter.prepare.current_student_attempt).to eq(attempt_student_1)
    end

    context 'when a student id is specified,' do
      let(:params) { { student_id: student_2.id } }

      it 'returns the attempt for the specified student' do
        expect(presenter.prepare.current_student_attempt).to eq(attempt_student_2)
      end
    end

    context 'when there is no student to grade,' do
      let(:students) { [] }

      it 'returns nil' do
        expect(presenter.prepare.current_student_attempt).to be_nil
      end
    end
  end

  describe '#done?' do
    context 'when there is no more student,' do
      it 'reurns true' do
        expect(presenter).to be_done
      end
    end

    context 'when there is more student,' do
      context 'when grading is done and the user is not jumping to a grading set item' do
        let(:params) { { commit: 'Done', jump_to: nil } }

        it 'returns true' do
          expect(presenter).to be_done
        end
      end

      context 'when grading is not done' do
        let(:params) { { commit: 'Save & Next >', jump_to: nil } }

        it 'returns false' do
          expect(presenter).not_to be_done
        end
      end

      context 'when the user is jumping to a grading set item' do
        let(:params) { { commit: 'Done', jump_to: student_2.id.to_s } }

        it 'returns false' do
          expect(presenter).not_to be_done
        end
      end
    end
  end

  describe '#grading_status' do
    it 'returns the grading status of students' do
      allow(grading_set).to receive(:grading_status_of_students)
        .with(activity, [section])
        .and_return('valid grading status')

      expect(presenter.prepare.grading_status).to eql 'valid grading status'
    end
  end

  describe '#instructor_feedback' do
    let(:grading_feedback) { instance_double(GradingFeedback) }

    before do
      allow(GradingFeedback).to receive(:new).with(
        activity: activity,
        questions: anything,
        students: [student_1],
        sections: [section]
      ).and_return(grading_feedback)
    end

    context 'when the instructor has entered feedback for the current student' do
      it 'returns the feedback item' do
        feedback = 'feedback'
        allow(grading_feedback).to receive(:general_feedback).and_return(feedback)

        expect(presenter.prepare.instructor_feedback).to eq(feedback)
      end
    end

    context 'when the instructor has not entered feedback for the current student' do
      it 'returns nil' do
        allow(grading_feedback).to receive(:general_feedback).and_return(nil)

        expect(presenter.prepare.instructor_feedback).to be_nil
      end
    end
  end

  describe '#last_item?' do
    context 'when current student is the last student to grade and the ' \
      'instructor is finishing their grading' do
      let(:params) do
        { student_id: student_2.id.to_s, commit: 'Done', jump_to: nil }
      end

      it 'returns true' do
        expect(presenter.prepare.last_item?).to be_truthy
      end
    end

    context 'when the current student is not the last student to grade' do
      let(:params) do
        { student_id: student_1.id.to_s, commit: 'Done', jump_to: nil }
      end

      it 'returns false' do
        expect(presenter.prepare.last_item?).to be_falsey
      end
    end

    context 'when the instructor is moving to the previous student to grade' do
      let(:params) do
        { commit: '< Save & Previous', jump_to: nil }
      end

      it 'returns false' do
        expect(presenter.prepare.last_item?).to be_falsey
      end
    end

    context 'when the instructor is jumping to another student to grade' do
      let(:params) do
        { student_id: student_2.id.to_s, commit: 'Done', jump_to: student_1.id.to_s }
      end

      it 'returns false' do
        expect(presenter.prepare.last_item?).to be_falsey
      end
    end
  end

  describe '#next_element' do
    let(:params) do
      { student_id: student_1.id.to_s, jump_to: student_2.id.to_s }
    end

    it 'returns a hash containing the id of the next student' do
      expect(presenter.prepare.next_element).to eq(student_id: student_2.id)
    end
  end

  describe '#student_attempts' do
    it 'returns the attempts for the students to grade' do
      expect(presenter.prepare.student_attempts).to eq(
        student_1.id.to_s => attempt_student_1,
        student_2.id.to_s => attempt_student_2
      )
    end
  end

  describe '#teammate' do
    context 'when the activity is a partner chat,' do
      let(:activity) { create(:activity, activity_type: 'partner_chat') }

      before do
        allow(presenter).to receive(:student_attempts).and_return(
          student_1.id.to_s => attempt_student_1,
          student_2.id.to_s => attempt_student_2
        )
      end

      it 'returns the partner of the current student' do
        partner_chat_presenter = instance_double(PartnerChatPresenter)
        allow(PartnerChatPresenter).to receive(:new).and_return(partner_chat_presenter)
        expect(partner_chat_presenter).to receive(:sort_students).and_return(
          [student_1, student_2]
        )
        student_1_partner = create(:student)
        student_2_partner = create(:student)
        student_1_response = instance_double(
          PartnerChatRecording,
          user: student_1,
          partner: student_1_partner,
          user_id: student_1.id,
          partner_id: student_1_partner.id
        )
        student_2_response = instance_double(
          PartnerChatRecording,
          user: student_2,
          partner: student_2_partner,
          user_id: student_2.id,
          partner_id: student_2_partner.id
        )
        allow(attempt_student_1).to receive(:results).and_return(
          [
            { response: student_1_response }
          ]
        )
        allow(attempt_student_2).to receive(:results).and_return(
          [
            { response: student_2_response }
          ]
        )
        allow(presenter).to receive(:add_attempt_section_when_missing)
        expect(presenter.prepare.teammates).to eq [student_1_partner]
      end
    end

    context 'when the activity is not a partner chat,' do
      let(:activity) { create(:activity, activity_type: 'open_ended') }

      it 'returns nil' do
        expect(presenter.prepare.teammates).to eq []
      end
    end
  end

  describe '#teammate_attempts' do
    context 'when the activity is a partner chat,' do
      let(:activity) { create(:activity, activity_type: 'partner_chat') }
      let(:partner_chat_presenter) { instance_double(PartnerChatPresenter) }
      let(:student_1_partner) { create(:student) }
      let(:student_1_partner_attempt) { create(:attempt) }
      let(:student_2_partner) { create(:student) }
      let(:student_2_partner_attempt) { create(:attempt) }
      let(:student_1_response) do
        instance_double(
          PartnerChatRecording,
          user: student_1,
          partner: student_1_partner,
          user_id: student_1.id,
          partner_id: student_1_partner.id
        )
      end
      let(:student_2_response) do
        instance_double(
          PartnerChatRecording,
          user: student_2,
          partner: student_2_partner,
          user_id: student_2.id,
          partner_id: student_2_partner.id
        )
      end

      before do
        allow(presenter).to receive(:student_attempts).and_return(
          student_1.id.to_s => attempt_student_1,
          student_2.id.to_s => attempt_student_2
        )
        allow(PartnerChatPresenter).to receive(:new).and_return(partner_chat_presenter)
        allow(partner_chat_presenter).to receive(:sort_students).and_return(
          [student_1, student_2]
        )
        allow(attempt_student_1).to receive(:results).and_return(
          [
            { response: student_1_response }
          ]
        )
        allow(attempt_student_2).to receive(:results).and_return(
          [
            { response: student_2_response }
          ]
        )
        allow(presenter).to receive(:add_attempt_section_when_missing)
      end

      it "returns the partner's attempt of the current student" do
        allow(presenter).to receive(:teammate_attempt)
          .with([student_1_partner], attempt_student_1, activity)
          .and_return(student_1_partner_attempt)
        allow(presenter).to receive(:teammate_attempt)
          .with([student_2_partner], attempt_student_2, activity)
          .and_return(student_2_partner_attempt)

        expect(presenter.prepare.teammate_attempts).to eq(
          student_1_partner => student_1_partner_attempt
        )
      end

      it 'returns an empty hash when the partner of the current student has ' \
         'no attempt' do
        # This happens when the partner has been transfered to a section in a
        # different course
        allow(presenter).to receive(:teammate_attempt)
          .with([student_1_partner], attempt_student_1, activity)
          .and_return(nil)
        allow(presenter).to receive(:teammate_attempt)
          .with([student_2_partner], attempt_student_2, activity)
          .and_return(student_2_partner_attempt)

        expect(presenter.prepare.teammate_attempts).to eq({})
      end
    end

    context 'when the activity is not a partner chat,' do
      let(:activity) { create(:activity, activity_type: 'open_ended') }

      it 'returns nil' do
        expect(presenter.prepare.teammate_attempts).to be_nil
      end
    end
  end

  describe '#multi_type_activity_view_manager' do
    it 'returns a multi type activity view manager' do
      view_manager = instance_double(MultiTypeActivityViewManager)
      allow(MultiTypeActivityViewManager).to receive(:new)
        .with(presenter)
        .and_return(view_manager)

      expect(presenter.prepare.multi_type_activity_view_manager).to eq(view_manager)
    end
  end

  describe '#questions_to_grade' do
    it 'returns the instructor graded and auto graded questions for the activity' do
      questions = %w[question_1 question_2]
      allow(grading_set.activity).to receive(:questions).and_return(questions)

      expect(presenter.prepare.questions_to_grade).to eql questions
    end

    context 'when the activity is a smartbook,' do
      let(:activity) { create(:activity, activity_type: 'smart_book') }
      let(:question_1) do
        instance_double(
          Smartbook::Response,
          interaction_id: SecureRandom.uuid,
          question_number: 1
        )
      end
      let(:question_2) do
        instance_double(
          Smartbook::Response,
          interaction_id: SecureRandom.uuid,
          question_number: 2
        )
      end
      let(:question_3) do
        instance_double(
          Smartbook::Response,
          interaction_id: SecureRandom.uuid,
          question_number: 3
        )
      end
      let(:student_1_smartbook_responses) do
        instance_double(Smartbook::Responses, answered: [question_2, question_3])
      end
      let(:student_2_smartbook_responses) do
        instance_double(Smartbook::Responses, answered: [question_2, question_1])
      end

      before do
        allow(grading_set).to receive(:students_to_grade).and_return(
          [student_1, student_2]
        )
        allow(presenter).to receive(:student_attempts).and_return(
          student_1.id.to_s => attempt_student_1,
          student_2.id.to_s => attempt_student_2
        )
        allow(attempt_student_1).to receive(:smartbook_responses).and_return(
          student_1_smartbook_responses
        )
        allow(attempt_student_2).to receive(:smartbook_responses).and_return(
          student_2_smartbook_responses
        )
        allow(question_1).to receive(:<=>) do |other|
          question_1.question_number <=> other.question_number
        end
        allow(question_2).to receive(:<=>) do |other|
          question_2.question_number <=> other.question_number
        end
        allow(question_3).to receive(:<=>) do |other|
          question_3.question_number <=> other.question_number
        end
      end

      it 'returns all the questions answered by at least one student, sorted' do
        expect(presenter.prepare.questions_to_grade).to eq(
          [question_1, question_2, question_3]
        )
      end
    end
  end

  describe '#student_pending_question?' do
    let(:question_label) { 'question_01' }
    let(:student_results) do
      instance_double(MaestroActivityEngine::ActivityContent::Results)
    end

    before do
      allow(grading_set).to receive(:students_to_grade).and_return(
        [student_1, student_2]
      )
      allow(presenter).to receive(:student_attempts).and_return(
        student_1.id.to_s => attempt_student_1,
        student_2.id.to_s => attempt_student_2
      )
      allow(attempt_student_1).to receive(:results).and_return(
        student_results
      )
    end

    it 'returns true when the question has pending correction' do
      allow(student_results).to receive(:correctness).with(question_label)
        .and_return('pending')
      expect(presenter.prepare.student_pending_question?(question_label)).to be_truthy
    end

    it 'returns false when the question has no pending correction' do
      allow(student_results).to receive(:correctness).with(question_label)
        .and_return('incorrect')
      expect(presenter.prepare.student_pending_question?(question_label)).to be_falsey
    end
  end

  describe '#has_student_attachment_for?' do
    let(:question) do
      MaestroActivityEngine::ActivityContent::Composition::Item.new(rank: 1)
    end
    let(:attempt) { instance_double(Attempt) }

    before do
      allow(presenter).to receive(:current_student_attempt).and_return(attempt)
    end

    context 'when the activity has a composition question with an attachment' do
      let(:activity) { create(:activity, activity_type: 'composition') }

      it 'returns true when the activity has an attachment' do
        allow(attempt).to receive(:attachment_for).and_return(true)

        expect(presenter).to have_student_attachment_for(question)
      end

      it 'returns false when the activity has no attachment' do
        allow(attempt).to receive(:attachment_for).and_return(false)

        expect(presenter).not_to have_student_attachment_for(question)
      end
    end

    it 'returns false when the question is not a composition one' do
      allow(attempt).to receive(:attachment_for).and_return(true)
      question = MaestroActivityEngine::ActivityContent::OpenEnded::Item.new(rank: 1)

      expect(presenter).not_to have_student_attachment_for(question)
    end
  end

  describe '#format_rubric_link' do
    let(:expected_cms_revision_id) { Random.rand(1..30) }

    before do
      attempt_student_1.update!(cms_revision_id: expected_cms_revision_id)
    end

    it 'returns a link to the rubrics version of a given attempt' do
      result_link = presenter.format_rubric_link('View')
      result_link_element = Nokogiri::XML(result_link).at('a')
      result_url = result_link_element['href']
      expect(result_url).to eq "/sections/0/activities/#{activity.id}/rubric?cms_revision_id=#{expected_cms_revision_id}&from=grading"
    end

    describe 'optional icon parameter' do
      it "does not set an icon if the icon param is 'none'" do
        result_link = presenter.format_rubric_link('View', 'none')
        result_link_element = Nokogiri::XML(result_link).at('a')
        expect(result_link_element.inner_html).to eq 'View'
      end

      it 'allows a custom icon as param' do
        other_icon = Music::Components.icon(
          variant: 'edit',
          classes: 'u-txt-plain'
        )
        result_link = presenter.format_rubric_link('View', other_icon)
        result_link_element = Nokogiri::XML(result_link).at('a')
        expect(
          result_link_element.at_css('span.c-embedded-icon--edit')
        ).not_to be_nil
        expect(
          result_link_element.at_css('span.c-embedded-icon').count
        ).to eq 1
      end

      it 'sets a reference icon if the icon param is not given' do
        result_link = presenter.format_rubric_link('View')
        result_link_element = Nokogiri::XML(result_link).at('a')
        expect(
          result_link_element.at_css('span.c-embedded-icon--reference')
        ).not_to be_nil
        expect(
          result_link_element.at_css('span.c-embedded-icon').count
        ).to eq 1
      end
    end
  end
end
