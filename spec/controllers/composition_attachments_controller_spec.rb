describe CompositionAttachmentsController do
  let(:user) { build_stubbed(:student) }
  let(:section) { build_stubbed(:section) }
  let(:persistent_session) { create(:persistent_session) }

  before do
    allow(controller).to receive(:current_section).and_return(section)
    allow(controller).to receive(:persistent_session).and_return(persistent_session)
    allow(controller).to receive(:current_section).and_return(section)
    allow(controller).to receive(:current_user).and_return(user)
  end

  describe '#create' do
    let(:uploaded_file) { fixture_file_upload('/media_items/test.jpg', 'image/jpg') }

    before do
      @attacher = CompositionAttacher.new(user, section, uploaded_file)
      allow(CompositionAttacher).to receive(:new).and_return(@attacher)
      allow(@attacher).to receive(:upload)
      allow(@attacher).to receive(:response).and_return({})
    end

    def do_request(params = {})
      post :create, params: { qqfile: uploaded_file }.merge(params)
    end

    RSpec::Matchers.define :upload_params_of do |posted_file|
      match do |actual_file|
        actual_file.instance_of?(ActionDispatch::Http::UploadedFile) &&
          actual_file.original_filename == posted_file.original_filename &&
          actual_file.content_type == posted_file.content_type
      end
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'initializes a new CompositionAttacher, specifying current user and uploaded file param' do
      expect(CompositionAttacher)
        .to receive(:new)
        .with(user, section, upload_params_of(uploaded_file), nil)
        .and_return(@attacher)
      do_request
    end

    it 'it passes optional previous_attachment_id param when initializing CompositionAttacher' do
      previous_attachment_id = 345
      expect(CompositionAttacher)
        .to receive(:new)
        .with(user, section, upload_params_of(uploaded_file), previous_attachment_id.to_s)
        .and_return(@attacher)
      do_request(previous_attachment_id: previous_attachment_id)
    end

    it 'tells the attacher to upload' do
      expect(@attacher).to receive(:upload)
      do_request
    end

    context 'when the user is using Internet Explorer versions below 10' do
      let(:navigator_user_agent) { 'Mozilla/4.0 (compatible; MSIE 8.0; Windows NT 5.1; Trident/4.0; .NET CLR 2.0.50727)' }

      it 'renders html containing the attacher response in JSON format and a document.domain set to vhlcentral.com' do
        attacher_response = { reason: 'good file' , success: true }
        allow(@attacher).to receive(:response).and_return(attacher_response)
        do_request(navigator_user_agent: navigator_user_agent)

        expect(response.body).to have_selector('pre') do |pre_tag|
          result = JSON.parse(pre_tag.text)
          expect(result['reason']).to eq('good file')
          expect(result['success']).to eq(true)
        end

        expect(response.body).to have_selector('script', text: /document.domain='vhlcentral.com'/)
      end

      it 'returns a content type of text/html' do
        do_request(navigator_user_agent: navigator_user_agent)
        expect(response.content_type).to eq('text/html; charset=utf-8')
      end
    end

    context 'when the user is using Internet Explorer versions 10 or higher' do
      let(:attacher_response) { { reason: 'good file' , success: true } }

      before do
        allow(@attacher).to receive(:response).and_return(attacher_response)
      end

      context 'when IE10' do
        it 'renders json containing the attacher response' do
          do_request(navigator_user_agent: 'Mozilla/5.0 (compatible; MSIE 10.0; Windows NT 6.2; Trident/6.0;)')
          result = JSON.parse(response.body)
          expect(result['reason']).to eq('good file')
          expect(result['success']).to eq(true)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end

      context 'when IE11' do
        it 'renders json containing the attacher response' do
          do_request(navigator_user_agent: 'Mozilla/5.0 (Windows NT 6.1; WOW64; Trident/7.0; SLCC2; .NET CLR 2.0.50727; .NET CLR 3.5.30729; .NET CLR 3.0.30729; Media Center PC 6.0; .NET4.0C; .NET4.0E; BRI/2; rv:11.0) like Gecko')
          result = JSON.parse(response.body)
          expect(result['reason']).to eq('good file')
          expect(result['success']).to eq(true)
          expect(response.content_type).to eq('application/json; charset=utf-8')
        end
      end
    end

    context 'when the user is not using Internet Explorer' do
      it 'renders json containing the attacher response' do
        attacher_response = { reason: 'good file' , success: true }
        allow(@attacher).to receive(:response).and_return(attacher_response)
        do_request(navigator_user_agent: 'Mozilla/5.0 (compatible; Firefox 20.0; Windows NT 6.2; Trident/6.0;)')

        result = JSON.parse(response.body)
        expect(result['reason']).to eq('good file')
        expect(result['success']).to eq(true)
        expect(response.content_type).to eq('application/json; charset=utf-8')
      end
    end
  end

  describe '#show' do
    let!(:composition_attachment) {  build_stubbed(:composition_attachment, user: user) }

    def do_request
      get :show, params: { section_id: 0, activity_id: 1, id: composition_attachment.id }
    end

    it_behaves_like 'an action that requires a logged in user'

    before do
      allow(File).to receive(:exist?).and_return(true)
      allow(CompositionAttachment).to receive(:find).and_return(composition_attachment)
    end

    it 'redirects to 401 error when the user cannot download a file' do
      allow(composition_attachment).to receive(:user_id).and_return(user.id + 1)
      do_request
      expect(response.body).to include('Download Denied.')
      expect(response.code).to eq('401')
    end

    it 'redirects to 404 if file does not exist'do
      allow(composition_attachment).to receive(:has_file_name?).and_return(false)
      do_request
      expect(response).to redirect_to '/404'
    end

    it 'delivers a file when file belongs to user' do
      expected_url = 'remote_url'
      allow(composition_attachment).to receive(:signed_url).and_return(expected_url)
      do_request
      expect(response).to redirect_to expected_url
    end
  end

  describe '#destroy' do
    let(:composition_attachment) { build_stubbed(:composition_attachment, user_id: user.id) }

    before do
      allow(CompositionAttachment).to receive(:find).and_return(composition_attachment)
      allow(composition_attachment).to receive(:destroy_by_user).and_return(true)
    end

    def do_request(params = {})
      delete :destroy, params: { id: composition_attachment.id }.merge(params)
    end

    it_behaves_like 'an action that requires a logged in user'

    it 'finds the composition attachment specified by the id param' do
      expect(CompositionAttachment).to receive(:find).with(composition_attachment.id.to_s).and_return(composition_attachment)
      do_request
    end

    context 'when the current user is the owner of the composition attachment' do
      it 'deletes the composition attachment' do
        expect(composition_attachment).to receive(:destroy_by_user).with(user).and_return(true)
        do_request
      end

      it 'renders a success status of true' do
        do_request
        expect(JSON.parse(response.body)['success']).to be_truthy
      end

      it 'returns a content type of text/plain' do
        do_request
        expect(response.content_type).to eq('text/plain; charset=utf-8')
      end
    end

    context 'when the current user is not owner of the composition attachment' do
      before do
        allow(composition_attachment).to receive(:destroy_by_user).and_return(false)
      end

      it 'renders with a status code of 401 non-authorized' do
        do_request
        expect(response.status).to eq(401)
      end

      it 'renders an success status of false and an error message' do
        do_request
        expect(JSON.parse(response.body)['success']).to be_falsey
        expect(JSON.parse(response.body)['reason']).to eq('You cannot remove this file because it was uploaded by someone else.')
      end

      it 'returns a content type of text/plain' do
        do_request
        expect(response.content_type).to eq('text/plain; charset=utf-8')
      end
    end
  end

  describe '#file_types' do
    let!(:allowed_file_type) { create(:allowed_file_type) }
    let(:section) { build_stubbed(:section) }

    def do_request(params = {})
      get :file_types
    end

    it 'assigns a list of allowed file types' do
      allow(FileType).to receive(:allowed).and_return([allowed_file_type])
      do_request
      expect(assigns(:allowed_file_types)).to eq([allowed_file_type])
    end
  end
end