require 'requests/shared_require_user_examples'

describe Media::InstructorUploadsController do
  let(:instructor) { create(:instructor) }
  let(:persistent_session) { create(:persistent_session) }
  let(:params) { { 'abc' => '123' } }
  let(:uploader) { instance_double(UploadFileDocUploader) }
  let(:result) { { woo: :hoo } }

  before do
    allow(controller).to receive(:persistent_session).and_return(persistent_session)
    allow(controller).to receive(:current_user).and_return(instructor)
    allow(UploadFileDocUploader).to receive(:new).and_return(uploader)
    allow(uploader).to receive(:delete_file).and_return(result)
  end

  describe '#create_file' do
    before do
      allow(uploader).to receive(:upload).and_return(result)
    end

    def do_request(other_params = {})
      post :create_file, params: params.merge(other_params)
    end

    it 'initializes a new UploadFileDocUploader' do
      expect(UploadFileDocUploader).to receive(:new).and_return(uploader)
      do_request
    end

    it 'calls upload on UploadFileDocUploader instance' do
      expect(uploader).to receive(:upload)
      do_request
    end

    it 'renders text containing the result of the UploadFileDocUploader as json' do
      do_request
      expect(response.body).to eq(result.to_json)
    end
  end

  describe '#delete_file' do
    before do
      allow(uploader).to receive(:delete_file).and_return(result)
    end

    def do_request(other_params = {})
      post :delete_uploaded_file, params: params.merge(other_params)
    end

    it 'initializes a new UploadFileDocUploader' do
      expect(UploadFileDocUploader).to receive(:new).and_return(uploader)
      do_request
    end

    it 'calls delete_file on UploadFileDocUploader instance' do
      expect(uploader).to receive(:delete_file)
      do_request
    end

    it 'renders text containing the result of the UploadFileDocUploader as json' do
      do_request
      expect(response.body).to eq({ success: result }.to_json)
    end
  end
end
