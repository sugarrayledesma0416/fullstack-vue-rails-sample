describe AI::InstructorGrading::SuggestionRatingDetailPresenter do
  let(:program) { create(:program) }
  let(:section) { create(:section, program:) }
  let(:open_ended_activity) { create(:activity, activity_type: 'open_ended') }
  let(:open_ended_activity_2) { create(:activity, activity_type: 'open_ended') }
  let(:composition_activity) { create(:activity, activity_type: 'composition') }
  let(:composition_activity_2) { create(:activity, activity_type: 'composition') }
  let(:instructor) { create(:instructor) }
  let(:student) { create(:student) }
  let(:student_2) { create(:student) }
  let(:open_ended_attempt) { create(:attempt, activity: open_ended_activity, section:, user: student) }
  let(:open_ended_attempt_2) { create(:attempt, activity: open_ended_activity, section:, user: student_2) }
  let(:composition_attempt) { create(:attempt, activity: composition_activity, section:, user: student) }
  let(:composition_attempt_2) { create(:attempt, activity: composition_activity, section:, user: student_2) }
  let(:rating_category) { create(:ai_suggestion_rating_category) }

  # Composition activity 1 questions
  let(:composition_question_1) do
    double(
      MaestroActivityEngine::ActivityContent::Composition::Item,
      label: 'question_1',
      rank: 1
    )
  end

  # Composition activity 1 grading suggestions
  let(:composition_ai_grading_suggestion_1) do
    create(
      :ai_grading_suggestion,
      activity: composition_activity,
      attempt: composition_attempt,
      question_label: composition_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Composition activity 1 second student's grading suggestions
  let(:composition_ai_grading_suggestion_2) do
    create(
      :ai_grading_suggestion,
      activity: composition_activity,
      attempt: composition_attempt_2,
      question_label: composition_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Composition activity 1 first student's overall comments
  let(:composition_ai_overall_comment_1) do
    create(
      :ai_overall_comment,
      activity: composition_activity,
      attempt: composition_attempt,
      question_label: composition_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Composition activity 1 second student's overall comments
  let(:composition_ai_overall_comment_2) do
    create(
      :ai_grading_suggestion,
      activity: composition_activity,
      attempt: composition_attempt_2,
      question_label: composition_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Open ended activity 1 questions
  let(:open_ended_question_1) do
    double(
      MaestroActivityEngine::ActivityContent::OpenEnded::Item,
      label: 'question_1',
      rank: 1
    )
  end

  let(:open_ended_question_2) do
    double(
      MaestroActivityEngine::ActivityContent::OpenEnded::Item,
      label: 'question_2',
      rank: 2
    )
  end

  # Open ended activity 1 first student's grading suggestions
  let(:open_ended_ai_grading_suggestion_1) do
    create(
      :ai_grading_suggestion,
      activity: open_ended_activity,
      attempt: open_ended_attempt,
      question_label: open_ended_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  let(:open_ended_ai_grading_suggestion_2) do
    create(
      :ai_grading_suggestion,
      activity: open_ended_activity,
      attempt: open_ended_attempt,
      question_label: open_ended_question_2.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Open ended activity 1 second student's grading suggestions
  let(:open_ended_ai_grading_suggestion_3) do
    create(
      :ai_grading_suggestion,
      activity: open_ended_activity,
      attempt: open_ended_attempt_2,
      question_label: open_ended_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  let(:open_ended_ai_grading_suggestion_4) do
    create(
      :ai_grading_suggestion,
      activity: open_ended_activity,
      attempt: open_ended_attempt_2,
      question_label: open_ended_question_2.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Open ended activity 1 first student's overall comments
  let!(:open_ended_ai_overall_comment_1) do
    create(
      :ai_overall_comment,
      activity: open_ended_activity,
      attempt: open_ended_attempt,
      question_label: open_ended_question_1.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  # Open ended activity 1 second student's overall comments
  let!(:open_ended_ai_overall_comment_2) do
    create(
      :ai_overall_comment,
      activity: open_ended_activity,
      attempt: open_ended_attempt_2,
      question_label: open_ended_question_2.label,
      rated_by_id: instructor.id,
      rating_category:
    )
  end

  before do
    allow(open_ended_activity).to receive(:questions).and_return([open_ended_question_1, open_ended_question_2])
    allow(composition_activity).to receive(:questions).and_return([composition_question_1])
  end

  describe '#current_question' do
    context 'when the activity is open ended' do
      it 'returns the question based on the page number' do
        presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 2)
        expect(presenter.current_question.label).to eq(open_ended_question_2.label)
      end

      it 'returns the first question by default' do
        presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
        expect(presenter.current_question.label).to eq(open_ended_question_1.label)
      end
    end

    context 'when the activity is composition' do
      it 'returns always the rank 1 question' do
        presenter = described_class.new(program:, activity: composition_activity, instructor:, page: 2)
        expect(presenter.current_question.rank).to eq(1)
      end
    end
  end

  describe '#total_pages' do
    it 'calculates total pages correctly' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      # 2 attempts for the open ended activity
      expect(presenter.total_pages).to eq(2)
    end
  end

  describe '#current_page' do
    it 'clamps the page number between 1 and total_pages' do
      allow_any_instance_of(described_class).to receive(:total_pages).and_return(5)
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 7)
      expect(presenter.current_page).to eq(5)
    end

    it 'returns 1 if page is less than 1' do
      allow_any_instance_of(described_class).to receive(:total_pages).and_return(5)
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 0)
      expect(presenter.current_page).to eq(1)
    end
  end

  describe '#next_page' do
    it 'returns next page if it exists' do
      allow_any_instance_of(described_class).to receive(:total_pages).and_return(5)
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 3)
      expect(presenter.next_page).to eq(4)
    end

    it 'returns nil if on last page' do
      allow_any_instance_of(described_class).to receive(:total_pages).and_return(3)
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 3)
      expect(presenter.next_page).to be_nil
    end
  end

  describe '#previous_page' do
    it 'returns previous page if it exists' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 2)
      expect(presenter.previous_page).to eq(1)
    end

    it 'returns nil if on first page' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:, page: 1)
      expect(presenter.previous_page).to be_nil
    end
  end

  describe '#current_attempt' do
    it 'returns the correct attempt' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      allow(presenter).to receive(:current_attempt_id).and_return(open_ended_attempt.id)
      expect(presenter.current_attempt).to eq(open_ended_attempt)
    end
  end

  describe '#student_response' do
    it 'returns sanitized response' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      allow(presenter).to receive(:current_attempt).and_return(open_ended_attempt)
      allow(open_ended_attempt.results).to receive(:response).with(open_ended_question_1.label).and_return('<b>Respuesta</b>')

      expect(presenter.student_response(open_ended_question_1)).to eq('Respuesta')
    end
  end

  describe '#current_grading_suggestions' do
    it 'returns grading suggestions for the current attempt' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      allow(presenter).to receive(:current_attempt_id).and_return(open_ended_attempt.id)
      allow(presenter).to receive(:current_question).and_return(open_ended_question_1)

      expect(presenter.current_grading_suggestions).to include(open_ended_ai_grading_suggestion_1)
    end
  end

  describe '#current_overall_comments' do
    it 'returns overall comments for the current attempt' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      allow(presenter).to receive(:current_attempt_id).and_return(open_ended_attempt.id)
      allow(presenter).to receive(:current_question).and_return(open_ended_question_1)

      expect(presenter.current_overall_comments).to include(open_ended_ai_overall_comment_1)
    end
  end

  describe '#activity_type_is_open_ended?' do
    it 'returns true for open ended activities' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      expect(presenter.activity_type_is_open_ended?).to be(true)
    end

    it 'returns false for composition activities' do
      presenter = described_class.new(program:, activity: composition_activity, instructor:)
      expect(presenter.activity_type_is_open_ended?).to be(false)
    end
  end

  describe '#activity_type_is_composition?' do
    it 'returns true for composition activities' do
      presenter = described_class.new(program:, activity: composition_activity, instructor:)
      expect(presenter.activity_type_is_composition?).to be(true)
    end

    it 'returns false for open ended activities' do
      presenter = described_class.new(program:, activity: open_ended_activity, instructor:)
      expect(presenter.activity_type_is_composition?).to be(false)
    end
  end
end
