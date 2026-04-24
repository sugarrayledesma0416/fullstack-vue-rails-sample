describe Gradebook::InstructorGrading, core: true do
  include GradebookEngineHelpers

  let(:summation) do
    {
      points_earned: 8.0,
      pending: false,
      points_possible: 10,
      submitted_at: Time.now
    }
  end
  let(:score_action) { create(:gb_score_action, summation: summation) }
  let(:new_points) { score_action.points_possible.to_f }
  let(:reset_partial_pending) { false }
  let(:grading) do
    described_class.new(score_action, new_points, reset_partial_pending: reset_partial_pending)
  end
  let(:new_score_action) do
    latest_score_action(activity_id: score_action.activity_id,
                        section_id: score_action.section_id,
                        user_id: score_action.user_id)
  end

  it 'updates points earned' do
    grading.process
    expect(new_score_action.points_earned).to eq new_points
  end

  it 'records the new points_earned and sets pending false' do
    grading.process
    expected_action = {'type' => 'grade',
                       'points_earned' => new_points,
                       'points_pending' => nil}
    expect(new_score_action).to_not be_pending
    expect(new_score_action).to_not be_adjusted
    expect(new_score_action.action).to eq expected_action
    expect(new_score_action).to_not be_partial_pending
  end

  context 'when the summation does not contain a partial_pending attribute' do
    let(:score_action) { create(:gb_score_action, summation: summation) }

  end

  context 'when the summation contains a partial_pending attribute set to false' do
    let(:score_action) do
      create(:gb_score_action, summation: summation.merge(partial_pending: false))
    end

    context 'when reset_partial_pending is false,' do
      let(:reset_partial_pending) { false }

      it 'sets the partial_pending attribute to false' do
        grading.process
        expect(new_score_action.partial_pending).to eq(false)
      end
    end

    context 'when reset_partial_pending is true,' do
      let(:reset_partial_pending) { true }

      it 'sets the partial_pending attribute to false' do
        grading.process
        expect(new_score_action.partial_pending).to eq(false)
      end
    end
  end

  context 'when the summation contains a partial_pending attribute set to true' do
    let(:score_action) do
      create(:gb_score_action, summation: summation.merge(partial_pending: true))
    end

    context 'when reset_partial_pending is false,' do
      let(:reset_partial_pending) { false }

      it 'does not change the partial_pending attribute' do
        grading.process
        expect(new_score_action.partial_pending).to eq(true)
      end
    end

    context 'when reset_partial_pending is true,' do
      let(:reset_partial_pending) { true }

      it 'sets the partial_pending attribute to false' do
        grading.process
        expect(new_score_action.partial_pending).to eq(false)
      end
    end
  end

  context 'when the summation does not contain a partial_pending attribute' do
    context 'when reset_partial_pending is false,' do
      let(:reset_partial_pending) { false }

      it 'does not create a partial_pending attribute' do
        grading.process
        expect(new_score_action.partial_pending).to be_nil
      end
    end

    context 'when reset_partial_pending is true,' do
      let(:reset_partial_pending) { true }

      it 'sets the partial_pending attribute to false' do
        grading.process
        expect(new_score_action.partial_pending).to eq(false)
      end
    end
  end
end
