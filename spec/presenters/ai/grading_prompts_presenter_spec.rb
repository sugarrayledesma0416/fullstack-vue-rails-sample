describe AI::GradingPromptsPresenter do
  let(:presenter) { described_class.new }

  describe '#grading_suggestion_stats' do
    context 'when there are no prompts with ratings,' do
      it 'returns an empty statistics object for each prompt' do
        prompt_1 = create(:ai_grading_suggestion_prompt)
        prompt_2 = create(:ai_grading_suggestion_prompt)

        expect(
          [
            presenter.grading_suggestion_stats(prompt_1.id).empty?,
            presenter.grading_suggestion_stats(prompt_2.id).empty?
          ]
        ).to eq([true, true])
      end
    end

    context 'when there are prompts with ratings,' do
      let(:prompt_1) { create(:ai_grading_suggestion_prompt) }
      let(:prompt_2) { create(:ai_grading_suggestion_prompt) }

      before do
        # create out of order to verify sorting by label.
        category_2 = create(:ai_suggestion_rating_category, label: 'b')
        category_1 = create(:ai_suggestion_rating_category, label: 'a')

        suggestion_1 = create(:ai_grading_suggestion, prompt: prompt_1)
        suggestion_2 = create(:ai_grading_suggestion, prompt: prompt_1)
        suggestion_3 = create(:ai_grading_suggestion, prompt: prompt_2)

        create(
          :ai_grading_suggestion_rating,
          rating_category: category_1,
          grading_suggestion: suggestion_1
        )

        create(
          :ai_grading_suggestion_rating,
          rating_category: category_1,
          grading_suggestion: suggestion_1
        )

        create(
          :ai_grading_suggestion_rating,
          rating_category: category_2,
          grading_suggestion: suggestion_2
        )

        create(
          :ai_grading_suggestion_rating,
          rating_category: category_2,
          grading_suggestion: suggestion_3
        )
      end

      it 'returns a statistics object with ratings for the specified prompt' do
        expect(presenter.grading_suggestion_stats(prompt_1.id)).to have_attributes(
          categories: [
            { label: 'a', percentage: 66.7 },
            { label: 'b', percentage: 33.3 }
          ],
          empty?: false,
          total_count: 3
        )
      end

      it 'returns a statistics object with only one category when all ' \
         'ratings are for the same category' do
        expect(presenter.grading_suggestion_stats(prompt_2.id)).to have_attributes(
          categories: [
            { label: 'b', percentage: 100.0 }
          ],
          empty?: false,
          total_count: 1
        )
      end
    end
  end

  describe '#overall_comment_stats' do
    context 'when there are no prompts with ratings,' do
      it 'returns an empty statistics object for each prompt' do
        prompt_1 = create(:ai_overall_comment_prompt)
        prompt_2 = create(:ai_overall_comment_prompt)

        expect(
          [
            presenter.overall_comment_stats(prompt_1.id).empty?,
            presenter.overall_comment_stats(prompt_2.id).empty?
          ]
        ).to eq([true, true])
      end
    end

    context 'when there are prompts with ratings,' do
      let(:prompt_1) { create(:ai_overall_comment_prompt) }
      let(:prompt_2) { create(:ai_overall_comment_prompt) }

      before do
        # create out of order to verify sorting by label.
        category_2 = create(:ai_suggestion_rating_category, label: 'b')
        category_1 = create(:ai_suggestion_rating_category, label: 'a')

        comment_1 = create(:ai_overall_comment, prompt: prompt_1)
        comment_2 = create(:ai_overall_comment, prompt: prompt_1)
        comment_3 = create(:ai_overall_comment, prompt: prompt_2)

        create(
          :ai_overall_comment_rating,
          rating_category: category_1,
          overall_comment: comment_1
        )

        create(
          :ai_overall_comment_rating,
          rating_category: category_1,
          overall_comment: comment_1
        )

        create(
          :ai_overall_comment_rating,
          rating_category: category_2,
          overall_comment: comment_2
        )

        create(
          :ai_overall_comment_rating,
          rating_category: category_2,
          overall_comment: comment_3
        )
      end

      it 'returns a statistics object with ratings for the specified prompt' do
        expect(presenter.overall_comment_stats(prompt_1.id)).to have_attributes(
          categories: [
            { label: 'a', percentage: 66.7 },
            { label: 'b', percentage: 33.3 }
          ],
          empty?: false,
          total_count: 3
        )
      end

      it 'returns a statistics object with only one category when all ' \
         'ratings are for the same category' do
        expect(presenter.overall_comment_stats(prompt_2.id)).to have_attributes(
          categories: [
            { label: 'b', percentage: 100.0 }
          ],
          empty?: false,
          total_count: 1
        )
      end
    end
  end
end
