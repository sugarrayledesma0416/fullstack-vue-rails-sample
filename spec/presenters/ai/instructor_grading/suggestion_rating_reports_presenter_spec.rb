describe AI::InstructorGrading::SuggestionRatingReportsPresenter do
  let(:routes) { Rails.application.routes.url_helpers }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program:) }
  let(:lesson_1_strand) { create(:toc_entry, title: '<b>b &amp; c</b>') }
  let(:lesson_2_strand) { create(:toc_entry) }
  let(:lesson_1) { create(:lesson, toc_entries: [lesson_1_strand], unit:) }
  let(:lesson_2) { create(:lesson, toc_entries: [lesson_2_strand], unit:) }
  let(:grading_suggestion_prompt) { create(:ai_grading_suggestion_prompt) }
  let(:overall_comment_prompt) { create(:ai_overall_comment_prompt) }
  let(:rating_category) { create(:ai_suggestion_rating_category) }
  let(:instructor_1) { create(:instructor) }
  let(:instructor_2) { create(:instructor) }

  let(:activity_1) do
    create(:activity, activity_type: 'composition', lesson: lesson_1, toc_location: lesson_1_strand.location.to_i)
  end
  let(:activity_2) do
    create(:activity, activity_type: 'open_ended', lesson: lesson_1, toc_location: lesson_1_strand.location.to_i)
  end

  let(:req_params) { { page: '1', toc_location: lesson_1_strand.location } }

  before do
    create(:ai_grading_suggestion, activity: activity_1, prompt_id: grading_suggestion_prompt.id,
                                   rating_category:, rating_comment: 'comment', rated_by: instructor_1)
    create(:ai_grading_suggestion, activity: activity_2, prompt_id: grading_suggestion_prompt.id,
                                   rating_category:, rating_comment: 'comment', rated_by: instructor_2)
  end

  subject(:presenter) do
    described_class.new(
      activity_type: 'composition',
      grading_suggestion_prompt:,
      overall_comment_prompt:,
      program:,
      lesson_ids: lesson_1.id.to_s,
      selected_strands: [],
      selected_instructors: [],
      req_params:
    )
  end

  describe '#initialize' do
    it 'assigns instance variables correctly' do
      expect(presenter.activity_type).to eq(['composition'])
      expect(presenter.grading_suggestion_prompt).to eq(grading_suggestion_prompt)
      expect(presenter.overall_comment_prompt).to eq(overall_comment_prompt)
      expect(presenter.program).to eq(program)
    end
  end

  describe 'Filtering' do
    context 'when filtering by selected instructors' do
      subject(:filtered_presenter) do
        described_class.new(
          activity_type: 'composition',
          grading_suggestion_prompt:,
          overall_comment_prompt:,
          program:,
          lesson_ids: lesson_1.id.to_s,
          selected_strands: [],
          selected_instructors: [instructor_1.id],
          req_params:
        )
      end

      it 'returns only activities rated by the selected instructor' do
        expect(filtered_presenter.entries.size).to eq(1)
        expect(filtered_presenter.entries.first[:rated_by_instructor]).to eq(instructor_1)
      end
    end

    context 'when filtering by lesson IDs' do
      subject(:filtered_presenter) do
        described_class.new(
          activity_type: 'composition',
          grading_suggestion_prompt:,
          overall_comment_prompt:,
          program:,
          lesson_ids: lesson_2.id.to_s,
          selected_strands: [],
          selected_instructors: [],
          req_params:
        )
      end

      it 'returns no activities since lesson_2 has no activities' do
        expect(filtered_presenter.entries).to be_empty
      end
    end

    context 'when filtering by strands' do
      subject(:filtered_presenter) do
        described_class.new(
          activity_type: 'composition',
          grading_suggestion_prompt:,
          overall_comment_prompt:,
          program:,
          lesson_ids: lesson_1.id.to_s,
          selected_strands: [lesson_1_strand.location.to_i],
          selected_instructors: [],
          req_params:
        )
      end

      it 'returns only activities matching the selected strands' do
        expect(filtered_presenter.entries.size).to eq(1)
        expect(filtered_presenter.entries.first[:activity]).to eq(activity_1)
      end
    end

    context 'when filtering by multiple criteria' do
      subject(:filtered_presenter) do
        described_class.new(
          activity_type: 'composition',
          grading_suggestion_prompt:,
          overall_comment_prompt:,
          program:,
          lesson_ids: lesson_1.id.to_s,
          selected_strands: [lesson_1_strand.location.to_i],
          selected_instructors: [instructor_1.id],
          req_params:
        )
      end

      it 'returns only activities that match all filters' do
        expect(filtered_presenter.entries.size).to eq(1)
        expect(filtered_presenter.entries.first[:rated_by_instructor]).to eq(instructor_1)
      end
    end
  end

  describe '#entries pagination' do
    let(:req_params) { { page: '2' } }

    it 'returns the correct page of results' do
      expect(presenter.entries.size).to eq(0)
    end
  end
end
