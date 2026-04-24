describe Instructor::InstructorResourceSettingsController do
  let(:instructor) { create(:instructor) }
  let(:program) { create(:program) }

  before do
    fake_login(instructor)
  end

  describe '#create' do
    before do
      @resource = create(:resource, program_id: program.id)
      @instructor_resource_setting = create(
        :instructor_resource_setting,
        resource_id: @resource.id,
        user_id: instructor.id
      )
      @valid_params = {
        resource_id: @resource.id.to_s,
        user_id: instructor.id.to_s
      }
      allow(InstructorResourceSetting).to receive(:new)
        .and_return(@instructor_resource_setting)
    end

    def do_ajax_request
      post :create, params: @valid_params, xhr: true
    end

    context 'with valid params,' do
      before do
        allow(@instructor_resource_setting).to receive(:save).and_return(true)
      end

      it 'renders the create.js template' do
        do_ajax_request
        expect(response).to render_template('create')
      end

      it 'should create a new resource setting' do
        do_ajax_request
      end
    end

    context 'when invalid params' do
      before do
        allow(@instructor_resource_setting).to receive(:save).and_return(false)
      end

      it 'should display an error' do
        do_ajax_request
        expect(response.body).to include 'Could not create setting for this resource'
        expect(response.status).to eq(500)
      end
    end
  end

  describe '#update_many' do
    before do
      @resource = create(:resource, program_id: program.id, vhl_student_resource: false)
      @resource_2 = create(:resource, program_id: program.id, vhl_student_resource: false)
      @protected_resource = create(:resource, program_id: program.id, protected: true)
      allow(controller).to receive(:get_friendly_resource_setting_label_from_status)
        .and_return('hidden')
      @instructor_resource_setting = build_stubbed(
        :instructor_resource_setting,
        resource_id: @resource.id,
        user_id: instructor.id
      )
    end

    def do_ajax_request
      post :update_many, params: @params, xhr: true
    end

    context 'with valid params,' do
      before do
        @params = {
          'selected_resources' => [@resource.id.to_s, @resource_2.id.to_s].join(','),
          'user_id' => instructor.id.to_s
        }
      end

      it 'returns success' do
        do_ajax_request
        expect(response).to have_http_status(:success)
      end
    end

    context 'when there are resources that are not updated' do
      before do
        @params = {
          selected_resources: [@resource.id.to_s, @resource_2.id.to_s].join(','),
          user_id: instructor.id.to_s
        }
        allow_any_instance_of(Resource).to receive(:update).and_return(false)
      end

      it 'returns internal_server_error' do
        do_ajax_request
        expect(response).to have_http_status(:internal_server_error)
      end
    end

    context 'when there are protected resources selected' do
      before do
        @params = {
          'selected_resources' => [@resource.id.to_s, @protected_resource.id.to_s].join(','),
          'user_id' => instructor.id.to_s
        }
        @protected_resource_setting = build_stubbed(
          :instructor_resource_setting,
          resource_id: @protected_resource.id,
          user_id: instructor.id
        )
        allow(@instructor_resource_setting).to receive(:update)
        allow(@protected_resource_setting).to receive(:update)
      end

      it 'returns unprocessable_entity' do
        do_ajax_request
        expect(response).to have_http_status(:unprocessable_entity)
      end

      it 'does not update instructor settings for those resources' do
        allow(Resource).to receive(:where).and_return([@resource, @protected_resource])
        allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).with(
          instructor.id, @resource.id
        ).and_return(@instructor_resource_setting)
        allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id).with(
          instructor.id, @protected_resource.id
        ).and_return(@protected_resource_setting)

        do_ajax_request

        expect(@instructor_resource_setting).to have_received(:update)
        expect(@protected_resource_setting).not_to have_received(:update)

        result = JSON.parse(response.body)
        expect(result['successful_resources']).not_to include(@protected_resource.id)
      end
    end

    context 'when user has resource editor role' do
      before do
        @params = {
          selected_resources: [@resource.id.to_s, @resource_2.id.to_s].join(','),
          user_id: instructor.id.to_s,
          instructor_setting_status: 'shown'
        }
        instructor.roles << Role.new(name: Role::RESOURCE_EDITOR)
        allow(InstructorResourceSetting).to receive(:find_by_user_id_and_resource_id)
      end

      it 'does not update the instructor settings' do
        do_ajax_request

        expect(InstructorResourceSetting).not_to have_received(:find_by_user_id_and_resource_id)
      end

      it 'updates visibility properly' do
        do_ajax_request

        result = JSON.parse(response.body)
        expect(result['successful_resources']).to match_array([@resource.id, @resource_2.id])
        expect(@resource.reload.vhl_student_resource).to be_truthy
        expect(@resource_2.reload.vhl_student_resource).to be_truthy
      end
    end
  end
end
