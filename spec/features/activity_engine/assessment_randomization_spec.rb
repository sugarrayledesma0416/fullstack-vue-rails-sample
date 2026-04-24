feature 'Assessment randomization', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include CapybaraViewHelpers
  include ActivityTest::Helpers
  include ActivityTest::RecordingV2Helpers
  include GradebookEngineTest::PageObjects

  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:program) do
    create(:program).tap do |program|
      program.units = Array.new(3) do |number|
        create(
          :unit,
          name: "Lesson #{number + 1}",
          rank: number + 1,
          released: true,
          program: program
        )
      end
      program.units.each do |unit|
        unit.lessons = [
          create(
            :lesson,
            name: unit.name,
            rank: unit.rank,
            unit: unit,
            toc_entries: Array.new(5) do |index|
              # Create assessment strands and non assessment strands.
              create(:toc_entry, assessment: index < 3)
            end
          )
        ]
      end
      program.save!
    end
  end
  let(:program_settings) do
    {
      allow_assessments_randomization: true
    }
  end
  let(:course) do
    create(
      :course,
      owner: instructor,
      program: program,
      allow_audio_transcripts: true
    )
  end
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.toc_entries.first }
  let(:concept) do
    create(
      :concept,
      assessment: true,
      singular_label: 'quiz',
      id: strand.location,
      lesson: lesson
    )
  end
  let(:category) { create(:category, course: course) }
  let!(:media_items) do
    [
      create(
        :media_item_audio,
        id: 1,
        filename: 'vocab_list_audio_1.mp3',
        transcript: 'Audio file 1 transcription'
      ),
      create(:media_item_audio, id: 2, filename: 'vocab_list_audio_2.mp3')
    ]
  end
  let(:content_filepath) { File.join('spec', 'fixtures', 'xml', 'assessment.xml') }
  let(:assessment) do
    assessment = create(
      :instructor_created_activity,
      lesson: lesson,
      toc_location: strand.location,
      concept: concept,
      cms_revision_id: 1
    )
    allow(Activity).to receive(:filepath_from_revision_id).and_return(content_filepath)
    assessment = Activity.find(assessment.id)
    assessment.save!
    assessment
  end
  let(:ordered_activities) do
    assessment.content_object.activities.shuffle(random: Random.new(student.id))
  end
  let(:activity_data) { ActivityTest::ActivityData::MultiType.new(assessment, media_items) }
  let(:multiple_choice_activity_data) { activity_data.sub_activity(1) }
  let(:multiple_choice_ordered_questions_data) do
    multiple_choice_activity_data.questions.shuffle(random: Random.new(student.id))
  end
  let(:multiple_choice_question_1) { multiple_choice_activity_data.questions[0] }
  let(:multiple_choice_question_2) { multiple_choice_activity_data.questions[1] }
  let(:multiple_choice_question_3) { multiple_choice_activity_data.questions[2] }
  let(:multiple_choice_question_4) { multiple_choice_activity_data.questions[3] }
  let(:multiple_choice_question_1_choice) { multiple_choice_question_1.correct_choice }
  let(:multiple_choice_question_2_choice) { multiple_choice_question_2.incorrect_choices[0] }
  let(:drop_down_activity_data) { activity_data.sub_activity(2) }
  let(:drop_down_ordered_questions_data) do
    drop_down_activity_data.questions.shuffle(random: Random.new(student.id))
  end
  let(:drop_down_question_1) { drop_down_activity_data.questions[0] }
  let(:drop_down_question_2) { drop_down_activity_data.questions[1] }
  let(:drop_down_question_3) { drop_down_activity_data.questions[2] }
  let(:drop_down_question_1_menu_1_option) { drop_down_question_1.menu(1).correct_option }
  let(:drop_down_question_2_menu_2_option) { drop_down_question_2.menu(2).correct_option }
  let(:drop_down_question_3_menu_1_option) { drop_down_question_3.menu(1).incorrect_options[0] }
  let(:fib_activity_data) { activity_data.sub_activity(3) }
  let(:fib_ordered_questions_data) do
    fib_activity_data.questions.shuffle(random: Random.new(student.id))
  end
  let(:fib_question_1) { fib_activity_data.questions[0] }
  let(:fib_question_2) { fib_activity_data.questions[1] }
  let(:fib_question_3) { fib_activity_data.questions[2] }
  let(:fib_question_1_wol_2) { 'Question 1, answer 2!' }
  let(:fib_question_2_wol_1) { 'Question 2 answer' }
  let(:oe_activity_data) { activity_data.sub_activity(4) }
  let(:oe_ordered_questions_data) do
    oe_activity_data.questions.shuffle(random: Random.new(student.id))
  end
  let(:oe_question_1) { oe_activity_data.questions[0] }
  let(:oe_question_2) { oe_activity_data.questions[1] }
  let(:oe_question_3) { oe_activity_data.questions[2] }
  let(:oe_question_1_answer) { 'This is the response for the oe question 1' }
  let(:oe_question_2_answer) { 'This is the response for the oe question 2' }
  # true false enhanced activity
  let(:tfe_activity_data) { activity_data.sub_activity(5) }
  let(:tfe_ordered_questions_data) do
    tfe_activity_data.questions.shuffle(random: Random.new(student.id))
  end
  let(:tfe_question_1) { tfe_activity_data.questions[0] }
  let(:tfe_question_2) { tfe_activity_data.questions[1] }
  let(:tfe_question_3) { tfe_activity_data.questions[2] }
  let(:tfe_question_4) { tfe_activity_data.questions[3] }
  let(:tfe_question_2_correction) { 'some correction for the tfe question 2' }
  # recording activity
  let(:recording_activity_data) { activity_data.sub_activity(6) }
  let(:recording_ordered_questions_data) do
    recording_activity_data.questions.shuffle(random: Random.new(student.id))
  end
  let(:recording_question_1) { recording_activity_data.questions[0] }
  let(:recording_question_2) { recording_activity_data.questions[1] }
  let(:recording_question_3) { recording_activity_data.questions[2] }
  # new activity, start with no submission
  let(:fake_submissions) { {} }

  RSpec::Matchers.define :not_exist do
    match(&:not_exist?)
  end

  before do
    stub_const(
      'MediaItem::CDN_URL_PREFIX',
      "#{Capybara.app_host}:#{Capybara.current_session.server.port}"
    )
  end

  def exam_header_for_activity(activity)
    exam = activity.items.find do |item|
      item.is_a?(MaestroActivityEngine::ActivityContent::Reference::Exam)
    end
    exam.header.content
  end

  def validate_questions_prompts(questions, questions_data)
    questions_data.each_with_index do |question_data, index|
      expect_element_prompt_to_be_displayed(
        questions[index], question_data.prompt
      )
    end
  end

  def create_assignment(opts)
    common_args = {
      assignable: assessment,
      due_date: 2.days.from_now.to_date,
      section: section,
      show_at: 1.day.ago,
      category: category,
      grade_availability: :on_release,
      grades_available_at: 1.day.ago
    }
    create(:assignment, common_args.merge(opts))
  end

  before do
    ProgramConfig.create!(
      program_settings.merge(
        program_id: program.id,
        creator_id: instructor.id
      )
    )
  end

  context 'as a student' do
    before do
      initialize_fake_submissions_client
      give_user_access_to_program(student, program)
      allow(Maestro::LicenseGroup).to receive(:all)
        .and_return([double('LicenseGroup', id: 1, name: '01-Supersite')])
      allow_any_instance_of(StudentActivityPresenter).to receive(:pretest_type).and_return('')
      create(:active_enrollment, section: section, user: student)
      log_in_as(student)
    end

    context 'when marking the assignment as do not randomize' do
      scenario 'The assessment is not randomized' do
        create_assignment(randomize_per_student: false)

        visit section_activity_path(section, assessment)
        page.find(
          '.test-assessment-start-btn', text: 'Begin Assessment').click

        for_preview_page(activity_data) do |pobject|
          sections = pobject.assessment_sections
          sections_by_activity_type = sections.each_with_object({}) do |section, memo|
            memo[section.activity_type] = section
          end

          purpose 'Sections have *not* been randomized' do
            expect(sections.map(&:exam_header)).to eq(
              assessment.content_object.activities.map do |activity|
                exam_header_for_activity(activity)
              end
            )
          end

          purpose 'Questions of the multiple choice activity have *not* been randomized' do
            section = sections_by_activity_type['multiple_choice']
            validate_questions_prompts(
              section.multiple_choice_questions,
              multiple_choice_activity_data.questions
            )
          end

          purpose 'Questions of the drop down activity have *not* been randomized' do
            section = sections_by_activity_type['drop_down']
            validate_questions_prompts(
              section.drop_down_questions,
              drop_down_activity_data.questions
            )
          end

          purpose 'Questions of the fill in the blanks activity have *not* been randomized' do
            section = sections_by_activity_type['fill_in_the_blanks']
            validate_questions_prompts(
              section.fill_in_the_blanks_questions,
              fib_activity_data.questions
            )
          end

          purpose 'Questions of the open ended activity have *not* been randomized' do
            section = sections_by_activity_type['open_ended']
            validate_questions_prompts(
              section.open_ended_questions,
              oe_activity_data.questions
            )
          end

          purpose 'Questions of the true false enhanced activity have *not* been randomized' do
            section = sections_by_activity_type['true_false_enhanced']
            validate_questions_prompts(
              section.true_false_enhanced_questions,
              tfe_activity_data.questions
            )
          end

          purpose 'Questions of the recording activity have *not* been randomized' do
            section = sections_by_activity_type['recording']
            validate_questions_prompts(
              section.recording_v2_questions,
              recording_activity_data.questions
            )
          end
        end
      end
    end

    context 'when marking subactivities as do not randomize' do
      let(:content_filepath) do
        File.join('spec', 'fixtures', 'xml', 'assessment_do_not_randomize.xml')
      end

      scenario 'I can complete the assessment' do
        create_assignment(randomize_per_student: true)
        visit section_activity_path(section, assessment)
        page.find('.test-assessment-start-btn', text: 'Begin Assessment').click

        for_preview_page(activity_data) do |pobject|
          sections = pobject.assessment_sections
          sections_by_activity_type = sections.each_with_object({}) do |section, memo|
            memo[section.activity_type] = section
          end

          purpose 'Sections have *not* been randomized' do
            expect(sections.map(&:exam_header)).to eq(
              assessment.content_object.activities.map do |activity|
                exam_header_for_activity(activity)
              end
            )
          end

          purpose 'Questions of the multiple choice activity have *not* been randomized' do
            section = sections_by_activity_type['multiple_choice']
            validate_questions_prompts(
              section.multiple_choice_questions,
              multiple_choice_activity_data.questions
            )
          end

          purpose 'Questions of the drop down activity have been randomized' do
            section = sections_by_activity_type['drop_down']
            validate_questions_prompts(
              section.drop_down_questions,
              drop_down_ordered_questions_data
            )
          end

          purpose 'Questions of the fill in the blanks activity have been randomized' do
            section = sections_by_activity_type['fill_in_the_blanks']
            validate_questions_prompts(
              section.fill_in_the_blanks_questions,
              fib_ordered_questions_data
            )
          end

          purpose 'Questions of the open ended activity have been randomized' do
            section = sections_by_activity_type['open_ended']
            validate_questions_prompts(
              section.open_ended_questions,
              oe_ordered_questions_data
            )
          end

          purpose 'Questions of the true false enhanced activity have been randomized' do
            section = sections_by_activity_type['true_false_enhanced']
            validate_questions_prompts(
              section.true_false_enhanced_questions,
              tfe_ordered_questions_data
            )
          end

          purpose 'Questions of the recording activity have been randomized' do
            section = sections_by_activity_type['recording']
            validate_questions_prompts(
              section.recording_v2_questions,
              recording_ordered_questions_data
            )
          end
        end
      end
    end

    xscenario 'I can complete a randomized assessment' do
      create_assignment(randomize_per_student: true)
      visit section_activity_path(section, assessment)
      page.find('.test-assessment-start-btn', text: 'Begin Assessment').click

      for_preview_page(activity_data) do |pobject|
        sections = pobject.assessment_sections
        sections_by_activity_type = sections.each_with_object({}) do |section, memo|
          memo[section.activity_type] = section
        end

        purpose 'Sections have been randomized' do
          expect(sections.map(&:exam_header)).to eq(
            ordered_activities.map { |activity| exam_header_for_activity(activity) }
          )
        end

        purpose 'Questions of the multiple choice activity have been randomized' do
          section = sections_by_activity_type['multiple_choice']
          validate_questions_prompts(
            section.multiple_choice_questions,
            multiple_choice_ordered_questions_data
          )
        end

        purpose 'Questions of the drop down activity have been randomized' do
          section = sections_by_activity_type['drop_down']
          validate_questions_prompts(
            section.drop_down_questions,
            drop_down_ordered_questions_data
          )
        end

        purpose 'Questions of the fill in the blanks activity have been randomized' do
          section = sections_by_activity_type['fill_in_the_blanks']
          validate_questions_prompts(
            section.fill_in_the_blanks_questions,
            fib_ordered_questions_data
          )
        end

        purpose 'Questions of the open ended activity have been randomized' do
          section = sections_by_activity_type['open_ended']
          validate_questions_prompts(
            section.open_ended_questions,
            oe_ordered_questions_data
          )
        end

        purpose 'Questions of the true false enhanced activity have been randomized' do
          section = sections_by_activity_type['true_false_enhanced']
          validate_questions_prompts(
            section.true_false_enhanced_questions,
            tfe_ordered_questions_data
          )
        end

        purpose 'Questions of the recording activity have been randomized' do
          section = sections_by_activity_type['recording']
          validate_questions_prompts(
            section.recording_v2_questions,
            recording_ordered_questions_data
          )
        end

        purpose 'I answer the questions of the multiple choice activity' do
          from_multiple_choice_question(multiple_choice_question_1.rank)
            .select_choice(multiple_choice_question_1_choice)
          from_multiple_choice_question(multiple_choice_question_2.rank)
            .select_choice(multiple_choice_question_2_choice)
        end

        purpose 'I answer the questions of the drop down activity' do
          from_drop_down_question(drop_down_question_1.rank).drop_down_menu(1)
            .select_option(drop_down_question_1_menu_1_option.number)
          from_drop_down_question(drop_down_question_2.rank).drop_down_menu(2)
            .select_option(drop_down_question_2_menu_2_option.number)
          from_drop_down_question(drop_down_question_3.rank).drop_down_menu(1)
            .select_option(drop_down_question_3_menu_1_option.number)
        end

        purpose 'I answer the questions of the fill in the blanks activity' do
          from_fib_question(fib_question_1.rank).wol(2).choose_answer(
            fib_question_1_wol_2
          )
          from_fib_question(fib_question_2.rank).wol(1).choose_answer(
            fib_question_2_wol_1
          )
        end

        purpose 'I answer the questions of the open ended activity' do
          from_open_ended_question(oe_question_1.rank).choose_answer(
            oe_question_1_answer
          )
          from_open_ended_question(oe_question_2.rank).choose_answer(
            oe_question_2_answer
          )
        end

        purpose 'I answer the questions of the true false enhanced activity' do
          from_true_false_enhanced_question(tfe_question_1.rank)
            .choice_true.select
          from_true_false_enhanced_question(tfe_question_2.rank) do |question|
            question.choice_false.select
            question.correction.text = tfe_question_2_correction
          end
        end

        purpose 'I answer the questions of the recording activity' do
          # Show the transcriptions to enable the reord buttons to speed up the spec.
          @page_object.show_transcriptions

          from_recording_v2_question(recording_question_1.rank) do |question|
            record_audio_file(question)
          end

          from_recording_v2_question(recording_question_2.rank) do |question|
            record_audio_file(question)
          end

          from_recording_v2_question(recording_question_3.rank) do |question|
            # Do not record anything
          end
        end

        step 'I submit the assessment' do
          click_button_expect_alert(:submit, '9 questions are unanswered.')
        end
      end

      purpose 'I see a success message' do
        expect_flash_message(:notice, 'Activity complete.')
      end

      for_complete_page(activity_data) do |pobject|
        sections = pobject.assessment_sections
        sections_by_activity_type = sections.each_with_object({}) do |section, memo|
          memo[section.activity_type] = section
        end

        purpose 'Sections have been randomized' do
          expect(sections.map(&:exam_header)).to eq(
            ordered_activities.map { |activity| exam_header_for_activity(activity) }
          )
        end

        purpose 'Questions of the multiple choice activity have been randomized' do
          section = sections_by_activity_type['multiple_choice']
          validate_questions_prompts(
            section.multiple_choice_questions,
            multiple_choice_ordered_questions_data
          )
        end

        purpose 'Questions of the drop down activity have been randomized' do
          section = sections_by_activity_type['drop_down']
          validate_questions_prompts(
            section.drop_down_questions,
            drop_down_ordered_questions_data
          )
        end

        purpose 'Questions of the fill in the blanks activity have been randomized' do
          section = sections_by_activity_type['fill_in_the_blanks']
          validate_questions_prompts(
            section.fill_in_the_blanks_questions,
            fib_ordered_questions_data
          )
        end

        purpose 'Questions of the open ended activity have been randomized' do
          section = sections_by_activity_type['open_ended']
          validate_questions_prompts(
            section.open_ended_questions,
            oe_ordered_questions_data
          )
        end

        purpose 'Questions of the true false enhanced activity have been randomized' do
          section = sections_by_activity_type['true_false_enhanced']
          validate_questions_prompts(
            section.true_false_enhanced_questions,
            tfe_ordered_questions_data
          )
        end

        purpose 'Questions of the recording activity have been randomized' do
          section = sections_by_activity_type['recording']
          validate_questions_prompts(
            section.recording_v2_questions,
            recording_ordered_questions_data
          )
        end

        purpose 'Questions of the multiple choice activity are marked as correct or incorrect' do
          from_multiple_choice_question(multiple_choice_question_1.rank) do |question|
            expect(question).to be_marked(:correct)
            expect(question.choices)
              .to all_be_marked(:blank).except(multiple_choice_question_1_choice => :correct)
              .and all_be_uneditable
          end
          from_multiple_choice_question(multiple_choice_question_2.rank) do |question|
            expect(question).to be_marked(:incorrect)
            expect(question.choices)
              .to all_be_marked(:blank).except(
                multiple_choice_question_2_choice => :incorrect,
                multiple_choice_question_2.correct_choice => :correction
              )
              .and all_be_uneditable
          end
          from_multiple_choice_question(multiple_choice_question_3.rank) do |question|
            expect(question).to be_marked(:incorrect)
            expect(question.choices)
              .to all_be_marked(:blank).except(multiple_choice_question_3.correct_choice => :correction)
              .and all_be_uneditable
          end
        end

        purpose 'Questions of the drop down activity are marked as correct or incorrect' do
          from_drop_down_question(drop_down_question_1.rank) do |question|
            expect(question).to be_marked(:correct)
            with_element(question.drop_down_menu(1)) do |menu|
              expect(menu).to be_marked(:correct)
              expect(menu.text).to include(drop_down_question_1_menu_1_option.text)
            end
          end
          from_drop_down_question(drop_down_question_2.rank) do |question|
            expect(question).to be_marked(:partial)
            with_element(question.drop_down_menu(1)) do |menu|
              expect(menu).to be_marked(:incorrect)
              expect(menu.text).to include('(blank)')
            end
            with_element(question.drop_down_menu(2)) do |menu|
              expect(menu).to be_marked(:correct)
              expect(menu.text).to include(drop_down_question_2_menu_2_option.text)
            end
          end
          from_drop_down_question(drop_down_question_3.rank) do |question|
            expect(question).to be_marked(:incorrect)
            with_element(question.drop_down_menu(1)) do |menu|
              expect(menu).to be_marked(:incorrect)
              expect(menu.text).to include(drop_down_question_3_menu_1_option.text)
            end
          end
        end

        purpose 'Questions of the fill in the blanks activity are marked as correct or incorrect' do
          from_fib_question(fib_question_1.rank) do |question|
            expect(question).to be_marked(:incorrect)

            with_element(question.wol(1)) do |wol|
              expect(wol).to have_no_input_field
              expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
              expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
              expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
            end

            with_element(question.wol(2)) do |wol|
              expect(wol).to have_no_input_field
              expect(wol.submitted_tokens.map(&:text)).to eq(
                ['Question', '1', ',', 'answer', '2', '!']
              )
              expect(wol.submitted_tokens.map(&:mark)).to eq(
                %i[none none missed_punctuation none none missed_punctuation]
              )
              expect(wol.submitted_tokens.map(&:title)).to eq(
                %i[none none incorrect_or_extra_punctuation none none incorrect_or_extra_punctuation]
              )
            end
          end

          from_fib_question(fib_question_2.rank) do |question|
            expect(question).to be_marked(:correct)
            with_element(question.wol(1)) do |wol|
              expect(wol).to have_no_input_field
              expect(wol.submitted_tokens.map(&:text)).to eq(%w[Question 2 answer])
              expect(wol.submitted_tokens.map(&:mark)).to eq(%i[none none none])
              expect(wol.submitted_tokens.map(&:title)).to eq(%i[none none none])
              expect(wol.correct_answer_tokens).to eq(%w[Question 2 answer])
            end
          end

          from_fib_question(fib_question_3.rank) do |question|
            expect(question).to be_marked(:incorrect)
            with_element(question.wol(1)) do |wol|
              expect(wol).to have_no_input_field
              expect(wol.submitted_tokens.map(&:text)).to eq(['(blank)'])
              expect(wol.submitted_tokens.map(&:mark)).to eq(%i[incorrect])
              expect(wol.submitted_tokens.map(&:title)).to eq(%i[none])
              expect(wol.best_answers).to eq(['Question 3 answer'])
            end
          end
        end

        purpose 'Questions of the open ended activity are marked as correct or incorrect' do
          from_open_ended_question(oe_question_1.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.answer.text).to eq(oe_question_1_answer)
          end

          from_open_ended_question(oe_question_2.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.answer.text).to eq(oe_question_2_answer)
          end
          from_open_ended_question(oe_question_3.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.answer.text).to eq('(No student response)')
          end
        end

        purpose 'Questions of the true false enhanced activity are marked as correct or incorrect' do
          from_true_false_enhanced_question(tfe_question_1.rank) do |question|
            expect(question).to be_marked(:correct)
            expect(question.choice_true).to be_marked(:correct)
            expect(question.choice_false).to be_marked(:blank)
            expect(question.correction).to not_exist
          end
          from_true_false_enhanced_question(tfe_question_2.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.choice_true).to be_marked(:blank)
            expect(question.choice_false).to be_marked(:correct)
            expect(question.correction.text).to include(tfe_question_2_correction)
          end
          from_true_false_enhanced_question(tfe_question_3.rank) do |question|
            expect(question).to be_marked(:incorrect)
            expect(question.choice_true).to be_marked(:correction)
            expect(question.choice_false).to be_marked(:blank)
            expect(question.correction).to not_exist
          end
          from_true_false_enhanced_question(tfe_question_4.rank) do |question|
            expect(question).to be_marked(:incorrect)
            expect(question.choice_true).to be_marked(:blank)
            expect(question.choice_false).to be_marked(:correction)
            expect(question.correction).to not_exist
          end
        end

        purpose 'Questions of the recording activity are marked as pending' do
          from_recording_v2_question(recording_question_1.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.button(:listen)).to be_enabled
            expect(question.button(:review)).to be_enabled
            expect(question.button(:answer)).to be_enabled
          end

          from_recording_v2_question(recording_question_2.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.button(:listen)).to be_enabled
            expect(question.button(:review)).to be_enabled
            expect(question.button(:answer)).to be_enabled
          end

          from_recording_v2_question(recording_question_3.rank) do |question|
            expect(question).to be_marked(:pending)
            expect(question.button(:listen)).to be_enabled
            # The review button is disabled because we did not record anything
            expect(question.button(:review)).to be_disabled
            expect(question.button(:answer)).to be_enabled
          end
        end
      end

      purpose 'the responses have been stored in the attempt' do
        expect(Attempt.last.stored_responses).to include(
          format(
            'question_%02d', multiple_choice_question_1.rank
          ) => multiple_choice_question_1.correct_choice.to_s,
          format(
            'question_%02d', multiple_choice_question_2.rank
          ) => multiple_choice_question_2_choice.to_s,
          format('question_%02d', multiple_choice_question_3.rank) => '',
          format('question_%02d', multiple_choice_question_4.rank) => '',
          format(
            'question_%02d_1', drop_down_question_1.rank
          ) => drop_down_question_1_menu_1_option.number.to_s,
          format('question_%02d_1', drop_down_question_2.rank) => '0',
          format(
            'question_%02d_2', drop_down_question_2.rank
          ) => drop_down_question_2_menu_2_option.number.to_s,
          format(
            'question_%02d_1', drop_down_question_3.rank
          ) => drop_down_question_3_menu_1_option.number.to_s,
          format('question_%02d_wol_1', fib_question_1.rank) => '',
          format(
            'question_%02d_wol_2', fib_question_1.rank
          ) => fib_question_1_wol_2,
          format(
            'question_%02d_wol_1', fib_question_2.rank
          ) => fib_question_2_wol_1,
          format('question_%02d_wol_1', fib_question_3.rank) => '',
          format('question_%02d', oe_question_1.rank) => oe_question_1_answer,
          format('question_%02d', oe_question_2.rank) => oe_question_2_answer,
          format('question_%02d', oe_question_3.rank) => '',
          format('question_%02d', tfe_question_1.rank) => '1',
          format('question_%02d_correction', tfe_question_1.rank) => '',
          format('question_%02d', tfe_question_2.rank) => '2',
          format(
            'question_%02d_correction', tfe_question_2.rank
          ) => tfe_question_2_correction,
          format('question_%02d', tfe_question_3.rank) => '',
          format('question_%02d_correction', tfe_question_3.rank) => '',
          format('question_%02d', tfe_question_4.rank) => '',
          format('question_%02d_correction', tfe_question_4.rank) => '',
          format(
            'question_%02d', recording_question_1.rank
          ) => a_string_starting_with('recording_v2/'),
          format(
            'question_%02d', recording_question_2.rank
          ) => a_string_starting_with('recording_v2/'),
          format('question_%02d', recording_question_3.rank) => ''
        )
      end
    end
  end
end
