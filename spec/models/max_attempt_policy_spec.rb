describe MaxAttemptPolicy do

  let(:category) { create(:category) }
  let(:activity) { create(:activity) }
  let(:assignment) { create(:assignment, category: category) }
  let(:max_attempt_policy) { MaxAttemptPolicy.new(activity, assignment) }

  describe '#unsubmittable?' do
    it 'returns true if it is unsubmittable' do
      allow(activity).to receive(:max_attempts).and_return(0)
      expect(max_attempt_policy).to be_unsubmittable
    end

    it 'returns false if it is submittable' do
      allow(activity).to receive(:max_attempts).and_return(11)
      expect(max_attempt_policy).not_to be_unsubmittable
    end
  end

  describe '#max_attempts' do
    describe 'when there is an assignment' do
      context 'when assignment max attempt has been overriden and activity is an assessment' do
        it 'returns the number of attempts set by the instructor' do
          assessment_detail = double(AssignedAssessmentDetail, number_of_attempts: 11)
          allow(activity).to receive(:assessment?).and_return(true)
          allow(assignment).to receive(:assigned_assessment_detail).and_return(assessment_detail)

          expect(max_attempt_policy.max_attempts).to eq(11)
        end
      end

      context 'when an activity has unlimited attempts' do
        context 'when assignment exists' do
          it 'returns the maximum attempts allowed on the assignment category' do
            allow(activity).to receive(:max_attempts)
            allow(category).to receive(:max_attempts).and_return(8)

            expect(max_attempt_policy.max_attempts).to eq(8)
          end
        end
      end


      context 'when attempts allowed on the assignment category are unlimited' do
        before do
          allow(category).to receive(:max_attempts).and_return(-1)
        end

        context 'when activity has limited attempts' do
          it 'returns that limit' do
            allow(activity).to receive(:max_attempts).and_return(4)

            expect(max_attempt_policy.max_attempts).to eq(4)
          end
        end
      end

      context 'when both activity and assignment max attempts have been set' do
        it 'returns the lowest value of the two' do
          allow(activity).to receive(:max_attempts).and_return(7)
          allow(category).to receive(:max_attempts).and_return(4)

          expect(max_attempt_policy.max_attempts).to eq(4)
        end
      end
    end

    context 'when assignment does not exist' do
      context 'when activity max attempts has been set' do
        it 'returns activity maximum attempts allowed' do
          max_attempt_policy = MaxAttemptPolicy.new(activity, nil)
          allow(activity).to receive(:max_attempts).and_return(11)

          expect(max_attempt_policy.max_attempts).to eq(11)
        end
      end

      context 'when activity max attempts has not been set' do
        it 'returns -1' do
          max_attempt_policy = MaxAttemptPolicy.new(activity, nil)
          allow(activity).to receive(:max_attempts)

          expect(max_attempt_policy.max_attempts).to eq(-1)
        end
      end
    end

  end

end
