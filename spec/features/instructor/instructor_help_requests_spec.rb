# TODO: When wee try to remove the test_debt flag, we should add a test
# that execises opening a help request for a completed Formative Diagnostic V2 Practice Test.
# This is to make sure we cover the bug reported in https://vistahl.atlassian.net/browse/MAE-65258
feature 'Instructor help requests', js: true, chrome: true, new_gb_sync: true, test_debt: true do
  include RspecJsCommonHelpers
  include RspecJsContentHelpers
  include RspecJsApiHelpers
  include GradebookEngineHelpers

  let(:harmful_comment) { '<script type="text/javascript">window.close();</script>blah' }

  let(:lesson_1) { create(:lesson) }
  let(:lesson_2) { create(:lesson) }
  let(:school) { create(:school) }
  let!(:program) { create(:program, title: 'My Program') }
  let(:instructor) { create(:instructor, schools: [school]) }
  let(:strands) do
    {
      strand_a_attrs: { title: 'Strand 1' }
    }
  end
  let(:unit_1) { create(:unit, program: program, name: 'Lesson 1', rank: 0) }
  let(:unit_2) { create(:unit, program: program, name: 'Lesson 2', rank: 0) }
  let(:unit_3) { create(:unit, program: program, name: 'Lesson 3', rank: 2) }
  let!(:course) do
    create(
      :course,
      program: program,
      school: school,
      owner: instructor,
      first_unit_id: unit_1.id,
      last_unit_id: unit_3.id,
      allows_review_requests: true,
      allows_help_requests: true
    )
  end
  let!(:section) { create(:section, course: course, instructor: instructor) }
  let!(:activity_1) { create_multiple_choice_activity(program) }
  let!(:activity_2) { create_multiple_choice_activity(program) }
  let!(:activity_3) { create_multiple_choice_activity(program) }
  let(:student_1) { create(:student) }
  let(:student_2) { create(:student) }
  let(:category) { create(:category, course: course) }

  def create_help_request(args)
    create(
      :help_request,
      activity: args[:activity],
      user: args[:student],
      student_comment: args[:student_comment],
      request_type: "request_#{args[:type]}"
    )
  end

  def create_concepts_for_toc_entries(lesson)
    lesson.strands.each_with_index do |strand, index|
      create_concept_matching_strand_id(
        strand,
        name: strand.title,
        rank: index,
        assessment: true,
        lesson: lesson,
        program: program
      )
    end
  end

  def create_lesson_toc_entries(lesson, n = 1)
    toc_entries = Array.new(n) do |index|
      create(
        :toc_entry,
        strands[strands.keys[index]].merge(
          assessment: true
        )
      )
    end
    lesson.toc_entries = toc_entries
    lesson.save!
    create_concepts_for_toc_entries(lesson)
  end

  def create_submission_and_score(args)
    create_gradebook_engine_submission(
      args.merge(submitted_at: 0.days.ago)
    )
  end

  def create_attempt(args)
    create(:attempt_submitted, args.merge(submission_id: 1))
  end

  def assign_activity(activity)
    default_attrs = {
      category: category,
      due_date: 2.days.from_now.to_date,
      section: section,
      show_at: 1.day.ago
    }
    create(:assignment, default_attrs.merge(assignable: activity))
  end

  def visit_requests_page(args)
    within(header_selector(args)) do
      within('h3') do
        find('a').click
      end
    end
  end

  def expect_active_tab(args)
    expect(page).to have_selector(
      "#{header_selector(args)}.expanded.program-header-bar"
    )
  end

  def header_selector(args)
    "li##{args[:processed] ? '' : 'un'}processed_#{args[:type]}_request_header"
  end

  def active_tab_header(args)
    "##{args[:processed] ? '' : 'un'}processed_#{args[:type]}_request_list"
  end

  def expect_request_count(args)
    component_id =  "##{args[:processed] ? '' : 'un'}processed_#{args[:type]}_request_count"
    expect(page).to have_selector(component_id, text: args[:number])
  end

  def expect_instructor_comment(args)
    expect(page).to have_text(args[:name])
    expect(page).to have_selector('.instructor_responded_date')
    expect(page).to have_text(args[:comment])
  end

  def expect_lesson_name(args)
    expect(page).to have_text(args[:lesson])
    expect(page).to have_text(args[:strand])
  end

  def expect_activity_name(activity)
    expect(page).to have_text(activity.title)
  end

  def return_to_requests
    find('.test-activity_return_link').click
  end

  def click_respond_to_request_button(n = 0)
    page.all('input.red-button')[n].click
  end

  def click_edit_response_link(n = 0)
    page.all('a.edit_request')[n].click
  end

  def enter_response(comment, n = 0)
    page.all(:fillable_field, 'instructor_comment')[n].set(comment)
  end

  def expect_student_request(args)
    expect(page).to have_selector(
      'a.student_name_link',
      text: "#{args[:student].first_name} #{args[:student].last_name}"
    )
    expect(page).to have_selector('span.request_count', text: args[:request])
  end

  def expect_student_name(student)
    expect(page).to have_text(
      "#{student.first_name} #{student.last_name}"
    )
  end

  before do
    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)

    allow(SubmissionClient::Submission).to receive(:find).and_return(
      [
        SubmissionClient::Submission.new(
          'id' => 1,
          'data' => {
            'question_01' => '',
            'question_02' => ''
          }
        )
      ]
    )
  end

  scenario 'Instructor help requests' do
    step 'database setup' do
      create_lesson_toc_entries(lesson_1, 1)
      create_lesson_toc_entries(lesson_2, 1)
      create(:active_enrollment, section: section, user: student_1)

      step 'Student 1 leaves a help request on question 1' \
           'of "activity 1", with comment "hr_s1_a1_c1"' do
        create_help_request(
          activity: activity_1,
          student: student_1,
          student_comment: 'hr_s1_a1_c1',
          type: 'help'
        )
      end

      step 'Student 1 leaves a help request on question 1' \
           'of "activity 1", with comment "hr_s1_a1_c2"' do
        create_help_request(
          activity: activity_1,
          student: student_1,
          student_comment: 'hr_s1_a1_c2',
          type: 'help'
        )
      end

      step 'Student 1 leaves a help request on question 1' \
           'of "activity 2", with comment "hr_s1_a2_c1"' do
        create_help_request(
          activity: activity_2,
          student: student_1,
          student_comment: 'hr_s1_a2_c1',
          type: 'help'
        )
      end

      step 'Student 1 completes "activity 1"' do
        create_attempt(user: student_1, section: section, activity: activity_1)
        assign_activity(activity_1)
        submission_hash = {
          activity: activity_1,
          pending: false,
          student: student_1
        }
        create_submission_and_score(submission_hash)
      end

      step 'Student 1 leaves a score review on question 1' \
           'of "activity 1" with comment "sr_s1_a1_c1"' do
        create_help_request(
          activity: activity_1,
          student: student_1,
          student_comment: 'sr_s1_a1_c1',
          type: 'review'
        )
      end

      step 'Student 1 leaves a score review on question 1' \
           'of "activity 1" with comment "sr_s1_a1_c2"' do
        create_help_request(
          activity: activity_1,
          student: student_1,
          student_comment: 'sr_s1_a1_c2',
          type: 'review'
        )
      end

      step 'Student 1 completes "activity 2"' do
        create_attempt(user: student_1, section: section, activity: activity_2)
        assign_activity(activity_2)
        create_submission_and_score(
          activity: activity_2,
          pending: false,
          student: student_1
        )
      end

      step 'Student 1 leaves a score review on question 1' \
           'of "activity 2" with comment "sr_s1_a2_c1"' do
        create_help_request(
          activity: activity_2,
          student: student_1,
          student_comment: 'sr_s1_a2_c1',
          type: 'review'
        )
      end

      create(:active_enrollment, section: section, user: student_2)

      step 'Student 2 leaves a help request on question 1' \
           'of "activity 1", with comment "hr_s2_a1_c1"' do
        create_help_request(
          activity: activity_1,
          student: student_2,
          student_comment: 'hr_s2_a1_c1',
          type: 'help'
        )
      end

      step 'Student 2 leaves a help request on question 1' \
           'of "activity 3", with comment "hr_s2_a3_c1"' do
        create_help_request(
          activity: activity_3,
          student: student_2,
          student_comment: 'hr_s2_a3_c1',
          type: 'help'
        )
      end

      step 'Student 2 completes "activity 1"' do
        create_attempt(user: student_2, section: section, activity: activity_1)
        create_submission_and_score(
          activity: activity_1,
          pending: false,
          student: student_2
        )
      end

      step 'Student 2 leaves a score review on question 1' \
           'of "activity 1" with comment "sr_s2_a1_c1"' do
        create_help_request(
          activity: activity_1,
          student: student_2,
          student_comment: 'sr_s2_a1_c1',
          type: 'review'
        )
      end

      step 'Student 2 completes "activity 3"' do
        create_attempt(user: student_2, section: section, activity: activity_3)
        assign_activity(activity_3)
        create_submission_and_score(
          activity: activity_3,
          pending: false,
          student: student_2
        )
      end

      step 'Student 2 leaves a score review on question 1' \
           'of "activity 3" with comment "sr_s2_a3_c1"' do
        create_help_request(
          activity: activity_3,
          student: student_2,
          student_comment: 'sr_s2_a3_c1',
          type: 'review'
        )
      end
    end

    visit instructor_help_requests_path(program.id)

    purpose 'I see the current course settings' do
      expect(page).to have_text('Allowing score reviews.')
      expect(page).to have_text('Allowing help requests.')
    end

    purpose 'I can change the course settings' do
      expect(page).to have_text('Change these settings.')
    end

    purpose 'I see the number of requests per category' do
      expect(page).to have_selector('li#processed_help_request_header')
      expect_request_count(type: 'help', processed: true, number: '0')
      expect(page).to have_selector('li#unprocessed_help_request_header')
      expect_request_count(type: 'help', processed: false, number: '5')
      expect(page).to have_selector('li#processed_review_request_header')
      expect_request_count(type: 'review', processed: true, number: '0')
      expect(page).to have_selector('li#unprocessed_review_request_header')
      expect_request_count(type: 'review', processed: false, number: '5')
    end

    purpose 'Help requests' do
      purpose 'I see details of processed help requests' do
        visit_requests_page(processed: true, type: 'help')

        step 'I see "No requests."' do
          within(active_tab_header(processed: true, type: 'help')) do
            within('.instructor_task_activities') do
              within('.no_tasks') do
                expect(page).to have_selector('p', text: 'No requests.')
              end
            end
          end
        end
      end

      purpose 'I see details pending help requests' do
        visit_requests_page(processed: false, type: 'help')

        step 'I see requests organized by lesson / activity / student' do
          expect_lesson_name(lesson: 1, strand: 1)
          expect_activity_name(activity_1)
          expect_student_request(student: student_1, request: '2 requests')
          expect_student_request(student: student_2, request: '1 request')
          expect_activity_name(activity_2)
          expect_student_request(student: student_1, request: '1 request')
          expect_lesson_name(lesson: 2, strand: 1)
          expect_activity_name(activity_3)
          expect_student_request(student: student_2, request: '1 request')
        end
      end

      purpose 'I can answer help requests' do
        visit_requests_page(processed: false, type: 'help')

        step 'Click on the "student 1" link in the lesson' \
             'spanner "lesson 1 | strand 1", "activity 1"' do
          within(active_tab_header(processed: false, type: 'help')) do
            page.all(
              'a.student_name_link',
              text: "#{student_1.first_name} #{student_1.last_name}"
            ).first.click
          end
        end
        expect_activity_name(activity_1)
        step 'I see 2 help requests on the question 1' do
          expect_student_name(student_1)
          expect(page).to have_selector('.student_comment_date')
          expect(page).to have_text('hr_s1_a1_c1')
          expect_student_name(student_1)
          expect(page).to have_selector('.student_comment_date')
          expect(page).to have_text('hr_s1_a1_c2')
        end

        step 'I cannot respond with an empty comment' do
          enter_response('')
          click_respond_to_request_button
          expect(page).to have_text('You must enter a comment')
        end

        step 'I respond with a comment' do
          enter_response('comment for help request')
          click_respond_to_request_button
          expect(page).to have_selector('.help_request_message', text: 'Help request successfully responded!')
        end

        step 'I see my response' do
          expect_instructor_comment(
            name: "#{instructor.first_name} #{instructor.last_name}",
            comment: 'comment for help request'
          )
        end

        step 'I can change my comment' do
          click_edit_response_link
          all('instructor_comment').each { |field| expect(field).to eq('comment for help request') }
          enter_response('comment for help request fixed')
          click_respond_to_request_button
        end

        step 'I see my response' do
          expect_instructor_comment(
            name: "#{instructor.first_name} #{instructor.last_name}",
            comment: 'comment for help request fixed'
          )
        end

        step 'My comments are escaped' do
          click_edit_response_link
          enter_response(harmful_comment)
          click_respond_to_request_button

          step 'I see my harmful comment as text so it has been escaped' do
            page.html.should include('&lt;script type="text/javascript"&gt;window.close();&lt;/script&gt;blah')
          end
        end
        return_to_requests
        expect_active_tab(processed: false, type: 'help')
      end

      purpose '"Pending Help Requests" has been updated' do
        expect_request_count(type: 'help', processed: false, number: '4')

        step 'I see requests organized by lesson / activity / student' do
          expect_lesson_name(lesson: 1, strand: 1)
          expect_activity_name(activity_1)
          expect_student_request(student: student_1, request: '1 request')
          expect_student_request(student: student_2, request: '1 request')
          expect_activity_name(activity_2)
          expect_student_request(student: student_1, request: '1 request')
          expect_lesson_name(lesson: 2, strand: 1)
          expect_activity_name(activity_3)
          expect_student_request(student: student_2, request: '1 request')
        end
      end

      purpose '"Processed Help Requests" has been updated' do
        visit_requests_page(processed: true, type: 'help')

        expect_request_count(type: 'help', processed: true, number: '1')

        step 'I see requests organized by lesson / activity / student' do
          expect_lesson_name(lesson: 1, strand: 1)
          expect_activity_name(activity_1)
          expect_student_request(student: student_1, request: '1 request')
        end
      end

      purpose 'I can review my comment' do
        step 'Click on the "student 1" link in the lesson' \
             'spanner "lesson 1 | strand 1", "activity 1"' do
          within(active_tab_header(processed: true, type: 'help')) do
            page.all(
              'a.student_name_link',
              text: "#{student_1.first_name} #{student_1.last_name}"
            ).first.click
          end
        end
        expect_activity_name(activity_1)
        return_to_requests
      end
    end

    purpose 'Score reviews' do
      purpose 'I see details of processed score reviews' do
        visit_requests_page(processed: true, type: 'review')

        step 'I see "No requests."' do
          within(active_tab_header(processed: true, type: 'review')) do
            within('.instructor_task_activities') do
              within('.no_tasks') do
                expect(page).to have_selector('p', text: 'No requests.')
              end
            end
          end
        end

        purpose 'I see details pending score reviews' do
          visit_requests_page(processed: false, type: 'review')

          step 'I see requests organized by lesson / activity / student' do
            expect_lesson_name(lesson: 1, strand: 1)
            expect_activity_name(activity_1)
            expect_student_request(student: student_1, request: '2 requests')
            expect_student_request(student: student_2, request: '1 request')
            expect_activity_name(activity_2)
            expect_student_request(student: student_1, request: '1 request')
            expect_lesson_name(lesson: 2, strand: 1)
            expect_activity_name(activity_3)
            expect_student_request(student: student_2, request: '1 request')
          end
        end

        purpose 'I can answer score reviews' do
          visit_requests_page(processed: false, type: 'review')

          step 'Click on the "student 1" link in the lesson'\
               'spanner "lesson 1 | strand 1", "activity 1"' do
            within(active_tab_header(processed: false, type: 'review')) do
              page.all(
                'a.student_name_link',
                text: "#{student_1.first_name} #{student_1.last_name}"
              ).first.click
            end
          end
          expect_activity_name(activity_1)

          step 'I see 2 help requests on the question 1' do
            expect_student_name(student_1)
            expect(page).to have_selector('.student_comment_date')
            expect(page).to have_text('sr_s1_a1_c1')
            expect_student_name(student_1)
            expect(page).to have_selector('.student_comment_date')
            expect(page).to have_text('sr_s1_a1_c2')
          end

          step 'I cannot respond with an empty comment' do
            enter_response('', 2)
            click_respond_to_request_button(2)
            step 'I see the message "You must enter a comment"' do
              expect(page).to have_text('You must enter a comment')
            end
          end

          step 'I respond with a comment' do
            enter_response('comment for score review', 2)
            click_respond_to_request_button(2)
          end

          step 'I see my response' do
            expect_instructor_comment(
              name: "#{instructor.first_name} #{instructor.last_name}",
              comment: 'comment for score review'
            )
          end

          step 'I can change my comment' do
            click_edit_response_link(2)
            all('instructor_comment').each { |field| expect(field).to eq('comment for help request') }
            enter_response('comment for score review fixed', 2)
            click_respond_to_request_button(2)
          end

          step 'I see my response' do
            expect_instructor_comment(
              name: "#{instructor.first_name} #{instructor.last_name}",
              comment: 'comment for score review fixed'
            )
          end

          step 'My comments are escaped' do
            click_edit_response_link(2)
            enter_response(harmful_comment, 2)
            click_respond_to_request_button(2)
            step 'I see my harmful comment as text so it has been escaped' do
              page.html.should include('&lt;script type="text/javascript"&gt;window.close();&lt;/script&gt;blah')
            end
          end

          visit instructor_help_requests_path(program.id)
          visit_requests_page(processed: false, type: 'review')
        end

        purpose '"Pending Score Reviews" has been updated' do
          expect_request_count(type: 'review', processed: false, number: '4')

          step 'I see requests organized by lesson / activity / student' do
            expect_lesson_name(lesson: 1, strand: 1)
            expect_activity_name(activity_1)
            expect_student_request(student: student_1, request: '1 request')
            expect_student_request(student: student_2, request: '1 request')
            expect_activity_name(activity_2)
            expect_student_request(student: student_1, request: '1 request')
            expect_lesson_name(lesson: 2, strand: 1)
            expect_activity_name(activity_3)
            expect_student_request(student: student_2, request: '1 request')
          end
        end

        purpose '"Processed Score Reviews" has been updated' do
          visit_requests_page(processed: true, type: 'review')
          expect_request_count(type: 'review', processed: true, number: '1')

          step 'I see requests organized by lesson / activity / student' do
            expect_lesson_name(lesson: 1, strand: 1)
            expect_activity_name(activity_1)
            expect_student_request(student: student_1, request: '1 request')
          end
        end

        purpose 'I can review my comment' do
          step 'Click on the "student 1" link in the lesson' \
               'spanner "lesson 1 | strand 1", "activity 1"' do
            within(active_tab_header(processed: true, type: 'review')) do
              page.all(
                'a.student_name_link',
                text: "#{student_1.first_name} #{student_1.last_name}"
              ).first.click
            end
          end
          expect_activity_name(activity_1)
          visit instructor_help_requests_path(program.id)
        end
      end
    end
  end
end
