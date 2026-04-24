describe AI::SuggestionBatchStatus, type: :service do
  let(:activity) { create(:activity) }
  let(:section) { create(:section) }
  let(:service) { described_class.new(activity.id, section.id) }

  describe '#status' do
    context 'when no attempts exist' do
      it 'returns ready' do
        expect(service.status).to eq('ready')
      end
    end

    context 'when attempts exist but no jobs' do
      before do
        create_list(:attempt, 3, activity: activity, section: section)
      end

      it 'returns processing' do
        expect(service.status).to eq('processing')
      end
    end

    context 'when all attempts have failed jobs' do
      before do
        attempts = create_list(:attempt, 3, activity: activity, section: section)
        attempts.each do |attempt|
          create(:ai_grading_suggestion_job, attempt: attempt, status: 'failed')
        end
      end

      it 'returns failed' do
        expect(service.status).to eq('failed')
      end
    end

    context 'when all attempts have completed jobs' do
      before do
        attempts = create_list(:attempt, 3, activity: activity, section: section)
        attempts.each do |attempt|
          create(:ai_grading_suggestion_job, attempt: attempt, status: 'completed')
        end
      end

      it 'returns ready' do
        expect(service.status).to eq('ready')
      end
    end

    context 'when attempts have mixed status jobs' do
      context 'when all jobs are in terminal state' do
        before do
          attempt = create(:attempt, activity: activity, section: section)
          create(:ai_grading_suggestion_job, attempt: attempt, status: 'completed')
          create(:ai_grading_suggestion_job, attempt: attempt, status: 'failed')
        end

        it 'returns completed' do
          expect(service.status).to eq('completed')
        end
      end

      context 'when some jobs are still processing' do
        before do
          attempt = create(:attempt, activity: activity, section: section)
          create(:ai_grading_suggestion_job, attempt: attempt, status: 'completed')
          create(:ai_grading_suggestion_job, attempt: attempt, status: 'processing')
        end

        it 'returns processing' do
          expect(service.status).to eq('processing')
        end
      end
    end

    context 'with multiple attempts and various job states' do
      before do
        @attempts = create_list(:attempt, 3, activity: activity, section: section)
      end

      it 'returns processing when jobs are mixed' do
        create_jobs_for_attempt(@attempts[0], ['completed'])
        create_jobs_for_attempt(@attempts[1], ['completed', 'processing'])
        create_jobs_for_attempt(@attempts[2], ['failed'])

        expect(service.status).to eq('processing')
      end

      it 'returns ready when all attempts have all completed jobs' do
        @attempts.each do |attempt|
          create_jobs_for_attempt(attempt, ['completed', 'completed'])
        end

        expect(service.status).to eq('ready')
      end

      it 'returns failed when all attempts have all failed jobs' do
        @attempts.each do |attempt|
          create_jobs_for_attempt(attempt, ['failed', 'failed'])
        end

        expect(service.status).to eq('failed')
      end
    end
  end

  private def create_jobs_for_attempt(attempt, statuses)
    statuses.each do |status|
      create(:ai_grading_suggestion_job, attempt: attempt, status: status)
    end
  end
end
