# This spec tests the rendering of different smartbook questions.
feature 'Instructor smartbook questions grading',
  if: DynamoConfig.use_local?,
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

  let(:instructor) { create(:instructor) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:student_3) { create(:student) }
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
  let(:attempt_student_1) do
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
  let(:instructor_policy_token) { 'lossless_instructor_token' }
  let(:smartbook_data) { SmartbookTest::SmartbookData.new }

  def start_grading(grading_style)
    column_header(activity).click
    click_link('Grade Activity')

    for_grading_style_page_object do |pobject|
      pobject.grading_style = grading_style
      pobject.start_grading
    end
  end

  before do
    initialize_fake_submissions_client
    create(:enrollment, section: section, user: student_1)
    create(:enrollment, section: section, user: student_2)
    create(:enrollment, section: section, user: student_3)
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    stub_request(:get, /#{Rails.application.config.lossless_base_url}\/m3\/policy\/.*/)
      .to_return(
        status: 200,
        body: { token: instructor_policy_token }.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
  end

  context 'drawing questions' do
    let(:drawing_question) { smartbook_data.question_10_drawing }

    scenario 'As an instructor, I can review drawing questions' do
      student_1_response = smartbook_data.drawing_response_from_file(
        File.join('spec', 'fixtures', 'smartbooks', 'drawing_image_1.png')
      )
      student_2_response = smartbook_data.drawing_response_from_file(
        File.join('spec', 'fixtures', 'smartbooks', 'drawing_image_2.png')
      )
      student_3_harmful_response = 'data:image/png;base64,"><script class=".harmful_script" type="text/javascript">window.close();</script>'

      submit_instructor_graded_interaction(
        attempt: attempt_student_1,
        interaction: drawing_question,
        response: student_1_response
      )
      submit_instructor_graded_interaction(
        attempt: attempt_student_2,
        interaction: drawing_question,
        response: student_2_response
      )
      submit_instructor_graded_interaction(
        attempt: attempt_student_3,
        interaction: drawing_question,
        response: student_3_harmful_response
      )

      visit activities_for_lesson_url
      start_grading(:question_by_question)

      for_grading_question_by_question do |pobject|
        purpose 'I see the drawing for student 1' do
          pobject.for_student_answer(
            drawing_question.label, student_1
          ) do |container|
            expect(container.drawing_response.image_src).to eq(
              student_1_response
            )
          end
        end

        purpose 'I see the drawing for student 2' do
          pobject.for_student_answer(
            drawing_question.label, student_2
          ) do |container|
            expect(container.drawing_response.image_src).to eq(
              student_2_response
            )
          end
        end

        purpose 'harmful response for student 2 has been escaped' do
          pobject.for_student_answer(
            drawing_question.label, student_3
          ) do |container|
            expect(container.drawing_response.image_src).to eq(
              student_3_harmful_response
            )

            expect(page).to have_no_selector('.harmful_script')
          end
        end
      end
    end
  end
end
