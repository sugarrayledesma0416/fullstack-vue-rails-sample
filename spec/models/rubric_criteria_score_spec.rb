describe RubricCriteriaScore do
  let(:student) { create(:student) }
  let(:section) { create(:section) }
  let(:activity) { create(:activity) }
  let(:attempt) do
    create(
      :attempt,
      activity: activity,
      section: section,
      user: student
    )
  end

  let(:params) do
    {
      activity: activity,
      student: student,
      section: section,
      criteria: ActionController::Parameters.new(
        attempt.id.to_s => {
          'Content' => '5',
          'Organization' => '3',
          'Accuracy' => '4'
        }
      )
    }
  end

  let(:criteria_score_json) do
    "{\"Content\":\"4\", \"Organization\":\"3\", \"Accuracy\":\"5\"}"
  end

  let(:rubric_criteria_score_hash) do
    { 'Content' => 5.5, 'Organization' => 5, 'Accuracy' => 5 }
  end

  let(:criterias) do
    criterias = []
    mae_class = MaestroActivityEngine::ActivityContent::Rubric::Criteria
    rubric_criteria_score_hash.each do |k, v|
      criterias << mae_class.new.tap do |obj|
        obj.title = k
        obj.max_score = v
      end
    end
    criterias
  end

  let(:rubric) { OpenStruct.new(criterias: criterias) }

  let(:rubric_criteria_scores) do
    create(:rubric_criteria_score, criteria_score_json: criteria_score_json)
  end

  describe '.submit' do
    before do
      allow(Attempt).to receive(:find_by_student_section_and_activity)
        .and_return(attempt)
      allow(attempt).to receive(:attempt_revision).and_return(activity)
      allow(activity).to receive(:rubric).and_return(rubric)
    end

    describe 'when there is no rubric criteria score record for the attempt' do
      it 'creates a rubric criteria score record for the attempt' do
        expect { described_class.submit(params) }.to change(described_class, :count).by(1)
      end
    end

    describe 'when there is a rubric criteria score record for the attempt' do
      before do
        described_class.create(
          attempt_id: attempt.id,
          criteria_score_json: '{\'Content\':\'5\', \'Organization\':\'2\', \'Accuracy\':\'5\'}'
        )
      end

      it 'does not create a new record for the attempt' do
        expect { described_class.submit(params) }.not_to change(described_class, :count)
      end

      it 'updates the criteria_score_json column for the existing record' do
        rubric_criteria_score = described_class.find_by(attempt_id: attempt.id)

        expect { described_class.submit(params) }.to change {
          rubric_criteria_score.reload.criteria_score_json
        }.from('{\'Content\':\'5\', \'Organization\':\'2\', \'Accuracy\':\'5\'}')
          .to(params[:criteria][attempt.id.to_s].to_unsafe_hash.to_json)
      end
    end
  end

  describe '.validate_criteria' do
    context 'with valid data' do
      it 'does not raise an error if the criteria titles match the rubric' do
        expect do
          described_class.validate_criteria(rubric_criteria_score_hash, rubric)
        end.not_to raise_error
      end
    end

    context 'with invalid data' do
      it 'raises an error if the criteria titles do not match the rubric' do
        msg = 'Criteria titles do not match the rubric'
        bad_hash = { 'Bad Title' => '5', 'Organization' => '2', 'Accuracy' => '5' }
        expect do
          described_class.validate_criteria(bad_hash, rubric)
        end.to raise_error(StandardError, msg)
      end

      it 'raises an error if any criteria is over the max score allowed' do
        msg = "Score exceeds max score of 5 for category 'Organization'"
        bad_hash = { 'Content' => '5', 'Organization' => '6', 'Accuracy' => '5' }
        expect do
          described_class.validate_criteria(bad_hash, rubric)
        end.to raise_error(StandardError, msg)
      end
    end
  end

  describe '#scores' do
    it 'returns the scores for each criteria' do
      expect(rubric_criteria_scores.scores).to eq(JSON.parse(criteria_score_json))
    end
  end

  describe '#sum' do
    it 'returns the sum of the scores for each criteria' do
      expect(rubric_criteria_scores.sum).to eq(12)
    end
  end
end
