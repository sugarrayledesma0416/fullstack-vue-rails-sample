describe StudentGradingSubmission do
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }
  let(:section) { create(:section, program:) }
  let(:activity) { create(:activity) }
  let(:student) { create(:student) }
  let(:points_possible) { 10 }
  let(:question_klass) do
    MaestroActivityEngine::ActivityContent::OpenEnded::Item
  end
  let(:question) do
    instance_double(
      question_klass,
      label: 'question_1',
      points_possible:
    )
  end
  let(:response_id) { "#{question.label}_student_#{student.id}" }
  let(:score_key) { "score_for_#{response_id}" }
  let(:comment_key) { "comment_for_#{response_id}" }
  let(:ai_overall_comment_key) { "ai_overall_feedback_for_#{response_id}" }
  let(:ai_grading_suggestions_key) { "ai_grading_suggestions_for_#{response_id}" }
  let(:ai_suggestion_rating_details_key) { "ai_suggestion_rating_details_for_#{response_id}" }
  let(:inline_corrections_key) { "inline_corrections_for_#{response_id}" }
  let(:params) do
    {
      score_key => points_possible,
      rubric_graded: false
    }
  end
  let(:attempt) { create(:attempt, activity:, section:, user: student) }
  let(:grading_feedback) do
    GradingFeedback.new(
      activity:,
      questions: [question],
      students: [student],
      sections: [section]
    )
  end
  let(:grading_submission) do
    described_class.new(
      activity:,
      attempt:,
      grading_feedback:,
      instructor:,
      params: ActionController::Parameters.new(params),
      question:,
      student:
    )
  end

  def enable_ai_grading_feature_for_program(program:)
    create(
      :program_config,
      program:,
      ai_settings: { grading_suggestions: true }
    )
  end

  describe '#valid?' do
    it 'returns true if there is no score' do
      params[score_key] = ''

      expect(grading_submission).to be_valid
    end

    it 'returns false if points earned is not a number' do
      params[score_key] = 'threeve'

      expect(grading_submission).not_to be_valid
    end

    it 'returns false if points earned is < 0' do
      params[score_key] = -1

      expect(grading_submission).not_to be_valid
    end

    it 'returns true if the score is zero' do
      params[score_key] = 0

      expect(grading_submission).to be_valid
    end

    it 'returns true if the score equals the points possible' do
      params[score_key] = points_possible

      expect(grading_submission).to be_valid
    end

    it 'returns false if points earned is > points possible for the question' do
      params[score_key] = points_possible + 1

      expect(grading_submission).not_to be_valid
    end

    it 'returns true if the value submitted is of the format .8' do
      params[score_key] = '.8'

      expect(grading_submission).to be_valid
    end
  end

  describe '#submit' do
    let(:feedback_params) do
      {
        activity:,
        attempt:,
        current_user: instructor,
        question_label: question.label,
        section: attempt.section,
        student:,
        cartridge_params: nil,
        points_earned: 10,
        rubric_graded: false,
        feedback_item_ai_comments: {}
      }
    end

    before do
      allow(FeedbackItem).to receive(:submit)
      allow(RubricCriteriaScore).to receive(:submit)
    end

    context 'when there is no existing feedback item,' do
      context 'when no comment is submitted,' do
        it 'submits a feedback item' do
          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params
          )
        end
      end

      context 'when a comment is submitted,' do
        it 'submits a feedback item' do
          params[comment_key] = 'my new comment'

          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params.merge(
              comment: 'my new comment',
              feedback_notification: true
            )
          )
        end
      end

      context 'when no correction is submitted,' do
        it 'submits a feedback item' do
          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params
          )
        end
      end

      context 'when a correction is submitted and does not include an instructor tag' do
        it 'submits a feedback item with no inline correction' do
          params[inline_corrections_key] = 'some correction'

          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params
          )
        end
      end

      context 'when a correction is submitted and includes an instructor tag' do
        let(:corrections) do
          <<~CORRECTION
            <span
              data-comment-inline="This is incorrect"
              data-comment-number="1">
            </span>
          CORRECTION
        end

        it 'submits a feedback item with the inline correction' do
          params[inline_corrections_key] = corrections

          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params.merge(
              feedback_notification: true,
              inline_corrections: corrections
            )
          )
        end
      end
    end

    context 'when there is an existing feedback item,' do
      let!(:feedback_item) do
        create(
          :feedback_item,
          attempt:,
          section:,
          user: student,
          question_label: question.label
        )
      end

      context 'when the existing feedback item contains a comment,' do
        before do
          feedback_item.update!(
            comment: 'foo'
          )
        end

        context 'when no comment is submitted,' do
          context 'when the activity is a group chat activity,' do
            let(:activity) { create(:activity, activity_type: 'group_chat') }

            it 'submits a feedback item without including the empty comment' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  feedback_notification: true
                )
              )
            end
          end

          context 'when the activity is not a group chat activity,' do
            it 'submits a feedback item including an empty comment' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  comment: '',
                  feedback_notification: true
                )
              )
            end
          end
        end

        context 'when new comment is different from the old comment,' do
          context 'when the activity is a group chat activity,' do
            let(:activity) { create(:activity, activity_type: 'group_chat') }

            it 'submits a feedback item including the comment' do
              params[comment_key] = 'my new comment'

              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  comment: 'my new comment',
                  feedback_notification: true
                )
              )
            end
          end

          context 'when the activity is not a group chat activity,' do
            it 'submits a feedback item including the comment' do
              params[comment_key] = 'my new comment'

              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  comment: 'my new comment',
                  feedback_notification: true
                )
              )
            end
          end
        end

        context 'when new comment is equal to the old comment,' do
          it 'submits a feedback item without including the comment' do
            params[comment_key] = feedback_item.comment

            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params
            )
          end
        end
      end

      context 'when the existing feedback item does not contain comment,' do
        context 'when no comment is submitted,' do
          context 'when the activity is a group chat activity,' do
            let(:activity) { create(:activity, activity_type: 'group_chat') }

            it 'submits a feedback item without including the empty comment' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params
              )
            end
          end

          context 'when the activity is not a group chat activity,' do
            it 'submits a feedback item without including the empty comment' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params
              )
            end
          end
        end

        context 'when a comment is submitted,' do
          context 'when the activity is a group chat activity,' do
            let(:activity) { create(:activity, activity_type: 'group_chat') }

            it 'submits a feedback item including the comment' do
              params[comment_key] = 'my new comment'

              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  comment: 'my new comment',
                  feedback_notification: true
                )
              )
            end
          end

          context 'when the activity is not a group chat activity,' do
            it 'submits a feedback item including the comment' do
              params[comment_key] = 'my new comment'

              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  comment: 'my new comment',
                  feedback_notification: true
                )
              )
            end
          end
        end
      end

      context 'when the existing feedback item contains an inline corrections,' do
        before do
          feedback_item.update!(
            inline_corrections: 'some inline corrections <instructor_comment>'
          )
        end

        context 'when no correction is submitted,' do
          it 'submits a feedback item with the inline correction' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                inline_corrections: nil,
                feedback_notification: true
              )
            )
          end
        end

        context 'when the same correction is submitted,' do
          it 'submits a feedback item with no inline correction' do
            params[inline_corrections_key] = feedback_item.inline_corrections

            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params
            )
          end
        end

        context 'when a different correction is submitted and does not include an instructor tag' do
          it 'submits a feedback item with the inline correction' do
            params[inline_corrections_key] = 'different correction'

            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_notification: true,
                inline_corrections: 'different correction'
              )
            )
          end
        end

        context 'when a different correction is submitted and includes an instructor tag' do
          it 'submits a feedback item with the inline correction' do
            params[inline_corrections_key] = 'different correction <instructor_comment>'

            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_notification: true,
                inline_corrections: 'different correction <instructor_comment>'
              )
            )
          end
        end
      end

      context 'when the existing feedback item does not contain inline corrections,' do
        context 'when no inline correction is submitted' do
          it 'submits a feedback item with no inline corrections' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params
            )
          end
        end

        context 'when an inline correction is submitted and does not include an instructor tag,' do
          it 'submits a feedback item with no inline corrections' do
            params["inline_corrections_for_#{response_id}"] = 'new correction'

            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params
            )
          end
        end

        context 'when an inline correction is submitted and includes an instructor tag,' do
          it 'submits a feedback item with the inline corrections' do
            params["inline_corrections_for_#{response_id}"] = 'new correction <instructor_comment>'

            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_notification: true,
                inline_corrections: 'new correction <instructor_comment>'
              )
            )
          end
        end
      end
    end

    describe 'when the student is also an instructor,' do
      let(:student) { create(:instructor) }

      it 'does not submit feedback item' do
        grading_submission.submit

        expect(FeedbackItem).not_to have_received(:submit)
      end
    end

    describe 'when the grading feedback has no attempt for the student' do
      # This happens when the teammate of a partner chat activity has been transfered
      it 'does not submit feedback item' do
        attempt.destroy

        grading_submission.submit

        expect(FeedbackItem).not_to have_received(:submit)
      end
    end

    context 'when activity was not graded using a rubric,' do
      it 'does not submit rubric criteria scores' do
        grading_submission.submit

        expect(RubricCriteriaScore).not_to have_received(:submit)
      end
    end

    context 'when activity was graded using a rubric,' do
      let(:criteria_complete) do
        {
          attempt.id.to_s => {
            'Content' => '4',
            'Organization' => '2',
            'Accuracy' => '5'
          }
        }
      end
      let(:criteria_empty) do
        {
          attempt.id => {
            'Content' => '',
            'Organization' => '',
            'Accuracy' => ''
          }
        }
      end
      let(:criteria_incomplete) do
        {
          attempt.id => {
            'Content' => '',
            'Organization' => '3',
            'Accuracy' => ''
          }
        }
      end

      before do
        params[:rubric_graded] = 'true'
      end

      describe 'when criteria is complete' do
        before do
          params[:criteria] = criteria_complete
        end

        it 'submits feedback item' do
          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params.merge(
              rubric_graded: true
            )
          )
        end

        it 'submits rubric criteria scores' do
          grading_submission.submit

          expect(RubricCriteriaScore).to have_received(:submit).with(
            activity:,
            criteria: criteria_complete,
            section: attempt.section,
            student:
          )
        end
      end

      describe 'when criteria is not complete' do
        before do
          params[:criteria] = criteria_empty
        end

        it 'submits feedback item' do
          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params.merge(
              rubric_graded: true
            )
          )
        end

        it 'does not submit rubric criteria scores' do
          grading_submission.submit

          expect(RubricCriteriaScore).not_to have_received(:submit)
        end
      end

      describe 'when criteria is partially complete' do
        before do
          params[:criteria] = criteria_incomplete
        end

        it 'submits feedback item' do
          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params.merge(
              rubric_graded: true
            )
          )
        end

        it 'does not submit rubric criteria scores' do
          grading_submission.submit

          expect(RubricCriteriaScore).not_to have_received(:submit)
        end
      end

      context 'when there is an error submitting the criteria score' do
        before do
          params[:criteria] = criteria_complete

          allow(RubricCriteriaScore).to receive(:submit).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'does not submit a feedback item' do
          suppress(ActiveRecord::RecordInvalid) do
            grading_submission.submit

            expect(FeedbackItem).not_to have_received(:submit)
          end
        end

        it 'raises an error' do
          expect do
            grading_submission.submit
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end

      context 'when there is an error submitting the feedback item,' do
        before do
          params[:criteria] = criteria_complete

          allow(FeedbackItem).to receive(:submit).and_raise(ActiveRecord::RecordInvalid)
        end

        it 'raises an error' do
          expect do
            grading_submission.submit
          end.to raise_error(ActiveRecord::RecordInvalid)
        end
      end
    end

    context 'when activity is composition,' do
      let(:question) do
        MaestroActivityEngine::ActivityContent::Composition::Item.new(
          rank: 1,
          points_possible:
        )
      end

      context 'when no attachment is submitted,' do
        it 'submits a feedback item' do
          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params
          )
        end
      end

      context 'when an attachment is submitted,' do
        it 'submits a feedback item' do
          attachment_id = 321
          params["#{response_id}_attachment_id"] = attachment_id

          grading_submission.submit

          expect(FeedbackItem).to have_received(:submit).with(
            feedback_params.merge(
              attachment_id:
            )
          )
        end
      end
    end

    describe 'AI feature' do
      let(:activity) { create(:activity, activity_type: 'composition') }
      let!(:ai_overall_comment) do
        create(
          :ai_overall_comment,
          activity:,
          attempt:,
          question_label: question.label
        )
      end
      let(:rating_comment) { 'some comment' }
      let(:rating_category) { create(:ai_suggestion_rating_category) }

      shared_examples 'it raises a record not found error and does not submit a feedback item' do
        it 'raises an error' do
          expect do
            grading_submission.submit
          end.to raise_error(ActiveRecord::RecordNotFound)
        end

        it 'does not submit a feedback item' do
          expect do
            grading_submission.submit
          end.to raise_error(ActiveRecord::RecordNotFound)

          expect(FeedbackItem).not_to have_received(:submit)
        end
      end

      shared_examples 'it raises an argument error and does not submit a feedback item' do
        it 'raises an error' do
          expect do
            grading_submission.submit
          end.to raise_error(ArgumentError, /invalid value for Integer/)
        end

        it 'does not submit a feedback item' do
          expect do
            grading_submission.submit
          end.to raise_error(ArgumentError)

          expect(FeedbackItem).not_to have_received(:submit)
        end
      end

      shared_examples 'it does not log an AI grading suggestion inconsistency' do
        it 'does not log an AI grading suggestion inconsistency' do
          allow(STATS_PROXY).to receive(:warn)

          grading_submission.submit

          expect(STATS_PROXY).not_to have_received(:warn)
        end
      end

      context 'when an AI comment is marked as accepted and not edited,' do
        shared_examples 'it submits a feedback item and marks the AI comment as accepted and not edited' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                comment: ai_overall_comment.overall_comment,
                feedback_notification: true,
                feedback_item_ai_comments: {
                  ai_generated_comment: true
                }
              )
            )
          end

          it 'marks the AI comment as accepted and not edited' do
            expect do
              grading_submission.submit
            end.to(change { ai_overall_comment.reload.attributes })

            expect(ai_overall_comment.reload).to have_attributes(
              edited: false,
              reviewed_status: AI::OverallComment::ACCEPTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id.to_s => {
              accepted: 'true'
            }
          }
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the AI comment as accepted and not edited'
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as accepted and not edited'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as accepted and not edited'
        end
      end

      shared_examples 'it handles additional rating details' do
        context 'when additional rating details are provided,' do
          before do
            params[ai_suggestion_rating_details_key] = {
              'comment' => additional_rating_comment
            }
          end

          context 'when the rating comment is not blank' do
            let(:additional_rating_comment) { 'The suggestions are not precise.' }

            context 'when a suggestion rating details record already exists,' do
              let!(:rating_detail) do
                create(
                  :ai_suggestion_rating_detail,
                  attempt:,
                  question_label: question.label
                )
              end

              it 'updates the existing record' do
                expect do
                  grading_submission.submit
                end.to(change { rating_detail.reload.attributes })

                expect(rating_detail.reload).to have_attributes(
                  updated_by: instructor,
                  comment: additional_rating_comment
                )
              end
            end

            context 'when no suggestion rating details record exists,' do
              it 'creates a suggestion rating details record' do
                expect do
                  grading_submission.submit
                end.to change(AI::SuggestionRatingDetail, :count).by(1)

                expect(AI::SuggestionRatingDetail.last).to have_attributes(
                  comment: additional_rating_comment,
                  updated_by: instructor,
                  question_label: question.label,
                  attempt:
                )
              end
            end
          end

          context 'when the rating comment is blank' do
            let(:additional_rating_comment) { '' }

            context 'when a suggestion rating details record already exists,' do
              let!(:rating_detail) do
                create(
                  :ai_suggestion_rating_detail,
                  attempt:,
                  question_label: question.label
                )
              end

              it 'destroys the existing record' do
                expect do
                  grading_submission.submit
                end.to change(AI::SuggestionRatingDetail, :count).by(-1)

                expect(AI::SuggestionRatingDetail).not_to exist(rating_detail.id)
              end
            end

            context 'when no suggestion rating details record exists,' do
              it 'does not create any suggestion rating details record' do
                expect do
                  grading_submission.submit
                end.not_to change(AI::SuggestionRatingDetail, :count)
              end
            end
          end
        end

        context 'when no additional rating details are provided,' do
          before do
            params[ai_suggestion_rating_details_key] = {}
          end

          context 'when a suggestion rating details record already exists,' do
            let!(:rating_detail) do
              create(
                :ai_suggestion_rating_detail,
                attempt:,
                question_label: question.label
              )
            end

            it 'destroys the existing record' do
              expect do
                grading_submission.submit
              end.to change(AI::SuggestionRatingDetail, :count).by(-1)

              expect(AI::SuggestionRatingDetail).not_to exist(rating_detail.id)
            end
          end

          context 'when no suggestion rating details record exists,' do
            it 'does not create any suggestion rating details record' do
              expect do
                grading_submission.submit
              end.not_to change(AI::SuggestionRatingDetail, :count)
            end
          end
        end
      end

      shared_examples 'it ignores additional rating details' do
        context 'when additional rating details are provided,' do
          before do
            params[ai_suggestion_rating_details_key] = {
              'comment' => additional_rating_comment
            }
          end

          context 'when the rating comment is not blank' do
            let(:additional_rating_comment) { 'The suggestions are not precise.' }

            context 'when a suggestion rating details record already exists,' do
              let!(:rating_detail) do
                create(
                  :ai_suggestion_rating_detail,
                  attempt:,
                  question_label: question.label
                )
              end

              it 'does not update the existing record' do
                expect do
                  grading_submission.submit
                end.not_to(change { rating_detail.reload.attributes })
              end
            end

            context 'when no suggestion rating details record exists,' do
              it 'does not create any suggestion rating details record' do
                expect do
                  grading_submission.submit
                end.not_to change(AI::SuggestionRatingDetail, :count)
              end
            end
          end
        end

        context 'when no additional rating details are provided,' do
          before do
            params[ai_suggestion_rating_details_key] = {}
          end

          context 'when a suggestion rating details record already exists,' do
            let!(:rating_detail) do
              create(
                :ai_suggestion_rating_detail,
                attempt:,
                question_label: question.label
              )
            end

            it 'does not update the existing record' do
              expect do
                grading_submission.submit
              end.not_to(change { rating_detail.reload.attributes })
            end
          end

          context 'when no suggestion rating details record exists,' do
            it 'does not create any suggestion rating details record' do
              expect do
                grading_submission.submit
              end.not_to change(AI::SuggestionRatingDetail, :count)
            end
          end
        end
      end

      context 'when an AI comment is marked as accepted and edited,' do
        shared_examples 'it submits a feedback item and marks the AI comment as accepted and edited' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                comment: ai_overall_comment.overall_comment,
                feedback_notification: true,
                feedback_item_ai_comments: {
                  ai_generated_comment: true
                }
              )
            )
          end

          it 'marks the AI comment as accepted and edited' do
            expect do
              grading_submission.submit
            end.to(change { ai_overall_comment.reload.attributes })

            expect(ai_overall_comment.reload).to have_attributes(
              edited: true,
              reviewed_status: AI::OverallComment::ACCEPTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id.to_s => {
              accepted: 'true',
              edited: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as accepted and edited'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the AI comment as accepted and edited'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as accepted and edited'
        end
      end

      context 'when an invalid AI comment is marked as accepted,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            'invalid_id' => {
              accepted: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when a non-existent AI comment is marked as accepted,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            '999999999' => {
              accepted: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an AI comment is marked as rejected,' do
        shared_examples 'it submits a feedback item and marks the AI comment as rejected' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                comment: ai_overall_comment.overall_comment,
                feedback_item_ai_comments: {
                  ai_generated_comment: false
                },
                feedback_notification: true
              )
            )
          end

          it 'marks the AI comment as rejected' do
            expect do
              grading_submission.submit
            end.to(change { ai_overall_comment.reload.attributes })

            expect(ai_overall_comment.reload).to have_attributes(
              reviewed_status: AI::OverallComment::REJECTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as rejected'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the AI comment as rejected'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as rejected'
        end
      end

      context 'when an AI comment is marked as rejected and edited,' do
        shared_examples 'it submits a feedback item and marks the AI comment as rejected but not as edited' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                comment: ai_overall_comment.overall_comment,
                feedback_item_ai_comments: {
                  ai_generated_comment: false
                },
                feedback_notification: true
              )
            )
          end

          it 'marks the AI comment as rejected but not as edited' do
            expect do
              grading_submission.submit
            end.to(change { ai_overall_comment.reload.attributes })

            expect(ai_overall_comment.reload).to have_attributes(
              edited: false,
              reviewed_status: AI::OverallComment::REJECTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id => {
              rejected: 'true',
              edited:  'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as rejected but not as edited'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the AI comment as rejected but not as edited'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as rejected but not as edited'
        end
      end

      context 'when an invalid AI comment is marked as rejected,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            'invalid_id' => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when an non-existent AI comment is marked as rejected,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            '999999999' => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an AI comment is rated,' do
        shared_examples 'it submits a feedback item and marks the AI comment as rated' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                comment: ai_overall_comment.overall_comment,
                feedback_item_ai_comments: {
                  ai_generated_comment: false
                },
                feedback_notification: true
              )
            )
          end

          it 'marks the AI comment as rated' do
            expect do
              grading_submission.submit
            end.to(change { ai_overall_comment.reload.attributes })

            expect(ai_overall_comment.reload).to have_attributes(
              rated_by: instructor,
              rating_category_id: rating_category.id,
              rating_comment:
            )
          end
        end

        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id.to_s => {
              rating_category_id: rating_category.id.to_s,
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as rated'
          include_examples 'it handles additional rating details'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the AI comment as rated'
          include_examples 'it handles additional rating details'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the AI comment as rated'
          include_examples 'it handles additional rating details'
        end
      end

      context 'when an AI comment is rated with an invalid rating category,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id.to_s => {
              rating_category_id: 'invalid_id',
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when an AI comment is rated with a non-existent rating category,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id.to_s => {
              rating_category_id: '999999999',
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an invalid AI comment is rated,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            'invalid_id' => {
              rating_category_id: rating_category.id.to_s,
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when an non-existent AI comment is rated,' do
        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            '999999999' => {
              rating_category_id: rating_category.id.to_s,
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading,' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an AI generated correction is marked as accepted,' do
        let(:ai_grading_suggestion_1) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:ai_grading_suggestion_2) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_1.error_explanation}"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_1.id}">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment"
              data-comment-number="2">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_2.error_explanation} edited"
              data-comment-number="3"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_2.id}">
            </span>
          CORRECTION
        end

        shared_examples 'it submits a feedback item and marks the grading suggestions as accepted' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_item_ai_comments: {
                  ai_generated_inline_corrections: true
                },
                feedback_notification: true,
                inline_corrections: corrections
              )
            )
          end

          it 'marks the grading suggestions as accepted' do
            grading_submission.submit

            expect(ai_grading_suggestion_1.reload).to have_attributes(
              edited: false,
              reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
              reviewed_by: instructor
            )
            expect(ai_grading_suggestion_2.reload).to have_attributes(
              edited: true,
              reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion_1.id.to_s + ' ' => {
              accepted: 'true'
            },
            ai_grading_suggestion_2.id.to_s => {
              accepted: 'true',
              edited: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as accepted'
          include_examples 'it does not log an AI grading suggestion inconsistency'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as accepted'
          include_examples 'it does not log an AI grading suggestion inconsistency'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as accepted'
          include_examples 'it does not log an AI grading suggestion inconsistency'
        end
      end

      context 'when there is an inconsistency between AI generated corrections ' \
              'marked as accepted and AI comments found in the inline correction,' do
        let(:ai_grading_suggestion_1) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:ai_grading_suggestion_2) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_1.error_explanation}"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_1.id}">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment"
              data-comment-number="2">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="AI comment that has no matching AI grading suggestion"
              data-comment-number="3"
              data-ai-grading-suggestion-id="999999999"">
            </span>
          CORRECTION
        end

        shared_examples 'it marks the grading suggestion as accepted and logs inconsistency errors' do
          context 'on a live server,' do
            before do
              allow(Rails.env).to receive(:live?).and_return(true)
            end

            it 'submits a feedback item' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  feedback_notification: true,
                  inline_corrections: corrections,
                  feedback_item_ai_comments: {
                    ai_generated_inline_corrections: true
                  }
                )
              )
            end

            it 'marks the grading suggestion as accepted' do
              grading_submission.submit

              expect(ai_grading_suggestion_1.reload).to have_attributes(
                reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
                reviewed_by: instructor
              )
              expect(ai_grading_suggestion_2.reload).to have_attributes(
                reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
                reviewed_by: instructor
              )
            end

            it 'logs an AI grading suggestion inconsistency' do
              allow(STATS_PROXY).to receive(:warn)

              grading_submission.submit

              expect(STATS_PROXY).to have_received(:warn).with(
                application: :m3,
                environment: Rails.env,
                vhl_component: :ai_grading,
                accepted_grading_suggestions_ids_from_corrections: [
                  ai_grading_suggestion_1.id,
                  999_999_999
                ],
                accepted_grading_suggestions_ids_from_params: [
                  ai_grading_suggestion_1.id,
                  ai_grading_suggestion_2.id
                ],
                activity_id: activity.id,
                ai_grading_suggestions_params: {
                  ai_grading_suggestion_1.id => {
                    accepted: true,
                    edited: false,
                    rejected: false,
                    rating_category_id: rating_category.id,
                    rating_comment: nil
                  },
                  ai_grading_suggestion_2.id => {
                    accepted: true,
                    edited: false,
                    rejected: false,
                    rating_category_id: nil,
                    rating_comment:
                  }
                },
                attempt_id: attempt.id,
                edited_grading_suggestions_ids_from_corrections: [],
                edited_grading_suggestions_ids_from_params: [],
                event_action: 'Inconsistency between params and corrections',
                inline_correction: corrections,
                question_label: question.label
              )
            end
          end

          context 'on a NON-live server,' do
            before do
              allow(Rails.env).to receive(:live?).and_return(false)
            end

            it 'does not submit a feedback item' do
              suppress(StandardError) do
                grading_submission.submit

                expect(FeedbackItem).not_to have_received(:submit)
              end
            end

            it 'raises an error' do
              expect do
                grading_submission.submit
              end.to raise_error(StandardError, 'Inconsistency between params and corrections')
            end
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion_1.id.to_s => {
              accepted: 'true',
              edited: 'false',
              rating_category_id: rating_category.id.to_s,
              rejected: 'false'
            },
            ai_grading_suggestion_2.id.to_s => {
              accepted: 'true',
              edited: 'false',
              rating_comment:,
              rejected: 'false'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it marks the grading suggestion as accepted and logs inconsistency errors'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it marks the grading suggestion as accepted and logs inconsistency errors'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it marks the grading suggestion as accepted and logs inconsistency errors'
        end
      end

      context 'when an AI generated corrections is marked as edited but found ' \
              'not edited in the inline correction,' do
        let(:ai_grading_suggestion_1) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:ai_grading_suggestion_2) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_1.error_explanation}"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_1.id}">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment"
              data-comment-number="2">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_2.error_explanation}"
              data-comment-number="3"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_2.id}">
            </span>
          CORRECTION
        end

        shared_examples 'it marks the grading suggestion as edited and logs inconsistency errors' do
          context 'on a live server,' do
            before do
              allow(Rails.env).to receive(:live?).and_return(true)
            end

            it 'submits a feedback item' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  feedback_notification: true,
                  inline_corrections: corrections,
                  feedback_item_ai_comments: {
                    ai_generated_inline_corrections: true
                  }
                )
              )
            end

            it 'marks the grading suggestion as edited' do
              grading_submission.submit

              expect(ai_grading_suggestion_1.reload).to have_attributes(
                edited: true,
                reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
                reviewed_by: instructor
              )
              expect(ai_grading_suggestion_2.reload).to have_attributes(
                edited: false,
                reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
                reviewed_by: instructor
              )
            end

            it 'logs an AI grading suggestion inconsistency' do
              allow(STATS_PROXY).to receive(:warn)

              grading_submission.submit

              expect(STATS_PROXY).to have_received(:warn).with(
                application: :m3,
                environment: Rails.env,
                vhl_component: :ai_grading,
                accepted_grading_suggestions_ids_from_corrections: [
                  ai_grading_suggestion_1.id,
                  ai_grading_suggestion_2.id
                ],
                accepted_grading_suggestions_ids_from_params: [
                  ai_grading_suggestion_1.id,
                  ai_grading_suggestion_2.id
                ],
                activity_id: activity.id,
                ai_grading_suggestions_params: {
                  ai_grading_suggestion_1.id => {
                    accepted: true,
                    edited: true,
                    rejected: false,
                    rating_category_id: rating_category.id,
                    rating_comment: nil
                  },
                  ai_grading_suggestion_2.id => {
                    accepted: true,
                    edited: false,
                    rejected: false,
                    rating_category_id: nil,
                    rating_comment:
                  }
                },
                attempt_id: attempt.id,
                edited_grading_suggestions_ids_from_corrections: [
                ],
                edited_grading_suggestions_ids_from_params: [
                  ai_grading_suggestion_1.id
                ],
                event_action: 'Inconsistency between params and corrections',
                inline_correction: corrections,
                question_label: question.label
              )
            end
          end

          context 'on a NON-live server' do
            before do
              allow(Rails.env).to receive(:live?).and_return(false)
            end

            it 'does not submit a feedback item' do
              suppress(StandardError) do
                grading_submission.submit

                expect(FeedbackItem).not_to have_received(:submit)
              end
            end

            it 'raises an error' do
              expect do
                grading_submission.submit
              end.to raise_error(StandardError, 'Inconsistency between params and corrections')
            end
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion_1.id.to_s => {
              accepted: 'true',
              edited: 'true',
              rating_category_id: rating_category.id.to_s,
              rejected: 'false'
            },
            ai_grading_suggestion_2.id.to_s => {
              accepted: 'true',
              edited: 'false',
              rating_comment:,
              rejected: 'false'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it marks the grading suggestion as edited and logs inconsistency errors'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it marks the grading suggestion as edited and logs inconsistency errors'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it marks the grading suggestion as edited and logs inconsistency errors'
        end
      end

      context 'when an AI generated corrections is marked as not edited but found ' \
              'edited in the inline correction,' do
        let(:ai_grading_suggestion_1) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:ai_grading_suggestion_2) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_1.error_explanation} edited"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_1.id}">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment"
              data-comment-number="2">
            </span>
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion_2.error_explanation}"
              data-comment-number="3"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion_2.id}">
            </span>
          CORRECTION
        end

        shared_examples 'it marks the grading suggestion as not edited and logs inconsistency errors' do
          context 'on a live server,' do
            before do
              allow(Rails.env).to receive(:live?).and_return(true)
            end

            it 'submits a feedback item' do
              grading_submission.submit

              expect(FeedbackItem).to have_received(:submit).with(
                feedback_params.merge(
                  feedback_notification: true,
                  inline_corrections: corrections,
                  feedback_item_ai_comments: {
                    ai_generated_inline_corrections: true
                  }
                )
              )
            end

            it 'marks the grading suggestion as not edited' do
              grading_submission.submit

              expect(ai_grading_suggestion_1.reload).to have_attributes(
                edited: false,
                reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
                reviewed_by: instructor
              )
              expect(ai_grading_suggestion_2.reload).to have_attributes(
                edited: false,
                reviewed_status: AI::GradingSuggestion::ACCEPTED_STATUS,
                reviewed_by: instructor
              )
            end

            it 'logs an AI grading suggestion inconsistency' do
              allow(STATS_PROXY).to receive(:warn)

              grading_submission.submit

              expect(STATS_PROXY).to have_received(:warn).with(
                application: :m3,
                environment: Rails.env,
                vhl_component: :ai_grading,
                accepted_grading_suggestions_ids_from_corrections: [
                  ai_grading_suggestion_1.id,
                  ai_grading_suggestion_2.id
                ],
                accepted_grading_suggestions_ids_from_params: [
                  ai_grading_suggestion_1.id,
                  ai_grading_suggestion_2.id
                ],
                activity_id: activity.id,
                ai_grading_suggestions_params: {
                  ai_grading_suggestion_1.id => {
                    accepted: true,
                    edited: false,
                    rejected: false,
                    rating_category_id: rating_category.id,
                    rating_comment: nil
                  },
                  ai_grading_suggestion_2.id => {
                    accepted: true,
                    edited: false,
                    rejected: false,
                    rating_category_id: nil,
                    rating_comment:
                  }
                },
                attempt_id: attempt.id,
                edited_grading_suggestions_ids_from_corrections: [
                  ai_grading_suggestion_1.id
                ],
                edited_grading_suggestions_ids_from_params: [
                ],
                event_action: 'Inconsistency between params and corrections',
                inline_correction: corrections,
                question_label: question.label
              )
            end
          end

          context 'on a NON-live server' do
            before do
              allow(Rails.env).to receive(:live?).and_return(false)
            end

            it 'does not submit a feedback item' do
              suppress(StandardError) do
                grading_submission.submit

                expect(FeedbackItem).not_to have_received(:submit)
              end
            end

            it 'raises an error' do
              expect do
                grading_submission.submit
              end.to raise_error(StandardError, 'Inconsistency between params and corrections')
            end
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion_1.id.to_s => {
              accepted: 'true',
              edited: 'false',
              rating_category_id: rating_category.id.to_s,
              rejected: 'false'
            },
            ai_grading_suggestion_2.id.to_s => {
              accepted: 'true',
              edited: 'false',
              rating_comment:,
              rejected: 'false'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it marks the grading suggestion as not edited and logs inconsistency errors'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it marks the grading suggestion as not edited and logs inconsistency errors'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it marks the grading suggestion as not edited and logs inconsistency errors'
        end
      end

      context 'when an invalid AI generated correction is marked as accepted,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion.error_explanation}"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion.id}">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            'invalid_id' => {
              accepted: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when an non-existent AI generated correction is marked as accepted,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion.error_explanation}"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion.id}">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            '999999999' => {
              accepted: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an AI generated correction is marked as rejected,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        shared_examples 'it submits a feedback item and marks the grading suggestions as rejected' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_item_ai_comments: {
                  ai_generated_inline_corrections: false
                },
                feedback_notification: true,
                inline_corrections: corrections
              )
            )
          end

          it 'marks the grading suggestions as rejected' do
            grading_submission.submit

            expect(ai_grading_suggestion.reload).to have_attributes(
              reviewed_status: AI::GradingSuggestion::REJECTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion.id.to_s => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as rejected'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as rejected'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as rejected'
        end
      end

      context 'when an invalid AI generated correction is marked as rejected,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            'invalid_id' => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when a non-existent AI generated correction is marked as rejected,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            '999999999' => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an AI generated correction is marked as rejected,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        shared_examples 'it submits a feedback item and marks the grading suggestions as not used' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_item_ai_comments: {
                  ai_generated_inline_corrections: false
                },
                feedback_notification: true,
                inline_corrections: corrections
              )
            )
          end

          it 'marks the grading suggestions as not used' do
            grading_submission.submit

            expect(ai_grading_suggestion.reload).to have_attributes(
              reviewed_status: AI::GradingSuggestion::REJECTED_STATUS,
              reviewed_by: instructor
            )
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion.id.to_s => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as not used'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as not used'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as not used'
        end
      end

      context 'when an invalid AI generated correction is marked as rejected,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            'invalid_id' => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when a non-existent AI generated correction is marked as rejected,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            '999999999' => {
              rejected: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an AI generated correction is rated,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        shared_examples 'it submits a feedback item and marks the grading suggestions as rated' do
          it 'submits a feedback item' do
            grading_submission.submit

            expect(FeedbackItem).to have_received(:submit).with(
              feedback_params.merge(
                feedback_item_ai_comments: {
                  ai_generated_inline_corrections: false
                },
                feedback_notification: true,
                inline_corrections: corrections
              )
            )
          end

          it 'marks the grading suggestions as rated' do
            grading_submission.submit

            expect(ai_grading_suggestion.reload).to have_attributes(
              rated_by: instructor,
              rating_category_id: rating_category.id,
              rating_comment:
            )
          end
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion.id.to_s => {
              rating_category_id: rating_category.id.to_s,
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as rated'
          include_examples 'it handles additional rating details'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as rated'
          include_examples 'it handles additional rating details'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it submits a feedback item and marks the grading suggestions as rated'
          include_examples 'it handles additional rating details'
        end
      end

      context 'when an AI generated correction is rated with an invalid rating category,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion.id.to_s => {
              rating_category_id: 'invalid_id',
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when an AI generated correction is rated with a non-existent rating category,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion.id.to_s => {
              rating_category_id: '999999999',
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when an invalid AI generated correction is rated,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            'invalid_id' => {
              rating_category_id: rating_category.id.to_s,
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises an argument error and does not submit a feedback item'
        end
      end

      context 'when a non-existent AI generated correction is rated,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="non AI comment">
            </span>
          CORRECTION
        end

        before do
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            '999999999' => {
              rating_category_id: rating_category.id.to_s,
              rating_comment:
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it raises a record not found error and does not submit a feedback item'
        end
      end

      context 'when no AI generated corrections and no overall comments are rated,' do
        let(:ai_grading_suggestion) do
          create(
            :ai_grading_suggestion,
            activity:,
            attempt:,
            question_label: question.label
          )
        end
        let(:corrections) do
          <<~CORRECTION
            <span
              class="js-comment-inline"
              data-comment-inline="#{ai_grading_suggestion.error_explanation}"
              data-comment-number="1"
              data-ai-grading-suggestion-id="#{ai_grading_suggestion.id}">
            </span>
          CORRECTION
        end

        shared_examples 'it handles additional rating details when present' do
          context 'when additional rating details are provided,' do
            before do
              params[ai_suggestion_rating_details_key] = {
                'comment' => additional_rating_comment
              }
            end

            context 'when the rating comment is not blank' do
              let(:additional_rating_comment) { 'The suggestions are not precise.' }

              context 'when a suggestion rating details record already exists,' do
                let!(:rating_detail) do
                  create(
                    :ai_suggestion_rating_detail,
                    attempt:,
                    question_label: question.label
                  )
                end

                it 'destroys the existing record' do
                  expect do
                    grading_submission.submit
                  end.to change(AI::SuggestionRatingDetail, :count).by(-1)

                  expect(AI::SuggestionRatingDetail).not_to exist(rating_detail.id)
                end
              end

              context 'when no suggestion rating details record exists,' do
                it 'does not create any suggestion rating details record' do
                  expect do
                    grading_submission.submit
                  end.not_to change(AI::SuggestionRatingDetail, :count)
                end
              end
            end

            context 'when the rating comment is blank' do
              let(:additional_rating_comment) { '' }

              context 'when a suggestion rating details record already exists,' do
                let!(:rating_detail) do
                  create(
                    :ai_suggestion_rating_detail,
                    attempt:,
                    question_label: question.label
                  )
                end

                it 'destroys the existing record' do
                  expect do
                    grading_submission.submit
                  end.to change(AI::SuggestionRatingDetail, :count).by(-1)

                  expect(AI::SuggestionRatingDetail).not_to exist(rating_detail.id)
                end
              end

              context 'when no suggestion rating details record exists,' do
                it 'does not create any suggestion rating details record' do
                  expect do
                    grading_submission.submit
                  end.not_to change(AI::SuggestionRatingDetail, :count)
                end
              end
            end
          end

          context 'when no additional rating details are provided,' do
            before do
              params[ai_suggestion_rating_details_key] = {}
            end

            context 'when a suggestion rating details record already exists,' do
              let!(:rating_detail) do
                create(
                  :ai_suggestion_rating_detail,
                  attempt:,
                  question_label: question.label
                )
              end

              it 'destroys the existing record' do
                expect do
                  grading_submission.submit
                end.to change(AI::SuggestionRatingDetail, :count).by(-1)

                expect(AI::SuggestionRatingDetail).not_to exist(rating_detail.id)
              end
            end

            context 'when no suggestion rating details record exists,' do
              it 'does not create any suggestion rating details record' do
                expect do
                  grading_submission.submit
                end.not_to change(AI::SuggestionRatingDetail, :count)
              end
            end
          end
        end

        before do
          params[comment_key] = ai_overall_comment.overall_comment
          params[ai_overall_comment_key] = {
            ai_overall_comment.id.to_s => {
              accepted: 'true'
            }
          }
          params[inline_corrections_key] = corrections
          params[ai_grading_suggestions_key] = {
            ai_grading_suggestion.id.to_s => {
              accepted: 'true'
            }
          }
        end

        context 'when the instructor is allowed to use AI grading suggestions' do
          before do
            instructor.grant_access_to_ai_grading_suggestions
          end

          include_examples 'it handles additional rating details when present'
        end

        context 'when the program has the AI grading feature enabled,' do
          before do
            enable_ai_grading_feature_for_program(program:)
          end

          include_examples 'it handles additional rating details when present'
        end

        context 'when the program has the AI grading feature disabled and the ' \
                'instructor is not allowed to use AI grading,' do
          before do
            instructor.revoke_access_to_ai_grading_suggestions
          end

          include_examples 'it handles additional rating details when present'
        end
      end
    end
  end

  describe 'concurrent enrollment AI bug detection' do
    let(:activity) { create(:activity, activity_type: 'composition') }
    let(:ai_grading_suggestion) { create(:ai_grading_suggestion, attempt:, question_label: question.label) }
    let(:ai_overall_comment) { create(:ai_overall_comment, attempt:, question_label: question.label) }
    let(:other_section) { create(:section, course: section.course) }
    let(:other_attempt) { create(:attempt, activity:, section: other_section, user: student) }
    let(:other_ai_suggestion) { create(:ai_grading_suggestion, attempt: other_attempt, question_label: question.label) }
    let(:other_ai_comment) { create(:ai_overall_comment, attempt: other_attempt, question_label: question.label) }

    before do
      allow(FeedbackItem).to receive(:submit)
    end

    describe '#attempt_matches_ai_grading_params?' do
      context 'when no AI params are present' do
        it 'returns true (backward compatibility)' do
          expect(grading_submission.send(:attempt_matches_ai_grading_params?)).to be(true)
        end
      end

      context 'when AI objects belong to current attempt' do
        before do
          params[ai_grading_suggestions_key] = { ai_grading_suggestion.id => { accepted: true } }
          params[ai_overall_comment_key] = { ai_overall_comment.id => { accepted: true } }
        end

        it 'returns true' do
          expect(grading_submission.send(:attempt_matches_ai_grading_params?)).to be(true)
        end
      end

      context 'when AI objects belong to different attempt (concurrent enrollment bug)' do
        before do
          params[ai_grading_suggestions_key] = { other_ai_suggestion.id => { accepted: true } }
          params[ai_overall_comment_key] = { other_ai_comment.id => { accepted: true } }
        end

        it 'returns false' do
          expect(grading_submission.send(:attempt_matches_ai_grading_params?)).to be(false)
        end
      end

      context 'when AI objects do not exist (non-existent IDs)' do
        before do
          params[ai_grading_suggestions_key] = { '999999' => { accepted: true } }
          params[ai_overall_comment_key] = { '888888' => { accepted: true } }
        end

        it 'returns true (allows normal validation to handle the error)' do
          expect(grading_submission.send(:attempt_matches_ai_grading_params?)).to be(true)
        end
      end

      context 'when only AI suggestions are present and belong to current attempt' do
        before do
          params[ai_grading_suggestions_key] = { ai_grading_suggestion.id => { accepted: true } }
        end

        it 'returns true' do
          expect(grading_submission.send(:attempt_matches_ai_grading_params?)).to be(true)
        end
      end

      context 'when only AI comments are present and belong to current attempt' do
        before do
          params[ai_overall_comment_key] = { ai_overall_comment.id => { accepted: true } }
        end

        it 'returns true' do
          expect(grading_submission.send(:attempt_matches_ai_grading_params?)).to be(true)
        end
      end
    end

    context 'when concurrent enrollment + AI grading bug is detected' do
      before do
        params[ai_grading_suggestions_key] = { other_ai_suggestion.id => { accepted: true } }
        params[ai_overall_comment_key] = { other_ai_comment.id => { accepted: true } }
        allow(grading_submission).to receive(:ai_grading_enabled?).and_return(true)
      end

      it 'skips AI validations' do
        allow(grading_submission).to receive(:validate_ai_grading_params)
        allow(grading_submission).to receive(:check_for_ai_grading_use_inconsistency)

        grading_submission.submit

        expect(grading_submission).not_to have_received(:validate_ai_grading_params)
        expect(grading_submission).not_to have_received(:check_for_ai_grading_use_inconsistency)
      end

      it 'does not submit feedback' do
        params[comment_key] = 'instructor comment'

        grading_submission.submit

        expect(FeedbackItem).not_to have_received(:submit)
      end

      it 'sets concurrent enrollment AI warning' do
        grading_submission.submit

        expect(grading_submission.concurrent_enrollment_ai_bug_detected).to be_truthy
      end

      it 'returns nil' do
        result = grading_submission.submit

        expect(result).to be_nil
      end

      it 'skips AI update methods' do
        allow(grading_submission).to receive(:update_ai_overall_comments)
        allow(grading_submission).to receive(:update_ai_grading_suggestions)
        allow(grading_submission).to receive(:update_ai_suggestion_rating_details)

        grading_submission.submit

        expect(grading_submission).not_to have_received(:update_ai_overall_comments)
        expect(grading_submission).not_to have_received(:update_ai_grading_suggestions)
        expect(grading_submission).not_to have_received(:update_ai_suggestion_rating_details)
      end
    end
  end
end
