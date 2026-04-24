require 'requests/shared_require_instructor_examples'

feature 'Cartridge Instructor grading', chrome: true, js: true, new_gb_sync: true do
  include RspecJsContentHelpers
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers
  include ActivityTest::MockSubmissions
  include GradebookEngineTest::PageObjects

  let(:school) { create(:school) }
  let!(:context_id) { SecureRandom.hex(10) }
  let!(:cartridge_consumer) { create(:cartridge_consumer, school:) }
  let!(:instructor) { create(:cartridge_instructor, schools: [school]) }
  let!(:contexts_owner) do
    create(:cartridge_contexts_owner, user: instructor, school:)
  end
  let(:student_1) do
    create(:cartridge_student_user_link, school:).user
  end
  let(:student_2) do
    create(:cartridge_student_user_link, school:).user
  end
  let(:program) { create(:program_with_toc_entries) }
  let(:course) do
    create(
      :course,
      first_unit_id: program.units.first.id,
      last_unit_id: program.units.last.id,
      owner: instructor,
      school:,
      program:
    )
  end
  let(:section) { create(:section, course:, instructor:) }
  let(:course_context_detail) do
    create(
      :cartridge_course_context_detail,
      lms_context_id: context_id,
      course:,
      section:,
      school: cartridge_consumer.school,
      program_id: program.id
    )
  end
  let(:lis_outcome_service_url) { course_context_detail.lis_outcome_service_url }
  let(:lesson) { program.units.first.lessons.first }
  let(:strand) { lesson.strands.first }

  let(:activity_1) { create_open_ended_activity(program) }

  let(:activity_2) do
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'mixed_grading_type.xml'),
      program,
      grading_method: 'mixed'
    )
  end

  let(:activity_3) do
    create_activity_with_content(
      File.join('spec', 'fixtures', 'xml', 'dropdown.xml'),
      program,
      grading_method: 'auto'
    )
  end

  let(:activity_4) do
    create_reference_activity_with_reference_groups(program)
  end

  let(:non_credit_category) do
    create(:category, course:, credit_only: false, max_attempts: Random.rand(1..9),
                      weighting_percent: 50)
  end
  let(:credit_category) do
    create(:category, course:, credit_only: true, max_attempts: Random.rand(1..9),
                      weighting_percent: 50)
  end
  let(:fake_submissions) { {} }
  let(:student_1_activity_1_question_1_response) do
    'student 1, activity 1, response for question 1'
  end
  let(:student_1_activity_1_question_2_response) do
    'student 1, activity 1, response for question 2'
  end
  let(:student_1_activity_1_results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity_1.content_object
    ).tap do |results|
      results.add(
        label: 'question_01',
        response: student_1_activity_1_question_1_response
      )
      results.add(
        label: 'question_02',
        response: student_1_activity_1_question_2_response
      )
      results.add(label: 'question_03', response: '')
      results.add(label: 'question_04', response: '')
    end
  end
  let(:student_2_activity_1_question_1_response) do
    'student 2, activity 1, response for question 1'
  end
  let(:student_2_activity_1_question_3_response) do
    'student 2, activity 1, response for question 3'
  end
  let(:student_2_activity_1_results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity_1.content_object
    ).tap do |results|
      results.add(
        label: 'question_01',
        response: student_2_activity_1_question_1_response
      )
      results.add(label: 'question_02', response: '')
      results.add(
        label: 'question_03',
        response: student_2_activity_1_question_3_response
      )
      results.add(label: 'question_04', response: '')
    end
  end
  let(:student_1_activity_2_question_2_response) do
    'student 1, activity 2, response for question 2'
  end
  let(:student_1_activity_2_question_3_response) do
    'student 1, activity 2, response for question 3'
  end
  let(:student_1_activity_2_results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity_2.content_object
    ).tap do |results|
      results.add(label: 'question_01', response: '0')
      results.add(
        label: 'question_02',
        response: student_1_activity_2_question_2_response
      )
      results.add(
        label: 'question_03',
        response: student_1_activity_2_question_3_response
      )
      results.add(label: 'question_04', response: '')
    end
  end
  let(:student_1_activity_3_results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity_2.content_object
    ).tap do |results|
      # Correct
      results.add(label: 'question_01_1', response: '1')
      # Correct
      results.add(label: 'question_02_1', response: '1')
      # Incorrect
      results.add(label: 'question_02_2', response: '1')
      # Blank
      results.add(label: 'question_03_1', response: '0')
    end
  end

  def create_attempt(attrs)
    create(
      :attempt_completed,
      attrs.slice(:activity, :section).merge(user: attrs[:student])
    )
  end

  def validate_student_grading_in_gradebook(
    student, activity, points_earned:, pending:
  )
    score_action = GradebookEngine::CurrentScoreAction.by_user_and_activity(
      student.id, section.id, activity.id
    ).first
    if points_earned
      expect(score_action.points_earned.to_f).to eq(points_earned.round(2))
      expect(score_action.pending).to eq(pending)
    else
      expect(score_action).to be_nil
    end
  end

  def submit_results_for_activity_1
    {
      student_1 => student_1_activity_1_results,
      student_2 => student_2_activity_1_results
    }.each do |student, results|
      attrs = {
        activity: activity_1,
        section:,
        student:
      }
      attempt = create_attempt(attrs)
      create_gradebook_engine_submission(
        **attrs.merge(pending: true, submitted_at: 4.days.ago, time_spent: 1)
      )
      attempt.write_results(results, true)

      create(
        :cartridge_score_destination,
        user: student,
        section:,
        activity: activity_1
      )
    end
  end

  def submit_results_for_activity_2
    {
      student_1 => student_1_activity_2_results
    }.each do |student, results|
      attrs = {
        activity: activity_2,
        section:,
        student:
      }
      attempt = create_attempt(attrs)
      create_gradebook_engine_submission(
        **attrs.merge(pending: false, submitted_at: 4.days.ago, time_spent: 1)
      )
      attempt.write_results(results, true)

      create(
        :cartridge_score_destination,
        user: student,
        section:,
        activity: activity_2
      )
    end
  end

  def submit_results_for_activity_3
    {
      student_1 => student_1_activity_3_results
    }.each do |student, results|
      attrs = {
        activity: activity_3,
        section:,
        student:
      }
      attempt = create_attempt(attrs)
      create_gradebook_engine_submission(
        **attrs.merge(pending: false, submitted_at: 4.days.ago, time_spent: 1)
      )
      attempt.write_results(results, true)

      create(
        :cartridge_score_destination,
        user: student,
        section:,
        activity: activity_3
      )
    end
  end

  def submit_unsubmittable_activity_4
    [student_1, student_2].each do |student|
      attrs = {
        activity: activity_4,
        section:,
        student:,
        points_earned: 1
      }
      attempt = create_attempt(attrs)
      create_gradebook_engine_submission(
        **attrs.merge(pending: false, submitted_at: 4.days.ago, time_spent: 1)
      )
    end
  end

  def stub_post_grade_passback(lis_outcome_service_url)
    stub_request(:post, lis_outcome_service_url)
      .with(headers: { 'Content-Type' => 'application/xml' })
      .to_return(
        status: 200,
        body: <<-XML
        <?xml version="1.0" encoding="UTF-8"?>
        <imsx_POXEnvelopeResponse xmlns = "http://www.imsglobal.org/services/ltiv1p1/xsd/imsoms_v1p0">
          <imsx_POXHeader>
            <imsx_POXResponseHeaderInfo>
              <imsx_version>V1.0</imsx_version>
              <imsx_messageIdentifier>4560</imsx_messageIdentifier>
              <imsx_statusInfo>
                <imsx_codeMajor>success</imsx_codeMajor>
                <imsx_severity>status</imsx_severity>
                <imsx_description>readPerson is not supported</imsx_description>
                <imsx_messageRefIdentifier>999999123</imsx_messageRefIdentifier>
                <imsx_operationRefIdentifier>readPerson</imsx_operationRefIdentifier>
              </imsx_statusInfo>
            </imsx_POXResponseHeaderInfo>
          </imsx_POXHeader>
          <imsx_POXBody/>
        </imsx_POXEnvelopeResponse>
        XML
      )
  end

  def expect_grade_submitted_to_lms(
    lis_outcome_service_url, score:, lis_result_sourcedid:
  )
    expect(a_request(:post, lis_outcome_service_url).with do |req|
      doc = Nokogiri::XML.parse(req.body)
      replace_result_req = doc.xpath(
        '//xmlns:imsx_POXEnvelopeRequest/xmlns:imsx_POXBody/xmlns:replaceResultRequest'
      )
      sourcedid_element = replace_result_req.xpath(
        '//xmlns:resultRecord/xmlns:sourcedGUID/xmlns:sourcedId'
      )
      score_element = replace_result_req.xpath(
        '//xmlns:resultRecord/xmlns:result/xmlns:resultScore/xmlns:textString'
      )

      sourcedid_element.text == lis_result_sourcedid &&
      score_element.text == score.to_s
      # TODO: Instead of "at_least_one", we should check the last request.
    end).to have_been_made.at_least_once
  end

  before do
    initialize_fake_submissions_client
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    stub_post_grade_passback(course_context_detail.lis_outcome_service_url)
    allow(HTTP_AUTHENTICATIONS).to receive(:values).and_return(['secret'])
    allow(Maestro::Enrollment).to receive(:check_licenses).and_return('enrollment_guids' => [])
    allow(Maestro::User).to receive(:ensure_instructor_access_matches_site_license)
    # Visit the launch url to have all the lti parameters saved into the session.
    # But in order to be able to launch an activity, we need to have access to it.
    give_instructor_access_to_toc(activity: activity_1)
    create(:cartridge_resource_link, resource_id: activity_3.id)
    create(:cartridge_resource_link, resource_id: activity_2.id)
    create(:cartridge_resource_link, resource_id: activity_4.id)
    cartridge_resource = create(:cartridge_resource_link, resource_id: activity_1.id)
    url_params = { consumer_guid: cartridge_consumer.guid,
                   context_id:, lti_version: '1.1.0' }
    encoded_launch_params = { launch_params: (JWT.encode url_params, 'secret', 'HS256') }
    visit cartridge_launch_path(
      resource_link_id: cartridge_resource.resource_link_id,
      params: encoded_launch_params
    )

    create(:enrollment, section:, user: student_1)
    create(:enrollment, section:, user: student_2)
    create(
      :assignment,
      assignable: activity_1,
      category: non_credit_category,
      current: true,
      due_date: 2.days.ago.to_date,
      section:
    )
    create(
      :assignment,
      assignable: activity_2,
      category: credit_category,
      current: true,
      due_date: 2.days.ago.to_date,
      section:
    )
    create(
      :assignment,
      assignable: activity_4,
      category: credit_category,
      current: true,
      due_date: 2.days.ago.to_date,
      section:
    )
  end

  scenario 'As a cartridge instructor, I can grade my students SxS' do
    purpose 'I can see and select the View Dashboard link on an unsubmittable activity' do
      visit cartridge_section_activity_path(section.id, activity_1.id)
      find('.test-view-dashboard-link').click
      expect(page).to have_current_path(instructor_grading_styles_path(
                                          program_id: program.id,
                                          activity_id: activity_1.id,
                                          task_type: GradingTask::NEEDS_GRADING
                                        ))
    end

    purpose 'I select Start Grading and see flash message' do
      visit cartridge_section_activity_path(section.id, activity_1.id)
      find('.test-view-dashboard-link').click
      click_on('review')
      expect_flash_message(:error, 'There are currently no submissions to review.')
    end

    purpose 'I can access course content settings' do
      visit cartridge_section_activity_path(section.id, activity_1.id)
      find('.test-view-dashboard-link').click
      click_on('review')
      expect(page).to have_link('Content Settings')
    end

    purpose 'I can access View dashboard link for a submittable that has no attempts' do
      visit cartridge_section_activity_path(section.id, activity_1.id)
      find('.test-view-dashboard-link').click
      expect(page).to have_current_path(instructor_grading_styles_path(
                                          program_id: program.id,
                                          activity_id: activity_1.id,
                                          task_type: GradingTask::NEEDS_GRADING
                                        ))
    end

    purpose 'I submit students activities' do
      submit_results_for_activity_1
      submit_results_for_activity_2
      submit_results_for_activity_3
    end

    purpose 'I click View dashboard link' do
      visit cartridge_section_activity_path(section.id, activity_1.id)
      find('.test-view-dashboard-link').click
      expect(page).to have_current_path(instructor_grading_styles_path(
                                          program_id: program.id,
                                          activity_id: activity_1.id,
                                          task_type: GradingTask::NEEDS_GRADING
                                        ))
    end

    purpose 'I start grading activity 1' do
      visit cartridge_instructor_section_grading_path(section.id, activity_1.id)

      for_grading_style_page_object do |pobject|
        pobject.grading_style = :student_by_student
        pobject.start_grading
      end
    end

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to contain_exactly(
          student_1.full_name,
          student_2.full_name
        )
      end

      purpose 'I see all the questions student 1 submitted' do
        pobject.for_student_answer('question_01', student_1) do |container|
          expect(container.text_response.text).to include(
            student_1_activity_1_question_1_response
          )
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_02', student_1) do |container|
          expect(container.text_response.text).to include(
            student_1_activity_1_question_2_response
          )
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_03', student_1) do |container|
          expect(container.text_response.text).to include('No student response')
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_04', student_1) do |container|
          expect(container.text_response.text).to include('No student response')
          expect(container.score).to be_blank
        end
      end

      purpose 'I partially grade student 1' do
        pobject.student_answer('question_01', student_1).score = 9.0
      end

      purpose 'I select student 2' do
        click_button_expect_alert(
          :next, 'You did not enter a grade for 3 questions. OK to proceed?'
        )
        expect(pobject.selected_student).to eq(student_2.full_name)
        expect_grading_page_to_have_buttons(pobject, %i[previous done])
      end

      purpose 'I see all the questions student 2 submitted' do
        pobject.for_student_answer('question_01', student_2) do |container|
          expect(container.text_response.text).to include(
            student_2_activity_1_question_1_response
          )
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_02', student_2) do |container|
          expect(container.text_response.text).to include('No student response')
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_03', student_2) do |container|
          expect(container.text_response.text).to include(
            student_2_activity_1_question_3_response
          )
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_04', student_2) do |container|
          expect(container.text_response.text).to include('No student response')
          expect(container.score).to be_blank
        end
      end

      purpose 'I fully grade student 2' do
        {
          'question_01' => 10.0,
          'question_02' => 9.0,
          'question_03' => 8.0,
          'question_04' => 7.0
        }.each do |question_label, score|
          pobject.student_answer(question_label, student_2).score = score
        end
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_1.title} has been successfully graded."
        )
        expect(page).to have_current_path(cartridge_section_activity_path(section, activity_1))
      end
    end

    purpose 'Scores in the gradebook are updated' do
      validate_student_grading_in_gradebook(
        student_1, activity_1, points_earned: 0.0, pending: true
      )
      points_earned = 10.0 + 9.0 + 8.0 + 7.0
      validate_student_grading_in_gradebook(
        student_2, activity_1, points_earned:, pending: false
      )
    end

    purpose 'A grade passback has been sent for student 2' do
      score_dest = Cartridge::ScoreDestination.find_by_user_section_activity(
        user: student_2,
        section: section.id,
        activity: activity_1.id
      )

      expect_grade_submitted_to_lms(
        lis_outcome_service_url,
        lis_result_sourcedid: score_dest.lis_result_sourcedid,
        score: (10.0 + 9.0 + 8.0 + 7.0) / activity_1.points_possible
      )
      # TODO: Check that student 1 has not been updated
      WebMock.reset_executed_requests!
    end

    purpose 'I finish grading activity 1' do
      visit cartridge_instructor_section_grading_path(section.id, activity_1.id)

      for_grading_style_page_object do |pobject|
        pobject.grading_style = :student_by_student
        pobject.start_grading
      end
    end

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to contain_exactly(
          student_1.full_name,
          student_2.full_name + ' (graded)'
        )
      end

      purpose 'I see the score for the questions I already graded' do
        expect(pobject.student_answer('question_01', student_1).score).to eq('9.0')
        expect(pobject.student_answer('question_02', student_1).score).to be_blank
        expect(pobject.student_answer('question_03', student_1).score).to be_blank
        expect(pobject.student_answer('question_04', student_1).score).to be_blank
      end

      purpose 'I finish to grade student 1' do
        {
          'question_02' => 5.0,
          'question_03' => 6.0,
          'question_04' => 7.0
        }.each do |question_label, score|
          pobject.student_answer(question_label, student_1).score = score
        end

        pobject.button(:next).click
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_1.title} has been successfully graded."
        )
      end
    end

    purpose 'Scores in the gradebook are updated' do
      points_earned = 9.0 + 5.0 + 6.0 + 7.0
      validate_student_grading_in_gradebook(
        student_1, activity_1, points_earned:, pending: false
      )
      points_earned = 10.0 + 9.0 + 8.0 + 7.0
      validate_student_grading_in_gradebook(
        student_2, activity_1, points_earned:, pending: false
      )
    end

    purpose 'A grade passback has been sent for student 1' do
      score_dest = Cartridge::ScoreDestination.find_by_user_section_activity(
        user: student_1,
        section: section.id,
        activity: activity_1.id
      )

      expect_grade_submitted_to_lms(
        lis_outcome_service_url,
        lis_result_sourcedid: score_dest.lis_result_sourcedid,
        score: (9.0 + 5.0 + 6.0 + 7.0) / activity_1.points_possible
      )
      # TODO: Check that student 2 has not been updated
      WebMock.reset_executed_requests!
    end

    purpose 'I start grading activity 2' do
      visit cartridge_instructor_section_grading_path(section.id, activity_2.id)

      for_grading_style_page_object do |pobject|
        pobject.grading_style = :student_by_student
        pobject.show_auto_graded_questions
        pobject.start_grading
      end
    end

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to contain_exactly(
          student_1.full_name + ' (graded)'
        )
      end

      purpose 'I see all the questions student 1 submitted' do
        pobject.for_student_answer('question_01', student_1) do |container|
          expect(container.score).to eq('0.0')
        end
        pobject.for_student_answer('question_02', student_1) do |container|
          expect(container.text_response.text).to include(
            student_1_activity_2_question_2_response
          )
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_03', student_1) do |container|
          expect(container.text_response.text).to include(
            student_1_activity_2_question_3_response
          )
          expect(container.score).to be_blank
        end
        pobject.for_student_answer('question_04', student_1) do |container|
          expect(container.text_response.text).to include('No student response')
          expect(container.score).to be_blank
        end
      end

      purpose 'I partially grade student 1' do
        pobject.student_answer('question_01', student_1).score = 1.0
        pobject.student_answer('question_02', student_1).score = 4.0
        pobject.student_answer('question_03', student_1).score = 5.0
        pobject.student_answer('question_04', student_1).score = 6.0
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_2.title} has been successfully graded."
        )
      end
    end

    purpose 'Scores in the gradebook are updated' do
      points_earned = 1.0 + 4.0 + 5.0 + 6.0
      validate_student_grading_in_gradebook(
        student_1, activity_2, points_earned:, pending: false
      )
    end

    purpose 'A grade passback has been sent for student 1' do
      score_dest = Cartridge::ScoreDestination.find_by_user_section_activity(
        user: student_1,
        section: section.id,
        activity: activity_2.id
      )

      expect_grade_submitted_to_lms(
        lis_outcome_service_url,
        lis_result_sourcedid: score_dest.lis_result_sourcedid,
        score: (1.0 + 4.0 + 5.0 + 6.0) / activity_2.points_possible
      )
      # TODO: Check that student 2 has not been updated
      WebMock.reset_executed_requests!
    end
  end

  xscenario 'As a cartridge instructor, I can grade my students QxQ' do
    purpose 'I submit students activities' do
      submit_results_for_activity_1
      submit_results_for_activity_2
      submit_results_for_activity_3
    end

    purpose 'I start grading activity 1' do
      visit cartridge_instructor_section_grading_path(section.id, activity_1.id)

      for_grading_style_page_object do |pobject|
        pobject.grading_style = :question_by_question
        pobject.start_grading
      end
    end

    for_grading_question_by_question do |pobject|
      purpose 'I see all the questions in the drop down' do
        expect(pobject.selectable_questions).to contain_exactly(
          'question_01',
          'question_02',
          'question_03',
          'question_04'
        )
      end

      purpose 'I see all students responses for question 1' do
        pobject.select_question('question_01')
        {
          student_1 => student_1_activity_1_question_1_response,
          student_2 => student_2_activity_1_question_1_response
        }.each do |student, response|
          expect(
            pobject.student_answer('question_01', student).text_response.text
          ).to include(response)
        end
      end

      purpose 'I grade question 1' do
        {
          student_1 => 5.0,
          student_2 => 10.0
        }.each do |student, score|
          pobject.student_answer('question_01', student).score = score
        end
        pobject.button(:next).click
      end

      purpose 'I see all students responses for question 2' do
        # Remove after ubuntu 20.04 codebuild image is updated
        # with latest chromedriver.
        pending if ENV['NO_CHROME_UNLOAD'] != 'true'
        {
          student_1 => student_1_activity_1_question_2_response,
          student_2 => 'No student response'
        }.each do |student, response|
          expect(
            pobject.student_answer('question_02', student).text_response.text
          ).to include(response)
        end
      end

      purpose 'I grade question 2 only for student 1' do
        pobject.student_answer('question_02', student_1).score = 10.0
      end

      purpose 'I see an alert message when selecting question 3' do
        select_question_expect_alert(
          'question_03',
          'If you exit without saving, all scores will be lost. Ok to exit?'
        )
      end

      purpose 'I see all students responses for question 3' do
        {
          student_1 => 'No student response',
          student_2 => student_2_activity_1_question_3_response
        }.each do |student, response|
          expect(
            pobject.student_answer('question_03', student).text_response.text
          ).to include(response)
        end
      end

      purpose 'I grade question 3' do
        {
          student_1 => 10.0,
          student_2 => 10.0
        }.each do |student, score|
          pobject.student_answer('question_03', student).score = score
        end
      end

      purpose 'I see all students responses for question 4' do
        select_question_expect_alert(
          'question_04',
          'If you exit without saving, all scores will be lost. Ok to exit?'
        )
        {
          student_1 => 'No student response',
          student_2 => 'No student response'
        }.each do |student, response|
          expect(
            pobject.student_answer('question_04', student).text_response.text
          ).to include(response)
        end
      end

      purpose 'I grade question 4' do
        {
          student_1 => 0.0,
          student_2 => 0.0
        }.each do |student, score|
          pobject.student_answer('question_04', student).score = score
        end
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_1.title} has been successfully graded."
        )
      end
    end

    purpose 'Scores in the gradebook are updated' do
      points_earned = 5.0 + 10.0 + 10.0 + 0.0
      validate_student_grading_in_gradebook(
        student_1, activity_1, points_earned:, pending: false
      )
    end

    purpose 'A grade passback has been sent for student 1' do
      score_dest = Cartridge::ScoreDestination.find_by_user_section_activity(
        user: student_1,
        section: section.id,
        activity: activity_1.id
      )

      expect_grade_submitted_to_lms(
        lis_outcome_service_url,
        lis_result_sourcedid: score_dest.lis_result_sourcedid,
        score: (5.0 + 10.0 + 10.0 + 0.0) / activity_1.points_possible
      )
      # TODO: Check that student 2 has not been updated
      WebMock.reset_executed_requests!
    end

    purpose 'I finish to grade activity 1' do
      visit cartridge_instructor_section_grading_path(section.id, activity_1.id)

      for_grading_style_page_object do |pobject|
        pobject.grading_style = :question_by_question
        pobject.start_grading
      end
    end

    for_grading_question_by_question do |pobject|
      purpose 'I see all the questions in the drop down' do
        expect(pobject.selectable_questions).to contain_exactly(
          'question_01 (graded)',
          'question_02',
          'question_03 (graded)',
          'question_04 (graded)'
        )
      end

      purpose 'I see the score for question 1 that I already graded' do
        expect(pobject.student_answer('question_01', student_1).score).to eq('5.0')
        expect(pobject.student_answer('question_01', student_2).score).to eq('10.0')
      end

      purpose 'I see the score for question 2 that I already graded' do
        pobject.select_question('question_02')
        expect(pobject.student_answer('question_02', student_1).score).to eq('10.0')
        expect(pobject.student_answer('question_02', student_2).score).to be_blank
      end

      purpose 'I finish to grade question 2' do
        pobject.select_question('question_02')
        pobject.student_answer('question_02', student_2).score = 7.0
      end

      purpose 'I see the score for question 3 that I already graded' do
        pobject.select_question('question_03')
        expect(pobject.student_answer('question_03', student_1).score).to eq('10.0')
        expect(pobject.student_answer('question_03', student_2).score).to eq('10.0')
      end

      purpose 'I see the score for question 4 that I already graded' do
        pobject.select_question('question_04')
        expect(pobject.student_answer('question_04', student_1).score).to eq('0.0')
        expect(pobject.student_answer('question_04', student_2).score).to eq('0.0')
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_1.title} has been successfully graded."
        )
      end
    end

    purpose 'Scores in the gradebook are updated' do
      points_earned = 5.0 + 10.0 + 10.0 + 0.0
      validate_student_grading_in_gradebook(
        student_1, activity_1, points_earned:, pending: false
      )
      points_earned = 10.0 + 7.0 + 10.0 + 0.0
      validate_student_grading_in_gradebook(
        student_2, activity_1, points_earned:, pending: false
      )
    end

    purpose 'A grade passback has been sent for student 2' do
      score_dest = Cartridge::ScoreDestination.find_by_user_section_activity(
        user: student_2,
        section: section.id,
        activity: activity_1.id
      )

      expect_grade_submitted_to_lms(
        lis_outcome_service_url,
        lis_result_sourcedid: score_dest.lis_result_sourcedid,
        score: (10.0 + 7.0 + 10.0 + 0.0) / activity_1.points_possible
      )
      # TODO: Check that student 1 has not been updated
      WebMock.reset_executed_requests!
    end
  end

  scenario 'As a cartridge instructor, I can override the grade of an ' \
           'auto-graded activity' do
    create(
      :assignment,
      assignable: activity_3,
      category: credit_category,
      current: true,
      due_date: 2.days.ago.to_date,
      section:
    )

    purpose 'I submit students activities' do
      submit_results_for_activity_1
      submit_results_for_activity_2
      submit_results_for_activity_3
    end

    purpose 'I start grading activity 3' do
      visit cartridge_instructor_section_grading_path(section.id, activity_3.id)

      for_grading_style_page_object do |pobject|
        pobject.grading_style = :student_by_student
        pobject.start_grading
      end
    end

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to contain_exactly(
          student_1.full_name + ' (graded)'
        )
      end

      purpose 'I see all the questions student 1 submitted' do
        pobject.for_student_answer('question_01', student_1) do |container|
          expect(container.score).to eq('2.0')
        end
        pobject.for_student_answer('question_02', student_1) do |container|
          expect(container.score).to eq('2.0')
        end
        pobject.for_student_answer('question_03', student_1) do |container|
          expect(container.score).to eq('0.0')
        end
      end

      purpose 'I override the scores' do
        pobject.student_answer('question_02', student_1).score = 3.0
        pobject.student_answer('question_03', student_1).score = 1.0
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_3.title} has been successfully graded."
        )
        expect(page).to have_current_path(cartridge_section_activity_path(section, activity_3))
      end
    end

    purpose 'Scores in the gradebook are updated' do
      points_earned = 2.0 + 3.0 + 1.0
      validate_student_grading_in_gradebook(
        student_1, activity_3, points_earned:, pending: false
      )
    end

    purpose 'A grade passback has been sent for student 1' do
      score_dest = Cartridge::ScoreDestination.find_by_user_section_activity(
        user: student_1,
        section: section.id,
        activity: activity_3.id
      )

      expect_grade_submitted_to_lms(
        lis_outcome_service_url,
        lis_result_sourcedid: score_dest.lis_result_sourcedid,
        score: (2.0 + 3.0 + 1.0) / activity_3.points_possible
      )
    end
  end

  scenario 'As a cartridge instructor, I can grade an unassigned activity' do
    purpose 'I submit student activities' do
      submit_results_for_activity_3
    end

    purpose 'I start grading activity 3' do
      visit cartridge_instructor_section_grading_path(section.id, activity_3.id)
      for_grading_style_page_object do |pobject|
        pobject.grading_style = :student_by_student
        pobject.start_grading
      end
    end

    for_grading_student_by_student do |pobject|
      purpose 'I see all the students that have submitted a question' do
        expect(pobject.selectable_students).to contain_exactly(
          student_1.full_name + ' (graded)'
        )
      end

      purpose 'I see all the questions student 1 submitted' do
        pobject.for_student_answer('question_01', student_1) do |container|
          expect(container.score).to eq('2.0')
        end
        pobject.for_student_answer('question_02', student_1) do |container|
          expect(container.score).to eq('2.0')
        end
        pobject.for_student_answer('question_03', student_1) do |container|
          expect(container.score).to eq('0.0')
        end
      end

      purpose 'I override the scores' do
        pobject.student_answer('question_02', student_1).score = 3.0
        pobject.student_answer('question_03', student_1).score = 1.0
      end

      purpose 'I see a success message when I finish the grading' do
        pobject.button(:done).click
        expect_flash_message(
          :notice,
          "#{activity_3.title} has been successfully graded."
        )
        expect(page).to have_current_path(cartridge_section_activity_path(section, activity_3))
      end
    end

    purpose 'Scores in the gradebook are updated' do
      points_earned = 2.0 + 3.0 + 1.0
      validate_student_grading_in_gradebook(
        student_1, activity_3, points_earned:, pending: false
      )
    end
  end

  scenario 'As a cartridge instructor, I can change a course settings' do
    purpose 'I submit students activities' do
      submit_results_for_activity_2
    end

    purpose 'I see the course settings link' do
      visit cartridge_instructor_section_grading_path(section.id, activity_2.id)
      expect(page).to have_link('Content Settings')
    end

    purpose 'I see the current course settings' do
      first_category = course.reload.categories.first
      current_scoring_ruleset = first_category.current_scoring_ruleset
      click_link('Content Settings')
      with_element(CartridgeCourseSettingsPageObject.new(page)) do |pobject|
        expect(pobject).to have_scrollable_modal
        expect(pobject.direction_line).to eq 'These settings apply to all applicable activities.'
        expect(pobject.number_of_attempts).to eq first_category.max_attempts
        expect(pobject.require_accent_strictness?).to eq !current_scoring_ruleset.ignore_accents
        expect(pobject.require_punctuation_strictness?).to eq !current_scoring_ruleset.ignore_punctuation
        expect(pobject.require_capitalization_strictness?).to eq !current_scoring_ruleset.ignore_capitalization
        expect(pobject.course_end_date).to eq course.end_date
      end
    end

    purpose 'I can change the course settings' do
      new_max_attempts = -1
      new_require_accents = true
      new_require_punctuation = true
      new_require_capitalization = true
      new_course_end_date = course.end_date + 10.days
      with_element(CartridgeCourseSettingsPageObject.new(page)) do |pobject|
        pobject.number_of_attempts = new_max_attempts
        pobject.require_accent_strictness = new_require_accents
        pobject.require_punctuation_strictness = new_require_punctuation
        pobject.require_capitalization_strictness = new_require_capitalization
        pobject.course_end_date = new_course_end_date
        pobject.submit
      end
      click_link('Content Settings')
      with_element(CartridgeCourseSettingsPageObject.new(page)) do |pobject|
        expect(pobject.number_of_attempts).to eq new_max_attempts
        expect(pobject.require_accent_strictness?).to eq new_require_accents
        expect(pobject.require_punctuation_strictness?).to eq new_require_punctuation
        expect(pobject.require_capitalization_strictness?).to eq new_require_capitalization
        expect(pobject.course_end_date).to eq new_course_end_date
      end
      first_category = course.reload.categories.first
      current_scoring_ruleset = first_category.current_scoring_ruleset
      expect(first_category.max_attempts).to eq new_max_attempts
      expect(current_scoring_ruleset.ignore_accents).to eq !new_require_accents
      expect(current_scoring_ruleset.ignore_punctuation).to eq !new_require_punctuation
      expect(current_scoring_ruleset.ignore_capitalization).to eq !new_require_capitalization
      expect(course.end_date).to eq new_course_end_date
      expect(page).to have_current_path(instructor_grading_styles_path(
                                          program.id,
                                          activity_2.id,
                                          task_type: 'needs_grading_section'
                                        ))
    end
  end

  scenario 'As a cartridge instructor, I can access student interaction settings' do
    purpose 'I see the student interaction settings link' do
      visit cartridge_instructor_section_grading_path(section.id, activity_2.id)
      expect(page).to have_link('Student Interaction Settings')
    end

    purpose 'I can access the student interaction settings page' do
      click_link('Student Interaction Settings')
      expect(page).to have_current_path(
        section_student_settings_show_path(
          program_id: program.id,
          section_id: section.id
        )
      )
    end
  end

  scenario "As a cartridge instructor I can't spotcheck student work" do
    purpose "I don't see spotcheck student work radio button" do
      visit cartridge_instructor_section_grading_path(section.id, activity_1.id)

      expect(page).not_to have_selector('.test-spotcheck-button')
    end
  end

  scenario "As a cartridge instructor I can't ask for help" do
    purpose "I don't see need help link" do
      visit cartridge_instructor_section_grading_path(section.id, activity_1.id)

      expect(page).not_to have_selector('.test-need-help-link')
    end
  end

  scenario 'As a cartridge instructor, I see the View Dashboard link ' \
           'on an unsubmittable activity' do
    purpose 'I submit student results with default score' do
      submit_unsubmittable_activity_4
      validate_student_grading_in_gradebook(
        student_1, activity_4, points_earned: 1.0, pending: false
      )
    end

    purpose 'I can access the View Dashboard from an unsubmittable activity' do
      visit cartridge_section_activity_path(section.id, activity_4.id)
      expect(page).to have_selector('.test-view-dashboard-link')
    end
  end
end
