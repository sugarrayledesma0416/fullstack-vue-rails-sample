describe Instructor::GradingTasksController do
  describe '#start_ai_feedback' do
    before do
      populate_instructor_program_and_focus
      @grading_set = double(GradingSet, id: 42)
      @activity = create(:activity, activity_type: 'open_ended')
      @section = create(:section)
      @attempts = create_list(:attempt, 3, activity: @activity, section: @section)

      allow(GradingSet).to receive(:create_or_update).and_return(@grading_set)
      allow(AI::GradingSuggestionWorker).to receive(:perform_async)
    end

    def do_request
      post :start_ai_feedback, params: {
        activity_id: @activity.id,
        program_id: @program.id,
        section_id: @section.id
      }
    end

    context 'when creating grading set' do
      it 'creates or retrieves the grading set' do
        expect(GradingSet).to receive(:create_or_update).with(
          @instructor.id,
          {
            activity_id: @activity.id,
            program_id: @program.id
          },
          []
        ).and_return(@grading_set)

        do_request
      end
    end

    context 'when handling existing grading jobs' do
      let!(:failed_jobs) do
        @attempts.map do |attempt|
          create(:ai_grading_suggestion_job,
            attempt: attempt,
            status: 'failed'
          )
        end
      end

      let!(:processing_jobs) do
        @attempts.map do |attempt|
          create(:ai_grading_suggestion_job,
            attempt: attempt,
            status: 'processing'
          )
        end
      end

      it 'updates failed jobs to processing status' do
        do_request
        failed_jobs.each do |job|
          expect(job.reload.status).to eq('processing')
        end
      end

      it 'does not modify jobs that are already processing' do
        do_request
        processing_jobs.each do |job|
          expect(job.reload.status).to eq('processing')
        end
      end
    end

    context 'when enqueueing worker' do
      it 'enqueues the AI GradingSuggestionWorker with attempt ids' do
        attempt_ids = @attempts.map(&:id)
        expect(AI::GradingSuggestionWorker).to receive(:perform_async).with(attempt_ids)
        do_request
      end
    end

    context 'when responding' do
      it 'returns successful JSON response with grading set id and status' do
        do_request
        expect(response).to be_successful
        expect(response.content_type).to include('application/json')

        json = response.parsed_body
        expect(json).to match({
          'grading_set_id' => 42,
          'status' => 'processing'
        })
      end
    end
  end

  describe '#grading_status' do
    before do
      populate_instructor_program_and_focus
      @activity = create(:activity, activity_type: 'open_ended')
      @section = create(:section)
    end

    it 'returns a JSON response with the status from SuggestionBatchStatus' do
      status_service = instance_double(AI::SuggestionBatchStatus)
      allow(AI::SuggestionBatchStatus).to receive(:new)
        .with(@activity.id.to_s, @section.id.to_s)
        .and_return(status_service)

      allow(status_service).to receive(:status).and_return('partial_ready')

      get :grading_status, params: {
        activity_id: @activity.id,
        section_id: @section.id
      }

      expect(response).to be_successful
      json = response.parsed_body
      expect(json['status']).to eq('partial_ready')
    end
  end

  describe '#grade_activity' do
    before do
      populate_instructor_program_and_focus
      @activity = create(:activity, activity_type: 'open_ended')
      @grading_set = double(GradingSet, id: 42)
      allow(GradingSet).to receive(:create_or_update).and_return(@grading_set)
      allow(@grading_set).to receive(:activity).and_return(@activity)
      allow(@grading_set).to receive(:first_gradable_student).and_return(1)
    end

    def do_request(task_type = 'needs_grading')
      get :grade_activity, params: {
        program_id: @program.id,
        activity_id: @activity.id,
        task_type: task_type
      }
    end

    context 'when activity is chat or recording' do
      before do
        allow(@activity).to receive(:chat_or_recording?).and_return(true)
      end

      it 'updates grading_set to show comments' do
        expect(@grading_set).to receive(:update).with(show_comments: true)
        do_request
      end
    end

    context 'when user has spotcheck grading style' do
      before do
        allow(@instructor).to receive(:setting)
          .with(Setting::GradingTasks::GradingStyle)
          .and_return(Setting::GradingTasks::GradingStyle::SPOTCHECK)
      end

      it 'redirects to spotcheck activity index' do
        do_request
        expect(response).to redirect_to(
          instructor_spotcheck_activity_index_path(
            @program.id,
            @activity.id,
            task_type: 'needs_grading'
          )
        )
      end
    end

    context 'when user has normal grading style' do
      before do
        allow(@instructor).to receive(:setting)
          .with(Setting::GradingTasks::GradingStyle)
          .and_return('normal')
      end

      it 'redirects to edit grading set path' do
        do_request
        expect(response).to redirect_to(
          edit_instructor_grading_set_path(
            @program.id,
            @grading_set,
            student_id: 1,
            task_type: 'needs_grading',
            return_to: nil
          )
        )
      end

      it 'includes return_to parameter when provided' do
        get :grade_activity, params: {
          program_id: @program.id,
          activity_id: @activity.id,
          task_type: 'needs_grading',
          return_to: 'some_path'
        }

        expect(response).to redirect_to(
          edit_instructor_grading_set_path(
            @program.id,
            @grading_set,
            student_id: 1,
            task_type: 'needs_grading',
            return_to: 'some_path'
          )
        )
      end
    end
  end

  describe '#find_or_create_grading_set' do
    before do
      populate_instructor_program_and_focus
      @activity = create(:activity)
      @student_ids = [1, 2, 3]

      allow(controller).to receive(:fetch_student_ids)
        .with(@activity.id)
        .and_return(@student_ids)
    end

    def do_request
      get :find_or_create_grading_set_id, params: {
        program_id: @program.id,
        activity_id: @activity.id
      }
    end

    context 'when successful' do
      let(:grading_set) { double(GradingSet, id: 42) }

      before do
        allow(GradingSet).to receive(:create_or_update)
          .with(
            @instructor.id,
            {
              activity_id: @activity.id,
              program_id: @program.id
            },
            @student_ids
          )
          .and_return(grading_set)
      end

      it 'returns successful JSON with grading set id' do
        do_request
        expect(response).to be_successful
        expect(response.parsed_body).to eq({ 'grading_set_id' => 42 })
      end
    end

    context 'when there is an error' do
      before do
        allow(GradingSet).to receive(:create_or_update)
          .and_raise(StandardError.new("Error creating grading set"))
      end

      it 'returns error status and message' do
        do_request
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.parsed_body).to eq({ 'error' => 'Error creating grading set' })
      end
    end
  end
end
