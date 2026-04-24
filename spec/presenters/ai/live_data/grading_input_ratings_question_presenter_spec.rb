describe AI::LiveData::GradingInputRatingsQuestionPresenter do
  let(:program) { create(:program_with_lessons) }
  let(:lesson) { program.lessons.first }
  let(:activity) { create(:activity, lesson:) }
  let(:question) do
    instance_double(
      MaestroActivityEngine::ActivityContent::OpenEnded::Item,
      label: 'question_01',
      html_friendly_prompt: 'write something about flowers',
      rank: 1
    )
  end
  let(:content_object) do
    instance_double(
      MaestroActivityEngine::ActivityContent::OpenEndedContent,
      questions: [question]
    )
  end
  let(:rater) do
    create(:user).tap do |user|
      user.roles << Role.create!(name: Role::AI_GRADING_EDITOR)
    end
  end
  let(:presenter_excluding_rated_inputs) do
    described_class.new(
      activity:,
      include_rated_inputs: false,
      question_rank: question.rank,
      rater:
    )
  end
  let(:presenter_including_rated_inputs) do
    described_class.new(
      activity:,
      include_rated_inputs: true,
      question_rank: question.rank,
      rater:
    )
  end

  describe '#grading_suggestion_inputs' do
    let(:attempt) { create(:attempt, activity:) }
    let(:attempt_2) { create(:attempt, activity:) }
    let(:rating_category) do
      create(:ai_internal_suggestion_rating_category)
    end
    let(:activity_extractor) do
      instance_double(
        AI::ActivityExtractor,
        activity_title: 'some activity title',
        direction_line: 'some direction line'
      )
    end
    let!(:grading_suggestion_input) do
      create(
        :ai_grading_suggestion_input,
        attempt:,
        question_label: question.label,
        student_response: 'some response from student 1'
      )
    end
    let!(:grading_suggestion_input_2) do
      create(
        :ai_grading_suggestion_input,
        attempt: attempt_2,
        question_label: question.label,
        student_response: 'some response from student 2'
      )
    end

    def serialized_grading_suggestion(grading_suggestion, include_rating: false)
      {
        id: grading_suggestion.id,
        incorrectText: grading_suggestion.incorrect_text,
        errorExplanation: grading_suggestion.error_explanation
      }.tap do |memo|
        if include_rating
          rating = AI::GradingSuggestionRating.find_by(
            grading_suggestion:,
            user: rater
          )
          if rating
            memo[:rating] = {
              comment: rating.comment,
              id: rating.id,
              ratingCategoryId: rating.rating_category_id
            }
          end
        end
      end
    end

    def serialized_overall_comment(overall_comment, include_rating: false)
      {
        id: overall_comment.id,
        overallComment: overall_comment.overall_comment,
        explanation: overall_comment.explanation
      }.tap do |memo|
        if include_rating
          rating = AI::OverallCommentRating.find_by(
            overall_comment:,
            user: rater
          )
          if rating
            memo[:rating] = {
              comment: rating.comment,
              id: rating.id,
              ratingCategoryId: rating.rating_category_id
            }
          end
        end
      end
    end

    before do
      allow(activity).to receive(:content_object).and_return(content_object)
      allow(AI::ActivityExtractor).to receive(:new).with(activity).and_return(activity_extractor)
      allow(activity_extractor).to receive(:question_by_label).with('question_01').and_return(question)
    end

    context 'when a grading input has no associated grading suggestion and overall comment,' do
      context 'when asking to include rated inputs,' do
        it 'returns no entries' do
          expect(presenter_including_rated_inputs.serialized_grading_suggestion_inputs).to be_empty
        end
      end

      context 'when asking to exclude rated inputs,' do
        it 'returns no entries' do
          expect(presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs).to be_empty
        end
      end
    end

    context 'when a grading input only has associated grading suggestions,' do
      let!(:grading_suggestion_1) do
        create(
          :ai_internal_grading_suggestion,
          grading_suggestion_input:
        )
      end
      let!(:grading_suggestion_2) do
        create(
          :ai_internal_grading_suggestion,
          grading_suggestion_input:
        )
      end

      context 'when a grading suggestion has been rated by the rater,' do
        before do
          create(
            :ai_grading_suggestion_rating,
            user: rater,
            grading_suggestion: grading_suggestion_1,
            rating_category:
          )
        end

        context 'when asking to include rated inputs,' do
          it 'returns the grading input with rated and non-rated grading suggestions' do
            expect(
              presenter_including_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [
                  serialized_grading_suggestion(grading_suggestion_1, include_rating: true),
                  serialized_grading_suggestion(grading_suggestion_2, include_rating: true)
                ],
                overallComments: []
              }
            )
          end
        end

        context 'when asking to exclude rated inputs,' do
          it 'returns the grading input with only the non-rated grading suggestions' do
            expect(
              presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [
                  serialized_grading_suggestion(grading_suggestion_2)
                ],
                overallComments: []
              }
            )
          end
        end
      end

      context 'when all the grading suggestions have been rated by the rater,' do
        before do
          create(
            :ai_grading_suggestion_rating,
            user: rater,
            grading_suggestion: grading_suggestion_1,
            rating_category:
          )
          create(
            :ai_grading_suggestion_rating,
            user: rater,
            grading_suggestion: grading_suggestion_2,
            rating_category:
          )
        end

        context 'when asking to include rated inputs,' do
          it 'returns the grading input with rated and non-rated grading suggestions' do
            expect(
              presenter_including_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [
                  serialized_grading_suggestion(grading_suggestion_1, include_rating: true),
                  serialized_grading_suggestion(grading_suggestion_2, include_rating: true)
                ],
                overallComments: []
              }
            )
          end
        end

        context 'when asking to exclude rated inputs,' do
          it 'does not return the grading input' do
            expect(
              presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
            ).to be_empty
          end
        end
      end

      context 'when a grading suggestion has been rated by a different rater,' do
        before do
          create(
            :ai_grading_suggestion_rating,
            user: create(:user),
            grading_suggestion: grading_suggestion_1,
            rating_category:
          )
        end

        context 'when asking to include rated inputs,' do
          it 'returns the grading input with rated and non-rated grading suggestions' do
            expect(
              presenter_including_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [
                  serialized_grading_suggestion(grading_suggestion_1, include_rating: true),
                  serialized_grading_suggestion(grading_suggestion_2, include_rating: true)
                ],
                overallComments: []
              }
            )
          end
        end

        context 'when asking to exclude rated inputs,' do
          it 'return the grading input with all the non-rated grading suggestions' do
            expect(
              presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [
                  serialized_grading_suggestion(grading_suggestion_1),
                  serialized_grading_suggestion(grading_suggestion_2)
                ],
                overallComments: []
              }
            )
          end
        end
      end
    end

    context 'when a grading input only has associated overall comments,' do
      let!(:overall_comment_1) do
        create(
          :ai_internal_overall_comment,
          grading_suggestion_input:
        )
      end
      let!(:overall_comment_2) do
        create(
          :ai_internal_overall_comment,
          grading_suggestion_input:
        )
      end

      context 'when an overall comment has been rated by the rater,' do
        before do
          create(
            :ai_overall_comment_rating,
            user: rater,
            overall_comment: overall_comment_1,
            rating_category:
          )
        end

        context 'when asking to include rated inputs,' do
          it 'returns the grading input with rated and non-rated overall comments' do
            expect(
              presenter_including_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [],
                overallComments: [
                  serialized_overall_comment(overall_comment_1, include_rating: true),
                  serialized_overall_comment(overall_comment_2, include_rating: true)
                ]
              }
            )
          end
        end

        context 'when asking to exclude rated inputs,' do
          it 'returns the grading input with only the non-rated overall comment' do
            expect(
              presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [],
                overallComments: [
                  serialized_overall_comment(overall_comment_2)
                ]
              }
            )
          end
        end
      end

      context 'when all the overall comment have been rated by the rater,' do
        before do
          create(
            :ai_overall_comment_rating,
            user: rater,
            overall_comment: overall_comment_1,
            rating_category:
          )
          create(
            :ai_overall_comment_rating,
            user: rater,
            overall_comment: overall_comment_2,
            rating_category:
          )
        end

        context 'when asking to include rated inputs,' do
          it 'returns the grading input with rated and non-rated overall comments' do
            expect(
              presenter_including_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [],
                overallComments: [
                  serialized_overall_comment(overall_comment_1, include_rating: true),
                  serialized_overall_comment(overall_comment_2, include_rating: true)
                ]
              }
            )
          end
        end

        context 'when asking to exclude rated inputs,' do
          it 'does not return the grading input' do
            expect(
              presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
            ).to be_empty
          end
        end
      end

      context 'when an overall comment has been rated by a different rater,' do
        before do
          create(
            :ai_overall_comment_rating,
            user: create(:user),
            overall_comment: overall_comment_1,
            rating_category:
          )
        end

        context 'when asking to include rated inputs,' do
          it 'returns the grading input with rated and non-rated overall comments' do
            expect(
              presenter_including_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [],
                overallComments: [
                  serialized_overall_comment(overall_comment_1, include_rating: true),
                  serialized_overall_comment(overall_comment_2, include_rating: true)
                ]
              }
            )
          end
        end

        context 'when asking to exclude rated inputs,' do
          it 'return the grading input with all the non-rated overall comments' do
            expect(
              presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
            ).to contain_exactly(
              {
                id: grading_suggestion_input.id,
                studentResponse: grading_suggestion_input.student_response,
                gradingSuggestions: [],
                overallComments: [
                  serialized_overall_comment(overall_comment_1),
                  serialized_overall_comment(overall_comment_2)
                ]
              }
            )
          end
        end
      end
    end

    context 'when a grading input has associated grading suggestions and overall comments,' do
      let!(:grading_suggestion_1) do
        create(
          :ai_internal_grading_suggestion,
          grading_suggestion_input:
        )
      end
      let!(:grading_suggestion_2) do
        create(
          :ai_internal_grading_suggestion,
          grading_suggestion_input:
        )
      end
      let!(:overall_comment_1) do
        create(
          :ai_internal_overall_comment,
          grading_suggestion_input:
        )
      end
      let!(:overall_comment_2) do
        create(
          :ai_internal_overall_comment,
          grading_suggestion_input:
        )
      end

      before do
        create(
          :ai_grading_suggestion_rating,
          user: rater,
          grading_suggestion: grading_suggestion_1,
          rating_category:
        )
        create(
          :ai_overall_comment_rating,
          user: rater,
          overall_comment: overall_comment_1,
          rating_category:
        )
      end

      context 'when asking to include rated inputs,' do
        it 'returns the grading input with rated and non-rated grading suggestions and overall comments' do
          expect(
            presenter_including_rated_inputs.serialized_grading_suggestion_inputs
          ).to contain_exactly(
            {
              id: grading_suggestion_input.id,
              studentResponse: grading_suggestion_input.student_response,
              gradingSuggestions: [
                serialized_grading_suggestion(grading_suggestion_1, include_rating: true),
                serialized_grading_suggestion(grading_suggestion_2, include_rating: true)
              ],
              overallComments: [
                serialized_overall_comment(overall_comment_1, include_rating: true),
                serialized_overall_comment(overall_comment_2, include_rating: true)
              ]
            }
          )
        end
      end

      context 'when asking to exclude rated inputs,' do
        it 'return the grading input with all the non-rated grading suggestions and overall comments' do
          expect(
            presenter_excluding_rated_inputs.serialized_grading_suggestion_inputs
          ).to contain_exactly(
            {
              id: grading_suggestion_input.id,
              studentResponse: grading_suggestion_input.student_response,
              gradingSuggestions: [
                serialized_grading_suggestion(grading_suggestion_2)
              ],
              overallComments: [
                serialized_overall_comment(overall_comment_2)
              ]
            }
          )
        end
      end
    end
  end
end
