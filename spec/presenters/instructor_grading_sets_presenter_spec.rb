describe InstructorGradingSetsPresenter do
  let(:instructor) { build_stubbed(:instructor) }
  let(:student_1) { create(:student) }
  let(:program) { build_stubbed(:program) }
  let(:activity) { build_stubbed(:activity) }
  let(:grading_set) { double('GradingSet', activity:, students_to_grade: []) }
  let(:show_auto_graded_questions) { '1' }
  let(:presenter) do
    described_class.new(
      instructor,
      grading_set,
      program,
      [],
      {},
      show_auto_graded_questions,
    )
  end

  describe '#activity' do
    it 'returns the activity for the grading set' do
      expect(presenter.activity).to eql activity
    end
  end

  describe '#show_auto_graded_questions?' do
    context 'when the activity (in the grading set) is an auto graded activity' do
      it 'returns true' do
        allow(presenter.activity).to receive(:auto_graded?).and_return(true)
        expect(presenter.show_auto_graded_questions?).to be_truthy
      end
    end

    context 'when the activity is not an auto graded activity' do
      context "when the instructor has set the show auto graded questions setting to '1'" do
        it 'returns true' do
          expect(presenter.show_auto_graded_questions?).to be_truthy
        end
      end

      context "when the instructor has set the show auto graded setting to '0'" do
        let(:presenter) do
          described_class.new(instructor, grading_set, program, [], {}, '0')
        end

        it 'returns false' do
          expect(presenter.show_auto_graded_questions?).to be_falsey
        end
      end
    end
  end

  describe '#done_early?' do
    let(:presenter) do
      described_class.new(
        instructor,
        grading_set,
        program,
        [],
        params,
        show_auto_graded_questions
      )
    end

    context 'when grading is done and the user is not jumping to a grading set item' do
      let(:params) { { commit: 'Done', jump_to: nil } }

      it 'returns true' do
        expect(presenter.done_early?).to be_truthy
      end
    end

    context 'when grading is not done' do
      let(:params) { { commit: 'Next', jump_to: nil } }

      it 'returns false' do
        expect(presenter.done_early?).to be_falsey
      end
    end

    context 'when the user is jumping to a grading set item' do
      let(:params) { { commit: 'Done', jump_to: 'grading_set_item_1' } }

      it 'returns false' do
        expect(presenter.done_early?).to be_falsey
      end
    end
  end

  describe '#get_grading_list_element' do
    let(:grading_list) { %w[item_1 item_2] }

    context 'when moving to the next grading set item' do
      let(:presenter) do
        described_class.new(
          instructor,
          grading_set,
          program,
          [],
          { commit: 'Save & Next >' },
          show_auto_graded_questions
        )
      end

      it 'returns the next grading set item' do
        current_index = 0
        expect(presenter.get_grading_list_element(grading_list, grading_list[current_index],
                                                  nil)).to eql grading_list[current_index + 1]
      end

      it 'returns :no_next_element_found if there is no next item' do
        current_index = 1
        expect(presenter.get_grading_list_element(grading_list, grading_list[current_index],
                                                  nil)).to eql :no_next_element_found
      end
    end

    context 'when moving to the previous grading set item' do
      it 'returns the previous grading set item' do
        presenter = described_class.new(
          instructor,
          grading_set,
          program,
          [],
          { commit: '< Save & Previous' },
          show_auto_graded_questions
        )
        current_index = 1
        expect(presenter.get_grading_list_element(grading_list, grading_list[current_index],
                                                  nil)).to eql grading_list[current_index - 1]
      end
    end
  end

  describe '#students_submitted_multiple_versions?' do
    it 'returns true if students have submitted multiple versions of an activity' do
      attempt = build_stubbed(:attempt, cms_revision_id: 1)
      other_attempt = build_stubbed(:attempt, cms_revision_id: 2)
      allow(presenter).to receive(:student_attempts).and_return({ '1' => attempt,
                                                                  '2' => other_attempt })
      expect(presenter.students_submitted_multiple_versions?).to be_truthy
    end
  end

  describe '#students_to_grade' do
    it 'returns array of students that have to be graded' do
      allow(grading_set).to receive(:students_to_grade).and_return([student_1])
      expect(presenter.students_to_grade).to eql [student_1]
    end
  end

  describe '#disable_controls?' do
    it 'returns true when the activity is a partner chat' do
      activity.activity_type = 'partner_chat'
      expect(presenter.disable_controls?).to be_truthy
    end

    it 'returns true when the activity is a recording v2' do
      activity.activity_type = 'recording_v2'
      expect(presenter.disable_controls?).to be_truthy
    end

    it 'returns false when the activity is not a partner chat or recording v2' do
      activity.activity_type = 'not_partner_chat_or_recording'
      expect(presenter.disable_controls?).to be_falsey
    end
  end

  describe '#results_by_response_id' do
    it "creates a hash consisting of the score for each question by a student, as stored in the results. (e.g. {'question_01_student_35' => 2.0 })" do
      allow(presenter).to receive(:student_attempts).and_return({ 'student_id' => double(
        'Attempt', results: double('Results', points_earned: 3)
      ) })
      allow(presenter).to receive(:questions_to_grade).and_return([double('Question',
                                                                          label: 'question_label')])
      expect(presenter.results_by_response_id).to eq({ 'question_label_student_student_id' => 3.0 })
    end
  end

  describe '#add_attempt_section_when_missing' do
    let(:section) { build_stubbed(:section) }
    let(:attempt) { build_stubbed(:attempt, section:) }

    describe "when the attempt's section is not in the sections list" do
      it "adds the attempt's section to the sections list" do
        presenter.add_attempt_section_when_missing(attempt)
        expect(presenter.sections).to eql [attempt.section]
      end
    end

    describe "when the attempt's section is in the sections list" do
      it 'the sections list is unchanged' do
        allow(presenter).to receive(:sections).and_return([section])
        presenter.add_attempt_section_when_missing(attempt)
        expect(presenter.sections).to eql [section]
      end
    end
  end

  describe '#gradeable?' do
    let(:section) { build_stubbed(:section) }
    let(:attempt) { build_stubbed(:attempt, section:) }
    let(:student) { build_stubbed(:user) }

    before do
      allow(presenter).to receive(:student_attempts).and_return({ student.id.to_s => attempt })
    end

    it "returns true when the attempt's section is a section that the instructor can access" do
      allow(instructor).to receive(:gradeable_sections).and_return([section])
      expect(presenter.gradeable?(student)).to be_truthy
    end

    it "returns false when the attempt's section is a section that the instructor cannot access" do
      expect(presenter.gradeable?(student)).to be_falsey
    end

    context 'when there is no attempt for the student' do
      before do
        allow(presenter).to receive(:student_attempts).and_return({})
      end

      it 'returns false if there is no teammate attempt for the student' do
        allow(presenter).to receive(:teammate_attempts).and_return({})

        expect(presenter.gradeable?(student)).to be_falsey
      end

      context 'when a teammate attempt exists for the student' do
        before do
          allow(presenter).to receive(:teammate_attempts).and_return(
            student => attempt
          )
        end

        it "returns true when the teammate attempt's section is a section that " \
           'the instructor can access' do
          allow(instructor).to receive(:gradeable_sections).and_return([section])

          expect(presenter.gradeable?(student)).to be_truthy
        end

        it "returns false when the teammate attempt's section is a section that " \
           'the instructor cannot access' do
          expect(presenter.gradeable?(student)).to be_falsey
        end
      end
    end
  end

  describe '#show_auto_graded_questions?' do
    it "returns true when show auto graded questions setting is '1'" do
      expect(presenter.show_auto_graded_questions?).to be_truthy
    end

    it "returns false when show auto graded questions setting is '0'" do
      presenter = described_class.new(instructor, grading_set, program, [], {}, '0')
      expect(presenter.show_auto_graded_questions?).to be_falsey
    end
  end

  describe '#question_pending?' do
    let(:presenter) do
      described_class.new(instructor, grading_set, program, [], {}, '0')
    end
    let(:results) { double('Results') }
    let(:attempt) { double('Attempt', results:) }

    context 'when given question has pending correctness' do
      it 'returnsa true' do
        allow(results).to receive(:correctness).and_return('pending')
        expect(presenter.question_pending?('question_01', attempt)).to be_truthy
      end
    end

    context 'when given question does not have pending correctness' do
      it 'returnsa true' do
        allow(results).to receive(:correctness).and_return('correct')
        expect(presenter.question_pending?('question_01', attempt)).to be_falsey
      end
    end
  end

  describe '#activity_questions' do
    let(:activity_questions) { ['question 1', 'question 2'] }

    before do
      allow(activity).to receive(:questions).and_return(activity_questions)
    end

    it 'returns the activity questions' do
      expect(presenter.activity_questions).to eq(activity_questions)
    end

    context 'when the activity is a smartbook' do
      let(:activity) { build_stubbed(:activity, activity_type: 'smart_book') }
      let(:attempt_1) { build_stubbed(:attempt, cms_revision_id: 1) }
      let(:attempt_2) { build_stubbed(:attempt, cms_revision_id: 2) }
      let(:attempt_1_smartbook_responses) { instance_double(Smartbook::Responses) }
      let(:attempt_2_smartbook_responses) { instance_double(Smartbook::Responses) }
      let(:attempt_1_question_1) do
        instance_double(Smartbook::Response, interaction_id: 'question 02')
      end
      let(:attempt_1_question_2) do
        instance_double(Smartbook::Response, interaction_id: 'question 01')
      end
      let(:attempt_2_question_1) do
        instance_double(Smartbook::Response, interaction_id: 'question 01')
      end
      let(:attempt_2_question_2) do
        instance_double(Smartbook::Response, interaction_id: 'question 03')
      end

      before do
        allow(presenter).to receive(:student_attempts).and_return(
          '1' => attempt_1, '2' => attempt_2
        )
        allow(attempt_1).to receive(:smartbook_responses)
          .and_return(attempt_1_smartbook_responses)
        allow(attempt_1_smartbook_responses).to receive(:answered)
          .and_return([attempt_1_question_1, attempt_1_question_2])
        allow(attempt_2).to receive(:smartbook_responses)
          .and_return(attempt_2_smartbook_responses)
        allow(attempt_2_smartbook_responses).to receive(:answered)
          .and_return([attempt_2_question_1, attempt_2_question_2])
        [
          attempt_1_question_1,
          attempt_1_question_2,
          attempt_2_question_1,
          attempt_2_question_2
        ].each do |response|
          allow(response).to receive(:<=>) do |other|
            response.interaction_id <=> other.interaction_id
          end
        end
      end

      it 'returns all the interactions answered by at least ' \
         'one student and sorted' do
        expect(presenter.activity_questions).to eq([
                                                     attempt_1_question_2,
                                                     attempt_1_question_1,
                                                     attempt_2_question_2
                                                   ])
      end
    end
  end
end
