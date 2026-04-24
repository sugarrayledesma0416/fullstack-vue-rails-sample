feature 'Instructor Grading AI feature', chrome: true, js: true, new_gb_sync: true do
  include RspecJsCommonHelpers
  include RspecJsApiHelpers
  include RspecJsContentHelpers
  include GradebookEngineHelpers
  include GradebookEngineTest::PageObjects
  include CapybaraViewHelpers
  include ActivityTest::MockSubmissions

  let(:instructor) { create(:instructor, username: 'instructor') }
  let(:student) { create(:student) }
  let(:program) { create(:program_with_toc_entries) }
  let(:course) { create(:course, owner: instructor, program:) }
  let(:category) { create(:category, course:, penalty_percent: 0) }
  let(:section) { create(:section, course:, instructor:) }
  let(:activity) { create_open_ended_activity(program) }
  let(:concept) { activity.concept }
  let(:lesson) { activity.lesson }
  let(:strand) { activity.strand }
  let(:grading_set) { create(:grading_set, instructor:, activity:, program:, student_id_list: "#{student.id}")}
  let(:attempt_results) { blank_open_ended_results(activity) }
  let(:fake_submissions) { {} }
  let(:attempt) { create(:attempt_completed, activity:, section:, user: student) }
  let!(:identified_error_incorrectly_rating_category) do
    AI::SuggestionRatingCategory.create!(
      internal_use: false,
      label: 'Identified Error Incorrectly'
    )
  end
  let!(:other_rating_category) do
    AI::SuggestionRatingCategory.create!(internal_use: false, label: 'other')
  end
  let!(:ai_grading_suggestion_job) { create(:ai_grading_suggestion_job, attempt:, question_label: 'label', status: 'completed' ) }
  let!(:grading_suggestion_1) do
    create(
      :ai_grading_suggestion,
      activity:,
      attempt:,
      error_explanation: 'The verb must match with "this". It must be singular.',
      incorrect_text: 'This are',
      program:,
      question_label: 'question_01',
      ai_grading_suggestion_job_id: ai_grading_suggestion_job.id
    )
  end

  let!(:grading_suggestion_2) do
    create(
      :ai_grading_suggestion,
      activity:,
      attempt:,
      error_explanation: 'You misspelled the word "student".',
      incorrect_text: 'studnt',
      program:,
      question_label: 'question_01',
      ai_grading_suggestion_job_id: ai_grading_suggestion_job.id
    )
  end

  let!(:grading_suggestion_3) do
    create(
      :ai_grading_suggestion,
      activity:,
      attempt:,
      error_explanation: 'It should be "contains".',
      incorrect_text: 'contain',
      incorrect_text_begin_offset: 11,
      program:,
      question_label: 'question_01',
      ai_grading_suggestion_job_id: ai_grading_suggestion_job.id
    )
  end
  let!(:overall_comment) do
    create(
      :ai_overall_comment,
      activity:,
      attempt:,
      program:,
      question_label: 'question_01'
    )
  end
  let(:student_1_activity_1_question_1_response) do
    'This are the studnt response for question 1. It contain some errors.'
  end
  let(:student_1_activity_1_question_2_response) do
    'student 1, activity 1, response for question 2'
  end
  let(:results) do
    MaestroActivityEngine::ActivityContent::Results.new(
      activity.content_object
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
  let(:my_edited_comment_suffix) { ' (my edited comment)' }

  before do
    create(:enrollment, user: student, section: section)
    create(
      :assignment,
      assignable: activity,
      category: category,
      due_date: Date.yesterday,
      section: section
    )
    initialize_fake_submissions_client
    attempt.write_results(
      results,
      true,
      'submitted',
      5.minutes.ago.to_i,
      Time.now.to_i
    )

    stub_request(:post, %r{/instructor/grading_tasks/start_ai_feedback})
    .to_return(status: 200, body: { grading_set_id: grading_set.id, status: "ready" }.to_json)

    stub_request(:get, %r{/instructor/grading_tasks/grading_status})
      .to_return(status: 200, body: { status: "ready" }.to_json)

    initialize_program_access_client_calls_for_instructor(instructor, program)
    log_in_as(instructor)
  end

  xscenario 'As an instructor, I can access student-by-student grading for any instructor-graded activity' do
    create(:program_config, program:, ai_settings: { grading_suggestions: true })
    # Declare outside the following scope in order to access it later
    rating_details = nil

    # The student has submitted the activity
    create_gradebook_engine_submission(submitted_at: Time.now.utc)

    # Go to the gradebook page showing activity-level scores.
    visit activities_for_lesson_url
    column_header(activity).click
    click_link('Grade Activity')

    for_grading_style_page_object do |pobject|
      pobject.grading_style = :student_by_student
      pobject.ai_assisted_grading = true
      pobject.start_grading
    end

    expect(page).to have_current_path(edit_instructor_grading_set_path(program.id, grading_set.id, task_type: 'needs_grading_section'))

    for_grading_student_by_student do |pobject|
      purpose 'The AI suggestions are automatically applied' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I see the grading suggestions in the Froala editor' do
            student_answer.for_text_response do |response|
              expect(response.grading_suggestion_comments).to contain_exactly(
                an_object_having_attributes(
                  id: grading_suggestion_1.id,
                  comment: grading_suggestion_1.error_explanation
                ),
                an_object_having_attributes(
                  id: grading_suggestion_2.id,
                  comment: grading_suggestion_2.error_explanation
                ),
                an_object_having_attributes(
                  id: grading_suggestion_3.id,
                  comment: grading_suggestion_3.error_explanation
                )
              )
            end
          end

          step 'I see the grading suggestions marked as accepted in the AI panel' do
            student_answer.for_ai_panel do |panel|
              expect(panel.suggestions).to contain_exactly(
                an_object_having_attributes(
                  accepted?: true,
                  edited?: false,
                  id: grading_suggestion_1.id,
                  label: grading_suggestion_1.error_explanation
                ),
                an_object_having_attributes(
                  accepted?: true,
                  edited?: false,
                  id: grading_suggestion_2.id,
                  label: grading_suggestion_2.error_explanation
                ),
                an_object_having_attributes(
                  accepted?: true,
                  edited?: false,
                  id: grading_suggestion_3.id,
                  label: grading_suggestion_3.error_explanation
                )
              )
            end
          end
        end
      end

      purpose 'I can reject AI grading suggestions' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I reject AI grading suggestions from the AI panel' do
            student_answer.for_ai_panel do |panel|
              panel.suggestion(id: grading_suggestion_2.id).reject
              panel.suggestion(id: grading_suggestion_3.id).reject
            end
          end

          step 'I see the accepted grading suggestions in the Froala editor' do
            student_answer.for_text_response do |response|
              expect(response.grading_suggestion_comments).to contain_exactly(
                an_object_having_attributes(
                  id: grading_suggestion_1.id,
                  comment: grading_suggestion_1.error_explanation
                )
              )
            end
          end
        end
      end

      purpose 'I can accept AI grading suggestions' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I accept AI grading suggestions from the AI panel' do
            student_answer.for_ai_panel do |panel|
              panel.suggestion(id: grading_suggestion_2.id).accept
            end
          end

          step 'I see the accepted grading suggestions in the Froala editor' do
            student_answer.for_text_response do |response|
              expect(response.grading_suggestion_comments).to contain_exactly(
                an_object_having_attributes(
                  id: grading_suggestion_1.id,
                  comment: grading_suggestion_1.error_explanation
                ),
                an_object_having_attributes(
                  id: grading_suggestion_2.id,
                  comment: grading_suggestion_2.error_explanation
                )
              )
            end
          end
        end
      end

      purpose 'I can edit an AI suggestion' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I edit the AI grading suggestion in the Froala editor' do
            student_answer.for_text_response do |response|
              response.grading_suggestion_comment(grading_suggestion_1.id).click

              response.for_edit_comment_popup do |popup|
                expect(popup.comment).to eq(grading_suggestion_1.error_explanation)

                popup.comment = popup.comment + ' edited'
                popup.save
              end
            end
          end

          step 'I see the grading suggestions in the Froala editor' do
            student_answer.for_text_response do |response|
              expect(response.grading_suggestion_comments).to contain_exactly(
                an_object_having_attributes(
                  id: grading_suggestion_1.id,
                  comment: grading_suggestion_1.error_explanation + ' edited'
                ),
                an_object_having_attributes(
                  id: grading_suggestion_2.id,
                  comment: grading_suggestion_2.error_explanation
                )
              )
            end
          end

          step 'I see in the AI panel when a grading suggestion has been edited' do
            student_answer.for_ai_panel do |panel|
              expect(panel.suggestion(id: grading_suggestion_1.id)).to have_attributes(
                edited?: true,
                label: grading_suggestion_1.error_explanation + my_edited_comment_suffix
              )
            end
          end
        end
      end

      purpose 'The AI overall comment is automatically applied' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I see the overall comment in the instructor comment' do
            expect(student_answer.instructor_comment).to eq(
              "#{overall_comment.overall_comment}. #{overall_comment.explanation}"
            )
          end

          step 'I see the overall comment marked as accepted in the AI panel' do
            student_answer.for_ai_panel do |panel|
              expect(panel.overall_comments).to contain_exactly(
                an_object_having_attributes(
                  accepted?: true,
                  edited?: false,
                  id: overall_comment.id,
                  label: "#{overall_comment.overall_comment}. #{overall_comment.explanation}"
                )
              )
            end
          end
        end
      end

      purpose 'I can reject the AI overall comment' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I reject AI overall comment from the AI panel' do
            student_answer.for_ai_panel do |panel|
              panel.overall_comment(id: overall_comment.id).reject
            end
          end

          step 'I see the AI overall comment as rejected in the AI panel' do
            student_answer.for_ai_panel do |panel|
              expect(panel.overall_comment(id: overall_comment.id)).to be_rejected
            end
          end

          step 'I do not see the overall comment in the instructor comment' do
            expect(student_answer.instructor_comment).to be_blank
          end
        end
      end

      purpose 'I can accept the AI overall comment' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I accept AI overall comment from the AI panel' do
            student_answer.for_ai_panel do |panel|
              panel.overall_comment(id: overall_comment.id).accept
            end
          end

          step 'I see the overall comment in the instructor comment' do
            expect(student_answer.instructor_comment).to eq(
              "#{overall_comment.overall_comment}. #{overall_comment.explanation}"
            )
          end
        end
      end

      purpose 'I can edit the AI overall comment' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'I edit the instructor feedback' do
            student_answer.instructor_comment = student_answer.instructor_comment + ' blah.'
          end

          step 'I see in the AI panel that the overall comment has been edited' do
            student_answer.for_ai_panel do |panel|
              expect(panel.overall_comment(id: overall_comment.id)).to have_attributes(
                edited?: true,
                label: "#{overall_comment.overall_comment}. #{overall_comment.explanation}#{my_edited_comment_suffix}"
              )
            end
          end
        end
      end

      purpose 'I can add inline comments' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          purpose 'I can cancel the comment creation' do
            student_answer.for_text_response do |response|
              response.new_inline_comment

              response.for_edit_comment_popup do |popup|
                expect(popup.comment).to be_blank

                popup.comment = 'This is a new comment'
                popup.delete
              end

              step 'The comment is not added in the Froala editor' do
                expect(response.inline_comments).to be_empty
              end
            end
          end

          student_answer.for_text_response do |response|
            response.new_inline_comment

            response.for_edit_comment_popup do |popup|
              expect(popup.comment).to be_blank

              popup.comment = 'This is a new comment'
              popup.save

              step 'The comment is added in the Froala editor' do
                expect(response.inline_comments).to contain_exactly(
                  an_object_having_attributes(
                    comment: 'This is a new comment'
                  )
                )
              end
            end
          end
        end
      end

      purpose 'I can flag an AI suggestion' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          student_answer.for_ai_panel do |panel|
            panel.open_flag_modal

            panel.for_flag_modal do |modal|
              step 'By default, no grading suggestions is flagged' do
                expect(modal.grading_suggestions).to contain_exactly(
                  an_object_having_attributes(
                    id: grading_suggestion_1.id,
                    label: grading_suggestion_1.error_explanation,
                    selected?: false
                  ),
                  an_object_having_attributes(
                    id: grading_suggestion_2.id,
                    label: grading_suggestion_2.error_explanation,
                    selected?: false
                  ),
                  an_object_having_attributes(
                    id: grading_suggestion_3.id,
                    label: grading_suggestion_3.error_explanation,
                    selected?: false
                  )
                )
              end

              step 'By default, the overall comments are not flagged' do
                expect(modal.overall_comments).to contain_exactly(
                  an_object_having_attributes(
                    id: overall_comment.id,
                    label: "#{overall_comment.overall_comment}. #{overall_comment.explanation}",
                    selected?: false
                  )
                )
              end

              step 'When I select a grading suggestion, I have to select a rating category' do
                modal.for_grading_suggestion(id: grading_suggestion_1.id) do |suggestion|
                  suggestion.select
                  expect(modal.submit_button).to be_disabled
                  suggestion.rating_category = identified_error_incorrectly_rating_category.label
                  expect(modal.submit_button).not_to be_disabled
                end
              end

              step 'I can flag a grading suggestion with the "other" rating category ' \
                   'and not add any comment' do
                modal.for_grading_suggestion(id: grading_suggestion_1.id) do |suggestion|
                  suggestion.select
                  suggestion.rating_category = other_rating_category.label
                end
              end

              step 'I can flag a grading suggestion with the "other" rating category ' \
                   'and add an optional comment' do
                modal.for_grading_suggestion(id: grading_suggestion_3.id) do |suggestion|
                  suggestion.select
                  suggestion.rating_category = other_rating_category.label
                  suggestion.comment = 'This is not accurate'
                end
              end

              step 'I can flag an overall comment with the "oether" rating category ' \
                   'and add an optional comment' do
                modal.for_overall_comment(id: overall_comment.id) do |overall_comment|
                  overall_comment.select
                  overall_comment.rating_category = other_rating_category.label
                  overall_comment.comment = 'Flag comment for overall comment'
                end
              end

              step 'I can add an additional feedback' do
                modal.additional_feedback = 'this is an additional feedback about AI suggestions'
              end

              modal.submit
            end
          end
        end
      end

      purpose 'I can give a score' do
        pobject.student_answer('question_01', student).score = 10.0
      end

      purpose 'I can save my changes' do
        accept_alert('You did not enter a grade for 3 questions. OK to proceed?') do
          pobject.button(:done).click
        end

        Capybara.using_wait_time(5) do
          expect_flash_message(:notice, "#{activity.title} has been successfully graded.")
        end
      end
    end

    purpose 'I returned to the same gradebook view that I started from' do
      expect_url(activities_for_lesson_url)
    end

    purpose 'The changes are saved in the database' do
      expect(grading_suggestion_1.reload).to have_attributes(
        accepted?: true,
        edited?: true,
        rating_category: other_rating_category,
        rating_comment: nil,
        rated_by: instructor
      )
      expect(grading_suggestion_2.reload).to have_attributes(
        accepted?: true,
        edited?: false,
        rating_category: nil,
        rating_comment: nil
      )
      expect(grading_suggestion_3.reload).to have_attributes(
        rejected?: true,
        edited?: false,
        rating_category: other_rating_category,
        rated_by: instructor,
        rating_comment: 'This is not accurate'
      )
      expect(overall_comment.reload).to have_attributes(
        accepted?: true,
        edited?: true,
        rating_category: other_rating_category,
        rated_by: instructor,
        rating_comment: 'Flag comment for overall comment'
      )
      rating_details = AI::SuggestionRatingDetail.find_by!(
        program:,
        activity:,
        attempt:,
        question_label: 'question_01'
      )
      expect(rating_details).to have_attributes(
        comment: 'this is an additional feedback about AI suggestions',
        updated_by: instructor
      )
    end

    column_header(activity).click
    click_link('Grade Activity')

    for_grading_style_page_object do |pobject|
      pobject.grading_style = :student_by_student
      pobject.start_grading
    end

    for_grading_student_by_student do |pobject|
      step 'The accepted AI suggestions are applied' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'Applied grading suggestions are visible in the Froala editor' do
            student_answer.for_text_response do |response|
              expect(response.grading_suggestion_comments).to contain_exactly(
                an_object_having_attributes(
                  id: grading_suggestion_1.id,
                  comment: grading_suggestion_1.error_explanation + ' edited'
                ),
                an_object_having_attributes(
                  id: grading_suggestion_2.id,
                  comment: grading_suggestion_2.error_explanation
                )
              )
            end
          end

          step 'Grading suggestions state are visible in the AI Panel' do
            student_answer.for_ai_panel do |panel|
              expect(panel.suggestions).to contain_exactly(
                an_object_having_attributes(
                  accepted?: true,
                  edited?: true,
                  id: grading_suggestion_1.id,
                  label: "#{grading_suggestion_1.error_explanation}#{my_edited_comment_suffix}"
                ),
                an_object_having_attributes(
                  accepted?: true,
                  edited?: false,
                  id: grading_suggestion_2.id,
                  label: grading_suggestion_2.error_explanation
                ),
                an_object_having_attributes(
                  edited?: false,
                  id: grading_suggestion_3.id,
                  label: grading_suggestion_3.error_explanation,
                  rejected?: true
                )
              )
            end
          end
        end
      end

      step 'I see the suggestions that have been flagged' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          student_answer.for_ai_panel do |panel|
            panel.open_flag_modal

            panel.for_flag_modal do |modal|
              expect(modal.grading_suggestions).to contain_exactly(
                an_object_having_attributes(
                  id: grading_suggestion_1.id,
                  label: grading_suggestion_1.error_explanation,
                  selected?: true,
                  comment: ''
                ),
                an_object_having_attributes(
                  id: grading_suggestion_2.id,
                  label: grading_suggestion_2.error_explanation,
                  selected?: false
                ),
                an_object_having_attributes(
                  id: grading_suggestion_3.id,
                  label: grading_suggestion_3.error_explanation,
                  selected?: true,
                  comment: grading_suggestion_3.rating_comment
                )
              )

              expect(modal.overall_comments).to contain_exactly(
                an_object_having_attributes(
                  id: overall_comment.id,
                  label: "#{overall_comment.overall_comment}. #{overall_comment.explanation}",
                  selected?: true,
                  comment: overall_comment.rating_comment
                )
              )

              expect(modal.additional_feedback).to eq(
                rating_details.comment
              )
            end
          end
        end
      end

      step 'I can unflag an AI suggestion' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          student_answer.for_ai_panel do |panel|
            panel.for_flag_modal do |modal|
              step 'I can unflag a suggestion' do
                modal.grading_suggestion(id: grading_suggestion_1.id).unselect
              end

              step 'I can flag a suggestion' do
                modal.for_grading_suggestion(id: grading_suggestion_2.id) do |suggestion|
                  suggestion.select
                  suggestion.rating_category = identified_error_incorrectly_rating_category.label
                end
              end

              step 'I can update the comment of a flagged suggestion' do
                modal.for_grading_suggestion(id: grading_suggestion_3.id) do |suggestion|
                  suggestion.comment = 'This is a new comment'
                end
              end

              step 'I can remove the additional feedback' do
                modal.additional_feedback = 'These suggestions are not great.'
              end

              modal.submit
            end
          end
        end
      end

      step 'I can accept and reject grading suggestions' do
        pobject.for_student_answer('question_01', student) do |student_answer|
          student_answer.for_ai_panel do |panel|
            panel.suggestion(id: grading_suggestion_2.id).reject
            panel.suggestion(id: grading_suggestion_3.id).accept
          end
        end
      end

      step 'I can save my changes' do
        accept_alert('You did not enter a grade for 3 questions. OK to proceed?') do
          pobject.button(:done).click
        end
      end
    end

    Capybara.using_wait_time(5) do
      expect_flash_message(:notice, "#{activity.title} has been successfully graded.")
    end

    purpose 'The changes are saved in the database' do
      expect(grading_suggestion_1.reload).to have_attributes(
        accepted?: true,
        edited?: true,
        rating_category: nil,
        rating_comment: nil,
        rated_by: nil
      )
      expect(grading_suggestion_2.reload).to have_attributes(
        edited?: false,
        rejected?: true,
        rating_category: identified_error_incorrectly_rating_category,
        rating_comment: nil,
        rated_by: instructor
      )
      expect(grading_suggestion_3.reload).to have_attributes(
        accepted?: true,
        edited?: false,
        rating_category: other_rating_category,
        rated_by: instructor,
        rating_comment: 'This is a new comment'
      )
      expect(overall_comment.reload).to have_attributes(
        accepted?: true,
        edited?: false,
        rating_category: other_rating_category,
        rated_by: instructor,
        rating_comment: 'Flag comment for overall comment'
      )
      rating_details = AI::SuggestionRatingDetail.find_by!(
        program:,
        activity:,
        attempt:,
        question_label: 'question_01'
      )
      expect(rating_details).to have_attributes(
        comment: 'These suggestions are not great.',
        updated_by: instructor
      )
    end

    column_header(activity).click
    click_link('Grade Activity')

    purpose 'I can grade with the AI assisted grading disabled' do
      for_grading_style_page_object do |pobject|
        pobject.grading_style = :student_by_student
        pobject.ai_assisted_grading = false
        pobject.start_grading
      end

      expect(page).to have_current_path(edit_instructor_grading_set_path(program.id, grading_set.id, task_type: 'needs_grading_section'))

      for_grading_student_by_student do |pobject|
        pobject.for_student_answer('question_01', student) do |student_answer|
          step 'The AI Panel is not visible' do
            expect(student_answer.ai_panel).not_to be_visible
          end

          step 'All grading suggestions have been removed from the Froala editor' do
            student_answer.for_text_response do |response|
              expect(response.grading_suggestion_comments).to be_empty
            end
          end
        end

        step 'I can save my changes' do
          accept_alert('You did not enter a grade for 3 questions. OK to proceed?') do
            pobject.button(:done).click
          end
        end
      end
    end

    Capybara.using_wait_time(5) do
      expect_flash_message(:notice, "#{activity.title} has been successfully graded.")
    end

    purpose 'The changes are saved in the database' do
      step 'The grading suggestions status is reset and the flagging is not updated' do
        expect(grading_suggestion_1.reload).to have_attributes(
          accepted?: false,
          edited?: false,
          rated_by: nil,
          rating_category: nil,
          rating_comment: nil,
          rejected?: false
        )
        expect(grading_suggestion_2.reload).to have_attributes(
          accepted?: false,
          edited?: false,
          rated_by: instructor,
          rating_category: identified_error_incorrectly_rating_category,
          rating_comment: nil,
          rejected?: false
        )
        expect(grading_suggestion_3.reload).to have_attributes(
          accepted?: false,
          edited?: false,
          rated_by: instructor,
          rating_category: other_rating_category,
          rating_comment: 'This is a new comment',
          rejected?: false
        )
        expect(overall_comment.reload).to have_attributes(
          accepted?: false,
          edited?: false,
          rated_by: instructor,
          rating_category: other_rating_category,
          rating_comment: 'Flag comment for overall comment',
          rejected?: false
        )
        rating_details = AI::SuggestionRatingDetail.find_by!(
          activity:,
          attempt:,
          program:,
          question_label: 'question_01'
        )
        expect(rating_details).to have_attributes(
          comment: 'These suggestions are not great.',
          updated_by: instructor
        )
      end
    end
  end
end
