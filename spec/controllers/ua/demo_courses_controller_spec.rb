describe Ua::DemoCoursesController do
  describe '#create' do
    let (:demo_course_creator) { DemoCourseBuild::Creator.new({}) }
    let (:program) { build_stubbed(:program) }

    before do
      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)

      # Mock DemoCourseCreator
      allow(demo_course_creator).to receive(:create_course)
      allow(demo_course_creator).to receive(:message).and_return('success')
      allow(demo_course_creator).to receive(:status).and_return(:ok)
      allow(DemoCourseBuild::Creator).to receive(:new).and_return(demo_course_creator)
    end

    def do_request
      post :create, params: { program_id: program.id }, xhr: true
    end

    it_should_behave_like 'an active resource controller action that rescues and reports errors'

    context 'with a valid course creator' do
      before do
        allow(demo_course_creator).to receive(:valid?).and_return(true)
      end

      it 'initializes a new DemoCourseBuild::Creator, passing in request params, and calls create_course on it via a delayed job' do
        expect(DemoCourseCreatorWorker).to receive(:perform_async)
        do_request
      end
    end

    context 'with an invalid course creator' do
      before do
        allow(demo_course_creator).to receive(:valid?).and_return(false)
      end

      it "doesn't call the delayed job" do
        expect(DemoCourseCreatorWorker).not_to receive(:perform_async)
        do_request
      end
    end

    it 'renders the message of the demo course creator in json format' do
      allow(demo_course_creator).to receive(:message).and_return('message_text')
      do_request
      expect(response.body).to eq('message_text')
    end

    it 'sets a request status equal to the status returned by the demo course creator' do
      allow(demo_course_creator).to receive(:status).and_return(:unprocessable_entity)
      do_request
      expect(response.status).to eq(422)
    end
  end
end
