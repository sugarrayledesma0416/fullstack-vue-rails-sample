describe Instructor::ReviewWorkController do
  let(:activity) { build_stubbed(:activity) }
  let(:section) { build_stubbed(:section) }
  let!(:score) { create(:gb_score_action, activity: activity, section: section) }
  let(:attempt) { build_stubbed(:attempt) }

  before do
    populate_instructor_program_and_focus
    allow(GradebookEngine::GradebookAPI).to receive(:find_score).and_return(score)
    allow(Attempt).to receive(:by_student_section_and_activity).and_return([attempt])
    allow(attempt).to receive(:results).and_return([{response: ''}])
    allow(Activity).to receive(:find).with(activity.id).and_return(activity)
    allow(activity).to receive(:has_rubric?).and_return(false)
    allow(activity)
      .to receive(:content_object)
      .and_return(double('ContentObject', questions: [], activity_type: 'open_ended', has_rubric?: false))
    allow(Section).to receive(:find).with(section.id).and_return(section)
  end

  shared_examples 'an action that sets up data for rubric grading' do
    let(:user_scores_for_grading_mock) { instance_double(UserScoresForGrading) }
    let(:presenter_mock) { instance_double(StudentByStudentPresenter, activity: activity) }

    before do
      allow(activity).to receive(:has_rubric?).and_return(true)
      allow(user_scores_for_grading_mock).to receive(:score_list).and_return([{ foo: 'bar' }])
      allow(user_scores_for_grading_mock).to receive(:comment_boxes).and_return([])
      allow(presenter_mock).to receive(:has_rubric?).and_return(true)
    end

    it 'creates the score data for the rubric grading app' do
      expect(UserScoresForGrading).to receive(:new).and_return(user_scores_for_grading_mock)
      do_request
    end

    it 'assigns user_scores_for_rubric_grading' do
      allow(UserScoresForGrading).to receive(:new).and_return(user_scores_for_grading_mock)
      do_request
      expect(assigns(:user_scores_json)).to eq([{ foo: 'bar' }].to_json)
    end

    it 'assigns comment_boxes' do
      allow(UserScoresForGrading).to receive(:new).and_return(user_scores_for_grading_mock)
      do_request
      expect(assigns(:comment_boxes)).to eq([])
    end
  end

  shared_examples 'an action that does not set up data for rubric grading' do
    let(:presenter_mock) { instance_double(StudentByStudentPresenter, activity: activity) }

    it 'does not create the score data for the rubric grading app' do
      allow(activity).to receive(:has_rubric?).and_return(false)
      allow(presenter_mock).to receive(:has_rubric?).and_return(false)
      allow(UserScoresForGrading).to receive(:new)
      expect(UserScoresForGrading).not_to have_received(:new)
      do_request
    end
  end

  describe 'helper methods' do
    describe '#smartbook_audio_playback_url' do
      let(:section) { create(:section) }

      before do
        allow(controller).to receive(:current_section).and_return(section)
      end

      it 'returns an empty string if lossless_auth_token is not set' do
        expect(controller.smartbook_audio_playback_url('abc')).to eq('')
      end

      context 'when lossless_auth_token is set' do
        let(:lossless_token) { 'new_token' }
        let(:result) { controller.smartbook_audio_playback_url(path) }

        before do
          controller.instance_variable_set(:@lossless_auth_token, lossless_token)
        end

        context 'when the original path is a lossless url' do
          let(:path) do
            [
              Rails.application.config.smartbook_recording_endpoint,
              'smartbook',
              'old_section_guid',
              'old_token',
              'recording_dir',
              'recording_file.m4a'
            ].join('/')
          end

          it 'prefixes the result with the lossless endpoint' do
            expect(result).to start_with(
              Rails.application.config.smartbook_recording_endpoint
            )
          end

          it 'replaces the old section guid in the original path with the ' \
             'current section guid' do
            expect(result.split('/')[4]).to eq(section.guid)
          end

          it 'replaces the original auth token with the current auth token' do
            expect(result.split('/')[5]).to eq('new_token')
          end

          it 'ends the result with the recording file path' do
            expect(result).to end_with('recording_dir/recording_file.m4a')
          end
        end

        context 'when the original path is an s3 bucket url' do
          let(:path) do
            [
              Smartbook::Response::SANTILLANA_BUCKET_PREFIX,
              'recording_dir',
              'recording_file.wav'
            ].join('/')
          end

          it 'returns the s3 bucket url' do
            expect(result).to eq(path)
          end
        end
      end
    end
  end

  describe '#edit' do
    def do_request(params = {})
      params[:return_to] ||= ''
      get :edit, params: {
        program_id: @program.id, score_id: score.id
      }.merge(params)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it 'assigns recording_server_url' do
      recording_configuration = double(
                                  RecordingConfiguration,
                                  server_host: 'http://server_host'
                                )
      allow(RecordingConfiguration)
        .to receive(:new)
        .and_return(recording_configuration)
      do_request
      expect(assigns(:recording_server_url)).to eq(recording_configuration.server_host)
    end

    it 'should set page title' do
      do_request
      expect(assigns(:page_title)).to eq('Review student work')
    end

    it 'should assign return_to' do
      do_request(return_to: '/gradebook/47')
      expect(assigns(:return_to)).to eq('/gradebook/47')
    end

    it 'assigns a presenter' do
      do_request
      expect(assigns(:presenter)).not_to be_nil
      expect(assigns(:presenter)).to be_a(ReviewWorkPresenter)
    end

    it 'assigns the activity from the presenter when available' do
      expect_any_instance_of(ReviewWorkPresenter).to receive(:activity)
        .at_least(:once).and_call_original

      do_request

      expect(assigns(:activity)).not_to be_nil
      expect(assigns(:activity)).to eq assigns(:presenter).activity
    end

    context 'with a rubric activity' do
      it_behaves_like 'an action that sets up data for rubric grading'
    end

    context 'with a non-rubric activity' do
      it_behaves_like 'an action that does not set up data for rubric grading'
    end

    context 'when a return_label param is specified' do
      it 'assigns the specified param to return_to_label' do
        do_request(return_label: 'the_devil_put_dinosaurs_here')
        expect(assigns(:return_to_label)).to eq('the_devil_put_dinosaurs_here')
      end
    end

    context 'when an activity_return label exists in the session' do
      it 'assigns the return label from the session to return_to_label' do
        session[:activity_return] = {}
        session[:activity_return]['label'] = 'stone'
        do_request
        expect(assigns(:return_to_label)).to eq('stone')
      end
    end

    context 'when no activity_return label exists in the session \
               and no return_label param is specified' do
      it 'assigns a default return_to_label value of "Return"' do
        do_request
        expect(assigns(:return_to_label)).to eq('Return')
      end
    end

    context 'when there are no results to review' do
      let!(:presenter) do
        ReviewWorkPresenter.new(
          @instructor,
          score,
          {current_student_attempt: attempt}
        )
      end

      before do
        allow(ReviewWorkPresenter).to receive(:new).and_return(presenter)
        allow(presenter.current_student_attempt)
          .to receive(:results)
          .and_return(nil)
      end

      it 'creates a Rollbar notification' do
        expect(VHLMonitor).to receive(:notify)
        do_request
      end

      it 'shows a flash message saying the results are unavailable' do
        do_request
        expect(flash[:error])
          .to match(/We're sorry. The results for this activity are unavailable./)
      end


      it 'redirects the user back to where they came from' do
        expect(controller).to receive(:redirect_to).with('return_to')
        do_request(return_to: 'return_to')
      end
    end

    context 'when there are results to review' do
      context 'when a reviewing work in a popup' do
        it 'renders with the wizard layout passing popup' do
          do_request(popup: '1')
          expect(response).to render_template(layout: 'wizard_layout')
        end
      end

      context 'when not reviewing work in a popup' do
        it 'renders with the wizard layout without passing popup' do
          do_request
          expect(response).to render_template(layout: 'wizard_layout')
        end
      end
    end
  end

  describe '#update' do
    def do_request(params = {})
      params[:return_to] ||= ''
      put :update, params: {
        program_id: @program.id, score_id: score.id
      }.merge(params)
    end

    let!(:submission){ double('InstructorGradingSubmission') }

    before do
      allow(controller).to receive(:update_feedback_notification_for_student)
      allow(submission).to receive(:has_not_sent_notifications?).and_return(false)
    end

    it_should_behave_like 'an action that requires a logged in instructor'
    it_should_behave_like 'an action that assigns program and course, sections, and students from focus'

    it 'assigns a presenter' do
      do_request
      expect(assigns(:presenter)).not_to be_nil
    end

    it 'assigns popup' do
      do_request
      expect(assigns(:popup)).to be_falsey
    end

    it 'creates and processes a grading submission' do
      expect(InstructorGradingSubmission).to receive(:new).and_return(submission)
      expect(submission).to receive(:process_submission)
      do_request
    end

    context 'when we are reviewing a single students work (in single student view)' do
      it 'redirects to the student details page for that student' do
        expect(controller)
          .to receive(:gradebook_student_details_path)
          .and_return('student_details_path')
        do_request(view_type: 'student')
        expect(response).to redirect_to('student_details_path')
      end
    end

    context 'when on the standard review work page (not viewing a single student)' do
      it 'redirects the user to the return to url' do
        do_request(return_to: 'return_to')
        expect(response).to redirect_to('return_to')
      end
    end
  end
end
