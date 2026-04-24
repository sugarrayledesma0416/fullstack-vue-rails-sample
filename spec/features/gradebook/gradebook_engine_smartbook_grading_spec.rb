feature 'Instructor smartbook grading', if: DynamoConfig.use_local?,
                                        chrome: true, js: true,
                                        new_gb_sync: true,
                                        use_local_dynamodb: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include RspecJsDownloadHelpers
  include GradebookEngineHelpers
  include ActivityTest::MockSubmissions
  include InstructorGradingHelpers
  include GradebookEngineTest::PageObjects
  include CapybaraViewHelpers
  include SmartbookTest

  around do |example|
    # When using the 'percent_per_day' late penalty, the gradebook uses the nearest
    # number of days from now. In order to avoid any problem with the calculation
    # depending of the time the spec is run, we use a fixed date for the spec.
    now = Time.now
    Timecop.freeze(Time.new(now.year, now.month, now.day, 1, 0, 0)) do
      example.run
    end
  end

  let(:smartbook_recording_endpoint) { Rails.application.config.smartbook_recording_endpoint }
  let(:instructor) { create(:instructor) }
  # In the spotcheck grading view, the StudentSorter class sorts the students
  # by name using User.sortable_name. In order to have a predictable spec,
  # we hardcode the student names.
  let(:student_1) { create(:student, first_name: 'Obi-Wan', last_name: 'Kenobi') }
  let(:student_2) { create(:student, first_name: 'Princess', last_name: 'Leia') }
  let(:student_3) { create(:student, first_name: 'Luke', last_name: 'Skywalker') }
  let(:student_4) { create(:student, first_name: 'Darth', last_name: 'Vader') }
  let(:student_5) { create(:student, first_name: 'Kylo', last_name: 'Ren') }
  let(:program) { create(:program_with_toc_entries) }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      start_date: -1.days.from_now,
      program: program
    )
  end
  let(:category) { create(:category, course: course, credit_only: false) }
  let(:section) { create(:section, course: course, instructor: instructor) }
  let(:activity)  do
    create_smart_book_activity(
      program,
      grading_method: 'auto',
      lesson: lesson,
      strand_id: strand.location
    )
  end
  let(:attempt) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student_1,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let(:attempt_student_2) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student_2,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let(:attempt_student_3) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student_3,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let(:attempt_student_4) do
    create(
      :attempt_submitted,
      activity: activity,
      section: section,
      user: student_4,
      cms_revision_id: activity.cms_revision_id
    )
  end
  let(:attempt_student_5) do
    create(
        :attempt_submitted,
        activity: activity,
        section: section,
        user: student_5,
        cms_revision_id: activity.cms_revision_id
    )
  end
  let!(:assignment) do
    create(
      :assignment,
      category: category,
      due_date: Date.today + 2,
      section: section,
      assignable: activity
    )
  end
  let(:fake_submissions) { {} }
  let(:smartbook_data) { SmartbookTest::SmartbookData.new }
  let(:question_1) { smartbook_data.question_1_open_ended }
  let(:question_2) { smartbook_data.question_2_open_ended }
  let(:question_3) { smartbook_data.question_3_open_ended }
  let(:question_4) { smartbook_data.question_4_audio_recording }
  let(:question_5) { smartbook_data.question_5_multiple_choice }
  let(:question_6) { smartbook_data.question_6_matching }
  let(:question_1_instructor_graded) { question_1 }
  let(:question_2_instructor_graded) { question_2 }
  let(:question_3_instructor_graded) { question_3 }
  let(:question_4_audio_recording) { question_4 }
  let(:question_5_auto_graded) { question_5 }
  let(:question_6_auto_graded) { question_6 }
  let(:student_1_question_1_response) do
    'Me llamo Angela. Soy de Mexico.'
  end
  let(:student_1_question_2_response) do
    'Blah blah blah.'
  end
  let(:student_1_question_4_audio_filename) do
    'VR_SBHS1/HS1UP002bCCP1/201926392937868.wav'
  end
  let(:student_1_question_4_response) do
    "#{smartbook_recording_endpoint}/#{section.guid}/" \
    "lossless_user_token/#{student_1_question_4_audio_filename}"
  end
  let(:student_1_question_4_instructor_audio_source) do
    "#{smartbook_recording_endpoint}/#{section.guid}/" \
    "#{instructor_policy_token}/#{student_1_question_4_audio_filename}"
  end
  let(:student_1_question_5_response) do
    '1.[.]usted[,]2.[.]usted[,]4.[.]tú[,]5.[.]usted'
  end
  let(:student_1_question_5_formatted_response) do
    '1. usted 2. usted 4. tú 5. usted'
  end
  let(:student_1_question_6_response) do
    smartbook_data.question_6_response_1_incorrect_1_missing
  end
  let(:student_2_question_1_response) do
    'Soy Maria de Mexico.'
  end
  let(:student_2_question_3_response) do
    'Pablo.'
  end
  let(:student_3_question_5_response) do
    '1.[.]usted[,]2.[.]usted[,]4.[.]tú[,]5.[.]usted'
  end
  let(:student_3_question_5_formatted_response) do
    '1. usted 2. usted 4. tú 5. usted'
  end
  let(:student_3_question_5_points) { 0.80 * question_5.points_possible }
  let(:student_3_question_5_overridden_points) { student_3_question_5_points / 2 }
  let(:student_5_question_5_response) do
    '1.[.]usted[,]2.[.]tu[,]4.[.]tú[,]5.[.]usted'
  end
  let(:student_5_question_5_formatted_response) do
    '1. usted 2. tu 4. tú 5. usted'
  end
  let(:student_5_question_5_points) { 0.75 * question_5.points_possible }
  let(:instructor_policy_token) { 'lossless_instructor_token' }

  def validate_question_points_earned(question, student, expected_points)
    @page_object.for_student_answer(question.label, student) do |container|
      if expected_points.blank?
        expect(container.score).to be_blank
      else
        expect(container.score).to eq(expected_points.round(2).to_s)
      end
    end
  end

  def validate_student_grading_in_gradebook(student, expected_score, partial_pending: nil)
    score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
      student.id, section.id, activity.id
    ).first
    if expected_score
      expected_points_earned = expected_score.to_f * activity.points_possible
      expect(score_action.points_earned.to_f).to eq(expected_points_earned.round(2))
      expect(score_action.pending).to be_falsey
      expect(score_action.partial_pending).to eql(partial_pending)
    else
      expect(score_action).to be_nil
    end
  end

  def validate_initial_gradings
    step 'for student 1, it is sum of all the auto-graded interaction score s/he submitted ' \
      ' divided by the number of activities in the smartbook' do
      # unsubmitted instructor-graded question is worth 0 poinhts
      question_3_points_earned = 0
      # points earned for auto-graded question 5
      question_5_score = 70.0 / 100.0
      question_5_points_earned = question_5_score * question_5.points_possible
      # points earned for auto-graded question 6
      question_6_score = 50.0 / 100.0
      question_6_points_earned = question_6_score * question_6.points_possible
      # total number of points earned
      total_points_earned = question_3_points_earned + question_5_points_earned + question_6_points_earned
      # we don't consider the submitted but ungraded instructor-graded questions
      # in the total points possible
      total_points_possible = activity.points_possible -
        question_1.points_possible -
        question_2.points_possible -
        question_4.points_possible
      activity_score = total_points_earned / total_points_possible
      validate_student_grading_in_gradebook(student_1, activity_score, partial_pending: true)
    end

    step 'for student 2, it is 0 because s/he only submitted instructor-graded interactions' do
      total_points_earned = 0
      total_points_possible = activity.points_possible -
        question_1.points_possible -
        question_3.points_possible
      # we don't consider the submitted but ungraded instructor-graded questions
      # in the total points possible
      activity_score = total_points_earned / total_points_possible
      validate_student_grading_in_gradebook(student_2, activity_score, partial_pending: true)
    end

    step 'for student 3, it is the score of the auto-graded interaction s/he submitted' do
      question_5_score = 80.0 / 100.0
      question_5_points_earned = question_5_score * question_5.points_possible
      total_points_earned = question_5_points_earned
      total_points_possible = activity.points_possible
      activity_score = total_points_earned / total_points_possible
      validate_student_grading_in_gradebook(student_3, activity_score)
    end
    step 'student 4 has no grade because he submitted nothing' do
      validate_student_grading_in_gradebook(student_4, nil)
    end

    step 'for student 5, it is the latest score of the auto-graded interaction s/he submitted' do
      question_5_score = 75.0 / 100.0
      question_5_points_earned = question_5_score * question_5.points_possible
      total_points_earned = question_5_points_earned
      total_points_possible = activity.points_possible
      activity_score = total_points_earned / total_points_possible
      validate_student_grading_in_gradebook(student_5, activity_score)
    end
  end

  def start_grading(grading_style)
    column_header(activity).click
    click_link('Grade Activity')
    for_grading_style_page_object do |pobject|
      pobject.grading_style = grading_style
      pobject.start_grading
    end
  end

  RSpec::Matchers.define :not_exist do
    match(&:not_exist?)
  end

  before do
    initialize_fake_submissions_client
    create(:enrollment, section: section, user: student_1)
    create(:enrollment, section: section, user: student_2)
    create(:enrollment, section: section, user: student_3)
    create(:enrollment, section: section, user: student_4)
    create(:enrollment, section: section, user: student_5)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    stub_request(:get, /#{Rails.application.config.lossless_base_url}\/m3\/policy\/.*/)
      .to_return(
        status: 200,
        body: { token: instructor_policy_token }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )

    # student 1 submitted:
    # - auto-graded interactions 1 and 2.
    # - instructor-graded interactions 1 and 2.
    submit_instructor_graded_interaction(
      attempt: attempt,
      interaction: question_1_instructor_graded,
      response: student_1_question_1_response
    )
    submit_instructor_graded_interaction(
      attempt: attempt,
      interaction: question_2_instructor_graded,
      response: student_1_question_2_response
    )
    submit_instructor_graded_interaction(
      attempt: attempt,
      interaction: question_4_audio_recording,
      response: student_1_question_4_response
    )
    submit_auto_graded_interaction(
      attempt: attempt,
      interaction: question_5_auto_graded,
      response: student_1_question_5_response,
      score: { raw: 70, min: 0, max: 100 }
    )
    submit_auto_graded_interaction(
      attempt: attempt,
      interaction: question_6_auto_graded,
      response: student_1_question_6_response,
      score: { raw: 50, min: 0, max: 100 }
    )

    # student 2 submitted:
    # - no auto-graded interaction.
    # - instructor-graded interactions 1 and 3.
    submit_instructor_graded_interaction(
      attempt: attempt_student_2,
      interaction: question_1_instructor_graded,
      response: student_2_question_1_response
    )
    submit_instructor_graded_interaction(
      attempt: attempt_student_2,
      interaction: question_3_instructor_graded,
      response: student_2_question_3_response
    )

    # student 3 submitted:
    # - auto-graded interaction 1.
    # - no instructor-graded interaction.
    submit_auto_graded_interaction(
      attempt: attempt_student_3,
      interaction: question_5_auto_graded,
      response: student_3_question_5_response,
      score: { raw: 80, min: 0, max: 100 }
    )

    # student 4 submitted nothing.
    #
    #
    # student 5 submitted:
    # - auto-graded interaction 1.
    # - no instructor-graded interaction.
    submit_auto_graded_interaction(
      attempt: attempt_student_5,
      interaction: question_5_auto_graded,
      response: student_5_question_5_response,
      score: { raw: 75, min: 0, max: 100 }
    )
  end

  xscenario 'As an instructor, I can grade interactions student by student' do
    visit activities_for_lesson_url
    validate_initial_gradings

    purpose 'I start Student by Student grading' do
      start_grading(:student_by_student)
    end

    student_1_question_1_points = 0.66 * question_2.points_possible
    student_1_question_2_points = 0.33 * question_4.points_possible
    student_2_question_1_points = 0.44 * question_1.points_possible
    student_2_question_3_points = 0.20 * question_3.points_possible

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to eq([
          student_1.full_name,
          student_2.full_name,
          student_3.full_name + ' (graded)',
          student_5.full_name + ' (graded)'
        ])
      end

      purpose 'I see that the first student is selected by default' do
        expect(pobject.selected_student).to eq(student_1.full_name)
        expect_grading_page_to_have_buttons(pobject, %i[next])
      end

      purpose 'I see all the questions student 1 submitted' do
        pobject.for_student_answer(
          question_1_instructor_graded.label, student_1
        ) do |container|
          expect(container.text_response.text).to include(student_1_question_1_response)
          expect(container.score).to be_blank
        end
        pobject.for_student_answer(
          question_2_instructor_graded.label, student_1
        ) do |container|
          expect(container.text_response.text).to include(student_1_question_2_response)
          expect(container.score).to be_blank
        end
        pobject.for_student_answer(
          question_4_audio_recording.label, student_1
        ) do |container|
          container.for_audio_response do |audio|
            expect(audio.source).to eq(student_1_question_4_instructor_audio_source)
            expect(audio.player).not_to be_disabled
          end
          expect(container.score).to be_blank
        end
        pobject.for_student_answer(
          question_5_auto_graded.label, student_1
        ) do |container|
          expect(container.text_response.text).to include(
            student_1_question_5_formatted_response
          )
        end
        pobject.for_student_answer(
          question_6_auto_graded.label, student_1
        ) do |container|
          expect(container).to exist
        end
      end

      purpose 'I do not see the questions student 1 did not submit' do
        [
          question_3_instructor_graded
        ].each do |question|
          pobject.for_student_answer(question.label, student_1) do |container|
            expect(container).to not_exist
          end
        end
      end

      purpose 'I see the score for all the answered questions' do
        {
          question_1_instructor_graded => '',
          question_2_instructor_graded => '',
          question_4_audio_recording => '',
          question_5_auto_graded => 7.0,
          question_6_auto_graded => 5.0
        }.each do |question, score|
          validate_question_points_earned(question, student_1, score)
        end
      end

      purpose 'I partially grade student 1' do
        {
          question_1_instructor_graded => student_1_question_1_points,
          question_2_instructor_graded => student_1_question_2_points
        }.each do |question, score|
          pobject.for_student_answer(question.label, student_1) do |container|
            container.score = score
          end
        end
      end

      purpose 'I select student 2 using the next button' do
        click_button_expect_alert(
          :next, 'You did not enter a grade for 1 question. OK to proceed?'
        )
        expect(pobject.selected_student).to eq(student_2.full_name)
        expect_grading_page_to_have_buttons(pobject, %i[previous next])
      end

      purpose 'I see all the questions student 2 submitted' do
        pobject.for_student_answer(
          question_1_instructor_graded.label, student_2
        ) do |container|
          expect(container.text_response.text).to include(student_2_question_1_response)
        end
        pobject.for_student_answer(
          question_3_instructor_graded.label, student_2
        ) do |container|
          expect(container.text_response.text).to include(student_2_question_3_response)
        end
      end

      purpose 'I do not see the questions student 2 did not submit' do
        [
          question_2_instructor_graded,
          question_4_audio_recording,
          question_5_auto_graded,
          question_6_auto_graded
        ].each do |question|
          pobject.for_student_answer(question.label, student_2) do |container|
            expect(container).to not_exist
          end
        end
      end

      purpose 'I see the score for all the answered questions' do
        {
          question_1_instructor_graded => '',
          question_3_instructor_graded => ''
        }.each do |question, score|
          validate_question_points_earned(question, student_2, score)
        end
      end

      purpose 'I partially grade student 2' do
        {
          question_1_instructor_graded => student_2_question_1_points
        }.each do |question, score|
          pobject.for_student_answer(question.label, student_2) do |container|
            container.score = score
          end
        end
      end

      purpose 'I select student 1 using the previous button' do
        click_button_expect_alert(
          :previous, 'You did not enter a grade for 1 question. OK to proceed?'
        )
        selector = '#student_dropdown_menu option[selected="selected"]'
        Waiter.new.wait do
          page.has_selector?(selector) &&
            page.find(selector).text == student_1.full_name
        end

        expect(pobject.selected_student).to eq(student_1.full_name)
        expect_grading_page_to_have_buttons(pobject, %i[next])
      end

      purpose 'I see the score I already set' do
        {
          question_1_instructor_graded => student_1_question_1_points,
          question_2_instructor_graded => student_1_question_2_points,
          question_4_audio_recording => '',
          question_5_auto_graded => 7.0,
          question_6_auto_graded => 5.0
        }.each do |question, score|
          validate_question_points_earned(question, student_1, score)
        end
      end

      purpose 'I select student 2 using the dropdown' do
        select_student_expect_alert(
          student_2, 'If you exit without saving, all scores will be lost. Ok to exit?'
        )
      end

      purpose 'I finish to grade student 2' do
        pobject.for_student_answer(
          question_3_instructor_graded.label, student_2
        ) do |container|
          container.score = student_2_question_3_points
        end
      end

      purpose 'I select the student 3 using the next button' do
        # I do not see any alert because I fully graded student 2
        pobject.button(:next).click

        expect(pobject.selected_student).to eq(
          student_3.full_name + ' (graded)'
        )

        expect_grading_page_to_have_buttons(pobject, %i[previous next])
      end

      purpose 'I see in the drop down that student 2 has been fully graded' do
        expect(pobject.selectable_students).to eq([
          student_1.full_name,
          student_2.full_name + ' (graded)',
          student_3.full_name + ' (graded)',
          student_5.full_name + ' (graded)'
        ])
      end

      purpose 'I see all the questions student 3 submitted' do
        pobject.for_student_answer(
          question_5_auto_graded.label, student_3
        ) do |container|
          expect(container.text_response.text).to include(
            student_3_question_5_formatted_response
          )
        end
      end

      purpose 'I do not see the questions student 3 did not submit' do
        [
          question_1_instructor_graded,
          question_2_instructor_graded,
          question_3_instructor_graded,
          question_4_audio_recording,
          question_6_auto_graded
        ].each do |question|
          pobject.for_student_answer(question.label, student_3) do |container|
            expect(container).to not_exist
          end
        end
      end

      purpose 'I see the score for all the answered questions' do
        {
          question_5_auto_graded => student_3_question_5_points
        }.each do |question, score|
          validate_question_points_earned(question, student_3, score)
        end
      end

      purpose 'I override the score of an auto-graded question student 3 submitted' do
        pobject.for_student_answer(question_5_auto_graded.label, student_3) do |container|
          container.score = student_3_question_5_overridden_points
        end
      end

      purpose 'I select student 5 that only submitted auto graded questions' do
        pobject.button(:next).click

        expect(pobject.selected_student).to eq(
          student_5.full_name + ' (graded)'
        )
        expect_grading_page_to_have_buttons(pobject, %i[previous done])
      end

      purpose 'I see all the questions student 5 submitted' do
        pobject.for_student_answer(
          question_5_auto_graded.label, student_5
        ) do |container|
          expect(container.text_response.text).to include(
            student_5_question_5_formatted_response
          )
        end
      end

      purpose 'I do not see the questions student 5 did not submit' do
        [
          question_1_instructor_graded,
          question_2_instructor_graded,
          question_3_instructor_graded,
          question_4_audio_recording,
          question_6_auto_graded
        ].each do |question|
          pobject.for_student_answer(question.label, student_5) do |container|
            expect(container).to not_exist
          end
        end
      end

      purpose 'I see the score for all the answered questions' do
        {
          question_5_auto_graded => student_5_question_5_points
        }.each do |question, score|
          validate_question_points_earned(question, student_5, score)
        end
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity.title} has been successfully graded."
        )
      end
    end

    purpose 'students scores in the gradebook are updated' do
      step 'student 1 score has been updated' do
        # unsubmitted instructor-graded question is worth 0 points
        student_1_question_3_points = 0
        # ungraded instructor-graded question
        student_1_question_4_points = 0
        # points earned for auto-graded question 5
        student_1_question_5_points = 0.70 * question_5.points_possible
        # points earned for auto-graded question 6
        student_1_question_6_points = 0.50 * question_6.points_possible
        # total number of points earned
        total_points_earned =
          student_1_question_1_points +
          student_1_question_2_points +
          student_1_question_3_points +
          student_1_question_4_points +
          student_1_question_5_points +
          student_1_question_6_points
        # we don't consider the submitted but ungraded instructor-graded questions
        # in the total points possible
        total_points_possible = activity.points_possible - question_4.points_possible
        activity_score = total_points_earned / total_points_possible
        # All student's submitted instructor-graded interaction have been graded,
        # the partial pending flag should be true
        validate_student_grading_in_gradebook(
          student_1, activity_score, partial_pending: true
        )
      end

      step 'student 2 score has been updated' do
        # total number of points earned: 2 graded instructor-graded questions
        total_points_earned = student_2_question_1_points + student_2_question_3_points
        # All submitted questions have been updated so we use the total points
        # possible of the activity
        total_points_possible = activity.points_possible
        activity_score = total_points_earned / total_points_possible
        # All student's submitted instructor-graded interaction have been graded,
        # partial pending should be false
        validate_student_grading_in_gradebook(student_2, activity_score, partial_pending: false)
      end

      step 'student 3 score has been updated' do
        # total number of points earned
        total_points_earned = student_3_question_5_overridden_points
        # All submitted questions have been updated so we use the total points
        # possible of the activity
        total_points_possible = activity.points_possible
        activity_score = total_points_earned / total_points_possible
        # All student's submitted questions have been graded, partial pending
        # should ne false
        validate_student_grading_in_gradebook(
          student_3,
          activity_score,
          partial_pending: false
        )
      end

      step 'student 4 has no grade because he submitted nothing' do
        validate_student_grading_in_gradebook(student_4, nil)
      end

      step 'student 5 score has been updated' do
        # total number of points earned
        total_points_earned = student_5_question_5_points
        # All submitted questions have been updated so we use the total points
        # possible of the activity
        total_points_possible = activity.points_possible
        activity_score = total_points_earned / total_points_possible
        validate_student_grading_in_gradebook(student_5, activity_score, partial_pending: false)
      end
    end

    purpose 'I start Student by Student grading' do
      start_grading(:student_by_student)
    end

    student_1_question_4_points = 0.26 * question_4.points_possible

    for_grading_student_by_student do |pobject|
      purpose 'I see all the student that have submitted questions' do
        # Note that the students are not sorted by the presenter!
        expect(pobject.selectable_students).to contain_exactly(
          student_1.full_name,
          student_2.full_name + ' (graded)',
          student_3.full_name + ' (graded)',
          student_5.full_name + ' (graded)'
        )
      end

      purpose 'I see the score for student 1 questions already graded' do
        pobject.select_student(student_1)
        {
          question_1_instructor_graded => student_1_question_1_points,
          question_2_instructor_graded => student_1_question_2_points
        }.each do |question, score|
          validate_question_points_earned(question, student_1, score)
        end
      end

      purpose 'I finish to grade student 1' do
        pobject.for_student_answer(question_4_audio_recording.label, student_1) do |container|
          container.score = student_1_question_4_points
        end
      end

      purpose 'I see a success message when I finish the grading' do
        accept_alert do
          pobject.select_last_student
        end
        if ENV['NO_CHROME_UNLOAD'] != 'true'
          pending
        end
        pobject.button(:done).click

        expect_flash_message(
          :notice,
          "#{activity.title} has been successfully graded."
        )
      end
    end

    purpose 'student 1 score in the gradebook has been updated' do
      # unsubmitted instructor-graded question is worth 0 points
      student_1_question_3_points = 0
      # points earned for auto-graded question 5
      student_1_question_5_points = 0.70 * question_5.points_possible
      # points earned for auto-graded question 6
      student_1_question_6_points = 0.50 * question_6.points_possible
      # total number of points earned
      total_points_earned =
        student_1_question_1_points +
        student_1_question_2_points +
        student_1_question_3_points +
        student_1_question_4_points +
        student_1_question_5_points +
        student_1_question_6_points
      # All submitted questions have been updated so we use the total points
      # possible of the activity
      total_points_possible = activity.points_possible
      activity_score = total_points_earned / total_points_possible
      # All student's submitted instructor-graded interaction have been graded,
      # the partial pending flag should be false
      validate_student_grading_in_gradebook(
        student_1, activity_score, partial_pending: false
      )
    end
  end

  xscenario 'As an instructor, I can grade interactions question by question' do
    visit activities_for_lesson_url
    validate_initial_gradings

    purpose 'I start Question by Question grading' do
      start_grading(:question_by_question)
    end

    student_1_question_2_points = 0.76 * question_2.points_possible
    student_1_question_4_points = 0.98 * question_4.points_possible
    student_2_question_1_points = 0.44 * question_1.points_possible
    student_2_question_3_points = 0.50 * question_3.points_possible

    for_grading_question_by_question do |pobject|
      purpose 'I see all the questions in the drop down' do
        expect(pobject.selectable_questions).to eq([
          question_1_instructor_graded.label,
          question_2_instructor_graded.label,
          question_3_instructor_graded.label,
          question_4_audio_recording.label,
          question_5_auto_graded.label + ' (graded)',
          question_6_auto_graded.label + ' (graded)'
        ])
      end

      purpose 'I see that the first question is selected by default' do
        expect(pobject.selected_question).to eq(
          question_1_instructor_graded.label
        )
        expect_grading_page_to_have_buttons(pobject, %i[next])
      end

      purpose 'I see each student that answered question 1' do
        {
          student_1 => student_1_question_1_response,
          student_2 => student_2_question_1_response
        }.each do |student, response|
          pobject.for_student_answer(
            question_1_instructor_graded.label, student
          ) do |container|
            expect(container.text_response.text).to include(response)
          end
        end

        purpose 'I do not see students that did not submit question 2' do
          [student_3, student_4, student_5].each do |student|
            expect(
              pobject.student_answer(question_1_instructor_graded.label, student)
            ).to not_exist
          end
        end
      end

      purpose 'I only grade student 2' do
        pobject.for_student_answer(question_1_instructor_graded.label, student_2) do |container|
          container.score = student_2_question_1_points
        end
      end

      purpose 'I see an alert about 1 ungraded student when selecting question 2 ' \
        'using the next button' do
        click_button_expect_alert(
          :next, 'You did not enter a grade for 1 student. OK to proceed?'
        )
        expect(pobject.selected_question).to eq(
          question_2_instructor_graded.label
        )
        expect_grading_page_to_have_buttons(pobject, %i[previous next])
      end

      purpose 'I see student 1 answer that submitted question 2' do
        {
          student_1 => student_1_question_2_response
        }.each do |student, response|
          pobject.for_student_answer(
            question_2_instructor_graded.label, student
          ) do |container|
            expect(container.text_response.text).to include(response)
          end
        end
      end

      purpose 'I do not see students that did not submit question 2' do
        [student_2, student_3, student_4, student_5].each do |student|
          expect(
            pobject.student_answer(question_2_instructor_graded.label, student)
          ).to not_exist
        end
      end

      purpose 'I grade all students for question 3' do
        pobject.for_student_answer(question_2_instructor_graded.label, student_1) do |container|
          container.score = student_1_question_2_points
        end
      end

      purpose 'I select question 3 using the next button' do
        # Remove after ubuntu 20.04 codebuild image is updated
        # with latest chromedriver.
        if ENV['NO_CHROME_UNLOAD'] != 'true'
          pending
        end

        accept_alert do
          pobject.select_question(question_3_instructor_graded.label)
        end

        selector = 'select.js-jump-to option[selected="selected"]'
        Waiter.new.wait do
          page.has_selector?(selector) &&
            page.find(selector).text == question_3_instructor_graded.label
        end

        expect(pobject.selected_question).to eq(
          question_3_instructor_graded.label
        )
        expect_grading_page_to_have_buttons(pobject, %i[previous next])
      end

      purpose 'I see answers for students that submitted question 3' do
        {
          student_2 => student_2_question_3_response
        }.each do |student, response|
          pobject.for_student_answer(
            question_3_instructor_graded.label, student
          ) do |container|
            expect(container.text_response.text).to include(response)
          end
        end
      end

      purpose 'I do not see students that did not submit question 3' do
        [student_1, student_3, student_4, student_5].each do |student|
          expect(
            pobject.student_answer(question_3_instructor_graded.label, student)
          ).to not_exist
        end
      end

      purpose 'I grade all students for question 3' do
        pobject.for_student_answer(question_3_instructor_graded.label, student_2) do |container|
          container.score = student_2_question_3_points
        end
      end

      purpose 'I do not see any alert when selecting question 2 using the previous ' \
        'button because I graded all the students for question 3' do
        pobject.button(:previous).click
      end

      purpose 'I see the score for students already graded' do
        validate_question_points_earned(
          question_2_instructor_graded, student_1, student_1_question_2_points
        )
      end

      purpose 'I select question 4 using the dropdown' do
        pobject.select_question(question_4_audio_recording.label)
        expect(pobject.selected_question).to eq(
          question_4_audio_recording.label
        )
        expect_grading_page_to_have_buttons(pobject, %i[previous next])
      end

      purpose 'I see student 1 answer for question 4' do
        pobject.for_student_answer(question_4_audio_recording.label, student_1) do |container|
          container.for_audio_response do |audio|
            expect(audio.source).to eq(student_1_question_4_instructor_audio_source)
            expect(audio.player).not_to be_disabled
          end
        end
      end

      purpose 'I do not see students that did not submit question 4' do
        [student_2, student_3, student_4].each do |student|
          expect(
            pobject.student_answer(question_4_audio_recording.label, student)
          ).to not_exist
        end
      end

      purpose 'I grade student 1 for question 4' do
        pobject.for_student_answer(question_4_audio_recording.label, student_1) do |container|
          container.score = student_1_question_4_points
        end
      end

      purpose 'I see in the drop down that question 1 and 3 have been fully graded' do
        # A question does not appears as fully graded dynamically, that's why
        # question 4 is not displayed as graded even if we just set scores for
        # all students.
        expect(pobject.selectable_questions).to eq([
          question_1_instructor_graded.label,
          question_2_instructor_graded.label + ' (graded)',
          question_3_instructor_graded.label + ' (graded)',
          question_4_audio_recording.label,
          question_5_auto_graded.label + ' (graded)',
          question_6_auto_graded.label + ' (graded)'
        ])
      end

      purpose 'I select the question 5' do
        pobject.button(:next).click
        expect(pobject.selected_question).to eq(
          question_5_auto_graded.label + ' (graded)'
        )
        expect_grading_page_to_have_buttons(pobject, %i[previous next])
      end

      purpose 'I see answers for students that submitted question 5' do
        {
          student_1 => student_1_question_5_formatted_response,
          student_3 => student_3_question_5_formatted_response,
          student_5 => student_5_question_5_formatted_response
        }.each do |student, response|
          pobject.for_student_answer(
            question_5_auto_graded.label, student
          ) do |container|
            expect(container.text_response.text).to include(response)
          end
        end
      end

      purpose 'I do not see students that did not submit question 5' do
        [student_2, student_4].each do |student|
          expect(
            pobject.student_answer(question_5_auto_graded.label, student)
          ).to not_exist
        end
      end

      purpose 'I override the score for student 3' do
        pobject.for_student_answer(question_5_auto_graded.label, student_3) do |container|
          container.score = student_3_question_5_overridden_points
        end
      end

      purpose 'I select the question 6' do
        pobject.button(:next).click
        expect(pobject.selected_question).to eq(
          question_6_auto_graded.label + ' (graded)'
        )
        expect_grading_page_to_have_buttons(pobject, %i[previous done])
      end

      purpose 'I see answers for students that submitted question 6' do
        {
          student_1 => student_1_question_6_response,
          student_2 => nil,
          student_3 => nil,
          student_4 => nil,
          student_5 => nil
        }.each do |student, response|
          if response.nil?
            expect(
              pobject.student_answer(question_6_auto_graded.label, student)
            ).to not_exist
          else
            expect(
              pobject.student_answer(question_6_auto_graded.label, student)
            ).to exist
          end
        end
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity.title} has been successfully graded."
        )
      end
    end

    purpose 'students scores in the gradebook are updated' do
      step 'student 1 score has been updated' do
        # ungraded instructor-graded question
        student_1_question_1_points = 0
        # unsubmitted instructor-graded question is worth 0 points
        student_1_question_3_points = 0
        # points earned for auto-graded question 5
        student_1_question_5_points = 0.70 * question_5.points_possible
        # points earned for auto-graded question 6
        student_1_question_6_points = 0.50 * question_6.points_possible
        # total number of points earned
        total_points_earned =
          student_1_question_1_points +
          student_1_question_2_points +
          student_1_question_3_points +
          student_1_question_4_points +
          student_1_question_5_points +
          student_1_question_6_points
        # we don't consider the submitted but ungraded instructor-graded questions
        # in the total points possible
        total_points_possible = activity.points_possible - question_1.points_possible
        activity_score = total_points_earned / total_points_possible
        # All student's submitted instructor-graded interaction have been graded,
        # the partial pending flag should be true
        validate_student_grading_in_gradebook(
          student_1, activity_score, partial_pending: true
        )
      end

      step 'student 2 score has been updated' do
        # total number of points earned: 2 graded instructor-graded questions
        total_points_earned = student_2_question_1_points + student_2_question_3_points
        # All submitted questions have been updated so we use the total points
        # possible of the activity
        total_points_possible = activity.points_possible
        activity_score = total_points_earned / total_points_possible
        # All student's submitted instructor-graded interaction have been graded,
        # partial pending should be false
        validate_student_grading_in_gradebook(student_2, activity_score, partial_pending: false)
      end

      step 'student 3 score has been updated' do
        # total number of points earned
        total_points_earned = student_3_question_5_overridden_points
        # All submitted questions have been updated so we use the total points
        # possible of the activity
        total_points_possible = activity.points_possible
        activity_score = total_points_earned / total_points_possible
        validate_student_grading_in_gradebook(
          student_3, activity_score, partial_pending: false
        )
      end

      step 'student 4 has no grade because s/he submitted nothing' do
        validate_student_grading_in_gradebook(student_4, nil)
      end
    end

    purpose 'I start Question by Question grading' do
      start_grading(:question_by_question)
    end

    student_1_question_1_points = 0.55 * question_1.points_possible

    for_grading_question_by_question do |pobject|
      purpose 'I see all the questions in the drop down' do
        expect(pobject.selectable_questions).to eq([
          question_1_instructor_graded.label,
          question_2_instructor_graded.label + ' (graded)',
          question_3_instructor_graded.label + ' (graded)',
          question_4_audio_recording.label + ' (graded)',
          question_5_auto_graded.label + ' (graded)',
          question_6_auto_graded.label + ' (graded)'
        ])
      end

      purpose 'I see the score for student 2 already graded questions' do
        validate_question_points_earned(
          question_1_instructor_graded, student_2, student_2_question_1_points
        )
      end

      purpose 'I finish to grade question 1' do
        pobject.for_student_answer(question_1_instructor_graded.label, student_1) do |container|
          container.score = student_1_question_1_points
        end
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.select_question(question_6_auto_graded.label)
        pobject.button(:done).click
        expect_flash_message(:notice, "#{activity.title} has been successfully graded.")
      end
    end

    purpose 'student 1 score in the gradebook has been updated' do
      # unsubmitted instructor-graded question is worth 0 points
      student_1_question_3_points = 0
      # points earned for auto-graded question 5
      student_1_question_5_points = 0.70 * question_5.points_possible
      # points earned for auto-graded question 6
      student_1_question_6_points = 0.50 * question_6.points_possible
      # total number of points earned
      total_points_earned =
        student_1_question_1_points +
        student_1_question_2_points +
        student_1_question_3_points +
        student_1_question_4_points +
        student_1_question_5_points +
        student_1_question_6_points
      # All submitted questions have been updated so we use the total points
      # possible of the activity
      total_points_possible = activity.points_possible
      activity_score = total_points_earned / total_points_possible
      # All student's submitted instructor-graded interaction have been graded,
      # the partial pending flag should be false
      validate_student_grading_in_gradebook(
        student_1, activity_score, partial_pending: false
      )
    end
  end

  scenario 'As an instructor, I can grade interactions using spotcheck grading' do
    visit activities_for_lesson_url

    purpose 'I can not start spotcheck grading' do
      column_header(activity).click
      click_link('Grade Activity')
      for_grading_style_page_object do |pobject|
        expect(pobject.available_grading_styles).not_to include(:spotcheck)
      end
    end
  end

  xscenario 'As an instructor, I can review student work' do
    # visit instructor_review_work_grade_path(program, section, student_1, activity)
    visit activities_for_lesson_url

    for_student_grade_modal(student_1, activity) do |modal|
      modal.open
      modal.click_link(:review_student_work)
    end

    student_1_question_1_points = 1.00 * question_1.points_possible
    student_1_question_5_points = 0.70 * question_5.points_possible
    student_1_question_6_points = 0.50 * question_6.points_possible

    for_grading_student_by_student do |pobject|
      purpose 'I see all submitted auto-graded questions and intructor-graded ' \
        'questions in the correct order' do
        # TODO: Check questions order
        pobject.for_student_answer(question_1_instructor_graded.label, student_1) do |container|
          expect(container.text_response.text).to include(student_1_question_1_response)
        end
        pobject.for_student_answer(question_2_instructor_graded.label, student_1) do |container|
          expect(container.text_response.text).to include(student_1_question_2_response)
        end
        pobject.for_student_answer(question_4_audio_recording.label, student_1) do |container|
          container.for_audio_response do |audio|
            expect(audio.source).to eq(student_1_question_4_instructor_audio_source)
            expect(audio.player).not_to be_disabled
          end
        end
        pobject.for_student_answer(question_5_auto_graded.label, student_1) do |container|
          expect(container.text_response.text).to include(student_1_question_5_formatted_response)
        end
        pobject.for_student_answer(question_6_auto_graded.label, student_1) do |container|
          container.for_matching_response do |response|
            with_element(response.entry(1)) do |entry|
              expect(entry.prompt).to eq('1. Who welcomes the pairs?.')
              expect(entry.correct_answer).to eq('La familia Pérez.')
              expect(entry.student_answer).to eq('La familia Pérez.')
            end
            with_element(response.entry(2)) do |entry|
              expect(entry.prompt).to eq('2. Who is Marisa?.')
              expect(entry.correct_answer).to eq('La hija de Carmen y Luis.')
              expect(entry.student_answer).to eq('La hija de Carmen y Luis.')
            end
            with_element(response.entry(3)) do |entry|
              expect(entry.prompt).to eq('3. How do the characters feel?.')
              expect(entry.correct_answer).to eq('Contentos.')
              expect(entry.student_answer).to eq('Muy gracioso.')
            end
            with_element(response.entry(4)) do |entry|
              expect(entry.prompt).to eq('4. How many siblings does Marisa have?.')
              expect(entry.correct_answer).to eq('Dos.')
              expect(entry.student_answer).to eq('Dos.')
            end
            with_element(response.entry(5)) do |entry|
              expect(entry.prompt).to eq('5. What is Mack like?.')
              expect(entry.correct_answer).to eq('Muy gracioso.')
              expect(entry.student_answer).to eq('')
            end
          end
        end
      end

      purpose 'I grade the instructor-graded question 1' do
        pobject.for_student_answer(question_1_instructor_graded.label, student_1) do |container|
          container.score = student_1_question_1_points
        end
      end

      purpose 'I see the score for auto-graded questions' do
        validate_question_points_earned(
          question_5_auto_graded, student_1, student_1_question_5_points
        )
        validate_question_points_earned(
          question_6_auto_graded, student_1, student_1_question_6_points
        )
      end

      purpose 'I can override the score of auto-graded questions' do
        student_1_question_5_points = 0.90 * question_5.points_possible
        student_1_question_6_points = 1.00 * question_6.points_possible

        pobject.for_student_answer(question_5_auto_graded.label, student_1) do |container|
          container.score = student_1_question_5_points
        end
        pobject.for_student_answer(question_6_auto_graded.label, student_1) do |container|
          container.score = student_1_question_6_points
        end
      end

      pobject.button(:done).click
    end

    purpose 'The score for the auto-graded questions has been updated' do
      # ungraded instructor-graded question
      student_1_question_2_points = 0
      # unsubmitted instructor-graded question is worth 0 points
      student_1_question_3_points = 0
      # ungraded instructor-graded question
      student_1_question_4_points = 0
      # total number of points earned
      total_points_earned =
        student_1_question_1_points +
        student_1_question_2_points +
        student_1_question_3_points +
        student_1_question_4_points +
        student_1_question_5_points +
        student_1_question_6_points
      # we don't consider the submitted but ungraded instructor-graded questions
      # in the total points possible
      total_points_possible = activity.points_possible -
        question_2.points_possible - question_4.points_possible
      activity_score = total_points_earned / total_points_possible

      validate_student_grading_in_gradebook(
        student_1, activity_score, partial_pending: true
      )
    end

    visit activities_for_lesson_url

    for_student_grade_modal(student_1, activity) do |modal|
      modal.open
      modal.click_link(:review_student_work)
    end

    for_grading_student_by_student do |pobject|
      purpose 'I can see the score I left for auto-graded questions' do
        validate_question_points_earned(
          question_5_auto_graded, student_1, student_1_question_5_points
        )
        validate_question_points_earned(
          question_6_auto_graded, student_1, student_1_question_6_points
        )
      end
    end
  end

  scenario 'As an instructor, I can validate that the latest attempt is used for the grade of an auto-graded question' do
    visit activities_for_lesson_url

    for_student_grade_modal(student_5, activity) do |modal|
      modal.open
      modal.click_link(:review_student_work)
    end

    student_5_question_5_points_first = 0.75 * question_5.points_possible

    for_grading_student_by_student do |pobject|
      purpose 'I see the score for first attempt on auto-graded question' do
        validate_question_points_earned(
            question_5_auto_graded, student_5, student_5_question_5_points_first
        )
      end
    end
    # student 5 submitted 2nd time, better grade:
    # - auto-graded interaction 1.
    # - improved score
    submit_auto_graded_interaction(
        attempt: attempt_student_5,
        interaction: question_5_auto_graded,
        response: student_5_question_5_response,
        score: { raw: 100, min: 0, max: 100 },
        timestamp: Time.now + 5.minute

    )

    student_5_question_5_points_second = 1.0 * question_5.points_possible

    # Visit gradebook first to check that navigating away from it removes
    # any session state it created.
    visit activities_for_lesson_url

    for_student_grade_modal(student_5, activity) do |modal|
      modal.open
      modal.click_link(:review_student_work)
    end
    for_grading_student_by_student do |pobject|
      purpose 'The score for the auto-graded question has been updated' do
        validate_question_points_earned(
            question_5_auto_graded, student_5, student_5_question_5_points_second
        )
      end
    end
  end
end
