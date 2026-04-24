describe QuestionByQuestionViewManager do
  let(:question) { double('Question').as_null_object }
  let(:presenter) do
    instance_double(
      QuestionByQuestionPresenter,
      current_question: question
    ).as_null_object
  end
  let(:activity) { double('Activity', sub_activities: []).as_null_object }
  let(:sub_activity) { double('SubActivity', items: [question]) }
  let(:other_question) { double('Question').as_null_object }
  let(:other_sub_activity) { double('SubActivity', items: [other_question]) }

  let(:view_manager) { described_class.new(presenter) }

  it_behaves_like 'an object that expects table activity questions'

  describe '#students' do
    let(:student_1) { create(:student) }
    let(:student_2) { create(:student) }
    let(:students) { [student_1, student_2] }

    before do
      allow(presenter).to receive(:students).and_return(students)
    end

    it 'return all the studentd' do
      expect(view_manager.students).to eq(students)
    end

    context 'when the question is a smartbook question,' do
      let(:question) { Smartbook::Response.new({}) }

      it 'only returns students that answered the question' do
        allow(question).to receive(:label).and_return('question_01')

        results_student_1 = instance_double(
          MaestroActivityEngine::ActivityContent::Results
        )
        allow(results_student_1).to receive(:has_response?)
          .with(question.label)
          .and_return(true)
        results_student_2 = instance_double(
          MaestroActivityEngine::ActivityContent::Results
        )
        allow(results_student_2).to receive(:has_response?)
          .with(question.label)
          .and_return(false)
        allow(view_manager).to receive(:results).with(student_1).and_return(
          results_student_1
        )
        allow(view_manager).to receive(:results).with(student_2).and_return(
          results_student_2
        )

        expect(view_manager.students).to eq([student_1])
      end
    end
  end

  describe "#language" do
    it "returns the language of the activity" do
      allow(presenter).to receive_message_chain(:activity, :content_object, :language).and_return('test language')
      expect(view_manager.language).to eql 'test language'
    end
  end

  describe "#currently_on_first_question?" do
    it "returns true if the current question is the first question in the grading set" do
      allow(presenter).to receive(:current_question).and_return(question)
      allow(presenter).to receive(:questions_to_grade).and_return([question, double('Question')])
      expect(view_manager.currently_on_first_question?).to be_truthy
    end
  end

  describe "#currently_on_last_question?" do
    it "returns true if the current question is the last question in the grading set" do
      allow(presenter).to receive(:current_question).and_return(question)
      allow(presenter).to receive(:questions_to_grade).and_return([double('Question'), question])
      expect(view_manager.currently_on_last_question?).to be_truthy
    end
  end

  describe 'html_friendly_prompt' do
    before do
      def question.html_friendly_prompt
        block_given? ? yield : ''
      end
    end

    context 'when the current question is in an instructor graded activity' do
      let(:instructor_graded_question) { double('Question') }

      it 'calls the html_friendly_prompt method in the plugin for its Item ' \
         'class, and it ignores the block given' do
        activity = instance_double(Activity, has_mixed_grading_method?: true)
        allow(presenter).to receive(:activity).and_return(activity)

        fake_object = double('FakeObject', test: nil)
        allow(view_manager).to receive(:question).and_return(
          instructor_graded_question
        )
        allow(instructor_graded_question).to receive(:html_friendly_prompt)
          .and_return('prompt')
        allow(fake_object).to receive(:test)

        expect(view_manager.html_friendly_prompt do |_formatter, *_args|
          fake_object.test
        end).to eq('prompt')

        expect(fake_object).not_to have_received(:test)
      end
    end

    context "when the current question is in a multi-type activity" do
      let(:diagnostic_activity_type) { 'diagnostic' }
      let(:diagnostic_reference) { double('DiagnosticReference') }
      let(:diagnostic_activity) { double('Activity', activity_type: diagnostic_activity_type,
                                                     diagnostic_reference: diagnostic_reference,
                                                     is_bonus: false) }

      context "when the current question is an open ended question" do
        let(:oe_reference) { double('OpenEndedReference') }
        let(:oe_activity) { double('Activity', activity_type: 'open_ended',
                                               diagnostic_reference: oe_reference,
                                               is_bonus: false) }

        before do
          allow(question).to receive(:is_a?)
            .with(MaestroActivityEngine::ActivityContent::OpenEnded::Item)
            .and_return(true)
          allow(presenter).to receive_message_chain(:activity, :has_mixed_grading_method?)
            .and_return(true)
          allow(view_manager).to receive(:current_sub_activity)
            .and_return(oe_activity)
          allow(view_manager).to receive(:current_sub_activity_rank)
            .and_return(1)
        end

        it "yields the reference formatter name and args for the open ended reference" do
          def fake_method(*args)
          end

          expect(self).to receive(:fake_method)
            .with(:format_reference_diagnostic, 'open_ended', oe_reference,
                                                1, nil, false, true)

          view_manager.html_friendly_prompt { |formatter, *args| fake_method(formatter, *args) }
        end
      end

      it "yields the multi-type reference formatter method name, and args for it" do
        def fake_method(*args)
        end

        allow(presenter).to receive_message_chain(:activity, :has_mixed_grading_method?)
          .and_return(true)
        allow(view_manager).to receive(:current_sub_activity_rank)
          .and_return(1)
        allow(view_manager).to receive(:current_sub_activity)
          .and_return(diagnostic_activity)
        expect(self).to receive(:fake_method)
          .with(:format_reference_diagnostic, diagnostic_activity_type,
                                              diagnostic_reference,
                                              1, nil, false, true)

        view_manager.html_friendly_prompt{|formatter, *args| fake_method(formatter, *args) }
      end
    end

    context "when the current question is in an auto-graded activity" do
      it "yields the reference formatter method name, and args for it" do
        def fake_method(*args)
        end
        reference = double(MaestroActivityEngine::ActivityContent::Reference::Base)

        direction_line_children = [double('DirectionLine')]
        allow(direction_line_children).to receive(:to_html).and_return('Direction Line')
        allow(presenter).to receive_message_chain(:activity, :has_mixed_grading_method?).and_return(false)
        allow(presenter).to receive_message_chain(:activity, :content_object, :dl, :children).and_return(direction_line_children)
        allow(presenter).to receive_message_chain(:activity, :content_object, :items, :detect).and_return(reference)
        expect(self).to receive(:fake_method).with(:format_reference, reference)
        view_manager.html_friendly_prompt{|formatter, *args| fake_method(formatter, *args) }
      end
    end
  end

  describe "#question_title_text" do
    context "when an activity is a multi-type activity" do
      let(:sub_activity_with_one_question){ double('Activity', :items => [double('Question', :label => 'question_01', :question_number => 1)] ) }
      let(:sub_activity_with_multiple_questions){ double('Activity', :items => [double('Question', :label => 'question_02', :question_number => 1),
                                                                              double('Question', :label => 'question_03', :question_number => 2)] ) }
      let(:sub_activities){ [sub_activity_with_one_question, sub_activity_with_multiple_questions] }

      before do
        allow(presenter).to receive_message_chain(:activity, :has_mixed_grading_method?).and_return(true)
      end

      context "when a sub activity in the multi-type activity only has one question" do
        it "returns a hash keyed off of question label with a value of 'Question (question number)'" do
          allow(presenter).to receive_message_chain(:activity, :sub_activities).and_return(sub_activities)
          expect(view_manager.question_title_text).to include('question_01' => 'Question 1')
        end
      end

      context "when a sub activity in the multi-type activity has multiple questions" do
        it "returns a hash keyed off of question label with a value of 'Question (question number) - (sub question number)'" do
          allow(presenter).to receive_message_chain(:activity, :sub_activities).and_return(sub_activities)
          expect(view_manager.question_title_text).to include('question_02' => 'Question 2 - 1', 'question_03' => 'Question 2 - 2')
        end
      end
    end

    context "when an activity is not a multi-type activity (it is an open ended, or auto graded etc.)" do
      let(:questions) do
        [
          double('Question', label: 'question_01', question_number: 1),
          double('Question', label: 'question_02', question_number: 2)
        ]
      end

      it "returns a hash keyed off of question label, e.g. { 'question_01' => 'Question 1' }" do
        activity = instance_double(
          Activity,
          has_mixed_grading_method?: false,
          questions: questions
        )
        allow(presenter).to receive(:activity).and_return(activity)
        allow(presenter).to receive(:activity_questions).and_return(activity.questions)
        expect(view_manager.question_title_text).to include(
          'question_01' => 'Question 1'
        )
      end
    end
  end

  describe "#is_current_question?" do
    it "returns true when the given question is equal to the current question being graded" do
      allow(presenter).to receive(:current_question).and_return('question')
      expect(view_manager.current?('question')).to be_truthy
    end
  end

  describe "#graded?" do
    before(:each) do
      allow(question).to receive(:label).and_return('label')
    end

    it "returns true when status_class is 'complete'" do
      allow(view_manager.presenter).to receive(:grading_status).and_return(
        question.label => { status_class: 'complete' })
      expect(view_manager.graded?(question)).to be_truthy
    end

    it "returns false when status_class is not 'complete'" do
      allow(view_manager.presenter).to receive(:grading_status).and_return(
        question.label => { status_class: 'not complete' })
      expect(view_manager.graded?(question)).to be_falsey
    end
  end

  describe "#option_string" do
    it "returns expected value" do
      allow(question).to receive(:label).and_return('label')
      expect(view_manager.option_string(question)).to eq 'label'
    end
  end

  describe "#option_value" do
    it "returns expected value" do
      allow(question).to receive(:label).and_return('label')
      expect(view_manager.option_value(question)).to eq 'label'
    end
  end

  describe "#option_data" do
    it "returns expected value" do
      allow(question).to receive(:label).and_return('label')
      expect(view_manager.option_data(question)).to eq(question_label: 'label')
    end
  end

  describe "#option_jump_to" do
    it "returns the same value as #option_value" do
      allow(question).to receive(:label).and_return('label')
      expect(view_manager.option_jump_to(question)).to eq view_manager.option_value(question)
    end
  end

  describe '#results' do
    it 'retrieves the results from the student attempt' do
      attempt = FactoryBot.build(:attempt)
      student = double(Student)

      allow(view_manager).to receive(:question_label).and_return('my label')
      allow(view_manager).to receive(:student_attempt).with(student).and_return(attempt)

      expect(attempt).to receive(:results)

      view_manager.results(student)
    end
  end

  describe '#current_question_solo_video_recording_question?' do
    it 'returns true when question is a solo video recording one' do
      svr_question = MaestroActivityEngine::ActivityContent::SoloVideoRecording::Item.new
      allow(presenter).to receive(:current_question).and_return(svr_question)
      manager = described_class.new(presenter)
      expect(manager.solo_video_recording_question?).to be_truthy
    end

    it 'returns false when question is not a solo video recording one' do
      allow(presenter).to receive(:current_question).and_return(question)
      manager = described_class.new(presenter)
      expect(manager.solo_video_recording_question?).to be_falsey
    end
  end

  describe '#question_content_object' do
    let(:main_activity_content) do
      instance_double(
        MaestroActivityEngine::ActivityContent::Content
      )
    end

    before do
      allow(presenter).to receive(:activity).and_return(activity)
      allow(activity).to receive(:content_object).and_return(
        main_activity_content
      )
    end

    context 'when the main activity has no sub_activities' do
      before do
        allow(activity).to receive(:has_sub_activities?).and_return(false)
      end

      it 'returns the content object of the main activity' do
        expect(view_manager.question_content_object).to eq(main_activity_content)
      end
    end

    context 'when the main activity has sub_activities' do
      let(:sub_activity_content) do
        instance_double(
          MaestroActivityEngine::ActivityContent::Content
        )
      end

      before do
        allow(activity).to receive(:has_sub_activities?).and_return(true)

        allow(activity).to receive(:sub_activities).and_return(
          [other_sub_activity, sub_activity]
        )
      end

      it 'returns the sub_activity containing the current question' do
        expect(view_manager.question_content_object).to eq(sub_activity)
      end
    end
  end

  describe '#current_sub_activity' do
    before do
      allow(presenter).to receive(:activity).and_return(activity)
    end

    it 'returns the sub activity if question is part of a sub activity' do
      allow(view_manager).to receive(:sub_activity_and_rank_for_current_question)
        .and_return({ rank: 1, sub_activity: sub_activity })
      expect(view_manager.current_sub_activity).to eq(sub_activity)
    end
  end

  describe '#sub_activity_and_rank_for_current_question' do
    before do
      allow(presenter).to receive(:activity).and_return(activity)
    end

    it 'returns the rank and sub activity when question belongs to a sub activity' do
      allow(activity).to receive(:sub_activities).and_return(
        [other_sub_activity, sub_activity]
      )

      result = view_manager.sub_activity_and_rank_for_current_question

      expect(result).to eq({ rank: 2, sub_activity: sub_activity })
    end

    it 'returns nil if no sub activity contains the question' do
      allow(activity).to receive(:sub_activities).and_return([other_sub_activity])

      expect(view_manager.sub_activity_and_rank_for_current_question).to be_nil
    end
  end
end
