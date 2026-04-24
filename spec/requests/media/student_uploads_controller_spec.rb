require 'requests/login_helper_methods'
require 'requests/shared_require_user_examples'

describe Media::StudentUploadsController do
  let(:user) { create(:user) }
  let(:upload_results) do
    { 'success' => true }
  end
  let(:uploader) do
    instance_double(SoloVideoRecordingUploader,
                    upload: upload_results,
                    delete_video: false)
  end

  before do
    allow(SoloVideoRecordingUploader).to receive(:new).and_return(uploader)
  end

  describe 'POST /create_svr_video' do
    def do_request(params = {})
      post(media_student_uploads_create_svr_video_path, params: params)
    end

    include_examples 'require logged in user'

    describe 'as a logged in user' do
      before do
        log_in_user(user)
      end

      it 'uploads a video using the uploader' do
        expected_params = { uuid: SecureRandom.uuid }
        do_request(expected_params)
        expect(uploader).to have_received(:upload).with(hash_including(expected_params))
      end

      it 'returns the results from the uploader as JSON' do
        do_request
        expect(JSON.parse(response.body)).to eq upload_results
      end
    end
  end

  describe 'POST /delete_svr_video' do
    def do_request(params = {})
      post(media_student_uploads_delete_svr_video_path, params: params)
    end

    include_examples 'require logged in user'

    describe 'as a logged in user' do
      before do
        log_in_user(user)
      end

      it 'deletes a video using the uploader' do
        expected_params = { uuid: SecureRandom.uuid, delete_file_path: 'some/path' }
        do_request(expected_params)
        expect(uploader).to have_received(:delete_video).with(expected_params[:uuid],
                                                              expected_params[:delete_file_path])
      end

      it 'returns the results from the deletion as JSON' do
        do_request
        expect(JSON.parse(response.body)).to eq('success' => false)
      end
    end
  end
end
