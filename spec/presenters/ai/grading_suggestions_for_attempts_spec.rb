describe AI::GradingSuggestionsForAttempts do
  let(:consumer_class) do
    Class.new do
      include AI::GradingSuggestionsForAttempts

      attr_accessor :student_attempts

      def initialize(attempts)
        self.student_attempts = attempts
      end
    end
  end

  describe '#grading_suggestion_data_for' do
    let(:attempt_1) { create(:attempt) }
    let(:attempt_2) { create(:attempt) }
    let(:question_label_1) { 'question_01' }
    let(:question_label_2) { 'question_02' }
    let(:empty_response) do
      {
        suggestions: [],
        suggestion_job: nil
      }
    end

    it 'returns an empty hash when the attempt is nil' do
      consumer = consumer_class.new([attempt_1, attempt_2])

      results = consumer.grading_suggestion_data_for(nil, question_label_1)
      expect(results).to eq(empty_response)
    end

    it 'returns an empty array of suggestions when there are no ' \
       'AI::GradingSuggestions for the specified attempt' do
      create(
        :ai_grading_suggestion,
        attempt: attempt_1,
        question_label: question_label_1
      )

      consumer = consumer_class.new([attempt_2])

      results = consumer.grading_suggestion_data_for(attempt_2, question_label_1)

      expect(results[:suggestions]).to eq([])
    end

    it 'returns an empty array of suggestions when there are no ' \
       'AI::GradingSuggestions for the specified question_label' do
      create(
        :ai_grading_suggestion,
        attempt: attempt_1,
        question_label: question_label_1
      )

      consumer = consumer_class.new([attempt_1])

      results = consumer.grading_suggestion_data_for(attempt_1, question_label_2)

      expect(results[:suggestions]).to eq([])
    end

    context 'when GradingSuggestions exist for the specified attempts' do
      let!(:suggestion_1) do
        create(
          :ai_grading_suggestion,
          attempt: attempt_1,
          question_label: question_label_1
        )
      end

      let!(:suggestion_2) do
        create(
          :ai_grading_suggestion,
          attempt: attempt_1,
          question_label: question_label_1
        )
      end

      let!(:suggestion_3) do
        create(
          :ai_grading_suggestion,
          attempt: attempt_1,
          question_label: question_label_2
        )
      end

      let!(:suggestion_4) do
        create(
          :ai_grading_suggestion,
          attempt: attempt_2,
          question_label: question_label_1
        )
      end

      let(:consumer) { consumer_class.new([attempt_1, attempt_2]) }

      it 'returns all suggestions for a given attempt and question' do
        results = consumer.grading_suggestion_data_for(attempt_1, question_label_1)

        expect(results[:suggestions]).to contain_exactly(suggestion_1, suggestion_2)
      end

      it 'returns the correct suggestions for the same attempt with a ' \
         'different question' do
        results = consumer.grading_suggestion_data_for(attempt_1, question_label_2)

        expect(results[:suggestions]).to contain_exactly(suggestion_3)
      end

      it 'returns the correct suggestions for the same question with a ' \
         'different attempt' do
        results = consumer.grading_suggestion_data_for(attempt_2, question_label_1)

        expect(results[:suggestions]).to contain_exactly(suggestion_4)
      end
    end

    it 'returns a nil suggestion_job when there is no AI::GradingSuggestionJob ' \
       'for the specified attempt' do
      create(
        :ai_grading_suggestion_job,
        attempt: attempt_1,
        question_label: question_label_1
      )

      consumer = consumer_class.new([attempt_2])

      results = consumer.grading_suggestion_data_for(attempt_2, question_label_1)

      expect(results[:suggestion_job]).to be_nil
    end

    it 'returns a nil suggestion_job when there is no AI::GradingSuggestionJob ' \
       'for the specified question' do
      create(
        :ai_grading_suggestion_job,
        attempt: attempt_1,
        question_label: question_label_1
      )

      consumer = consumer_class.new([attempt_1])

      results = consumer.grading_suggestion_data_for(attempt_1, question_label_2)

      expect(results[:suggestion_job]).to be_nil
    end

    context 'when GradingSuggestionJobs exist for the specified attempts' do
      let!(:job_1) do
        create(
          :ai_grading_suggestion_job,
          attempt: attempt_1,
          question_label: question_label_1
        )
      end

      let!(:job_2) do
        create(
          :ai_grading_suggestion_job,
          attempt: attempt_1,
          question_label: question_label_2
        )
      end

      let!(:job_3) do
        create(
          :ai_grading_suggestion_job,
          attempt: attempt_2,
          question_label: question_label_1
        )
      end

      let(:consumer) { consumer_class.new([attempt_1, attempt_2]) }

      it 'returns the job for a given attempt and question' do
        results = consumer.grading_suggestion_data_for(attempt_1, question_label_1)

        expect(results[:suggestion_job]).to eq(job_1)
      end

      it 'returns the correct job for the same attempt with a ' \
         'different question' do
        results = consumer.grading_suggestion_data_for(attempt_1, question_label_2)

        expect(results[:suggestion_job]).to eq(job_2)
      end

      it 'returns the correct job for the same question with a ' \
         'different attempt' do
        results = consumer.grading_suggestion_data_for(attempt_2, question_label_1)

        expect(results[:suggestion_job]).to eq(job_3)
      end
    end
  end
end
