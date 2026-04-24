# encoding: utf-8

describe PublishApiController do
  describe '#concept' do
    let!(:concept_params) do
      { 'id' => '1',
        'unit_toc_location' => '10',
        'program_id' => '1',
        'unit_rank' => '1',
        'lesson_rank' => '1',
        'name' => 'Concept 1',
        'rank' => '100',
        'singular_label' => 'quiz',
        'background_color' => 'blue',
        'breadcrumb_string' => 'concept',
        'assessment' => '1' }
    end
    let!(:publish_processor) { ConceptPublishProcessor.new(concept_params) }

    before do
      allow(ConceptPublishProcessor).to receive(:new).and_return(publish_processor)
      allow(publish_processor).to receive(:process_request).and_return(publish_processor)

      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request
      post :concept, params: concept_params, xhr: true
    end

    it 'instanciates a new ConceptPublishProcessor object' do
      expect(ConceptPublishProcessor).to receive(:new)
      do_request
    end

    it 'processes the request' do
      expect(publish_processor).to receive(:process_request).and_return(publish_processor)
      do_request
    end

    it 'renders the message of the concept processor in json format' do
      allow(publish_processor).to receive(:message).and_return('message_text')
      do_request
      expect(response.body).to eql 'message_text'.to_json
    end

    it 'sets a request status equal to the status returned by the concept processor' do
      allow(publish_processor).to receive(:status).and_return(:unprocessable_entity)
      do_request
      expect(response.status).to eql 422
    end
  end

  describe '#media_item' do
    let(:media_item_params) do
      { 'id' => '1',
        'filename' => 'some_file' }
    end
    let!(:publish_processor) { double('MediaItemPublishProcessor', status: 200, message: 'success') }

    before do
      allow(MediaItemPublishProcessor).to receive(:new).and_return(publish_processor)
      allow(publish_processor).to receive(:process_request).and_return(publish_processor)

      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request
      post :media_item, params: media_item_params, xhr: true
    end

    it 'instantiates a new MediaItemPublishProcessor object' do
      expect(MediaItemPublishProcessor).to receive(:new).with(hash_including('id' => '1', 'filename' => 'some_file'))
      do_request
    end

    it 'processes the request' do
      expect(publish_processor).to receive(:process_request).and_return(publish_processor)
      do_request
    end
  end

  describe '#unit' do
    let(:unit_params) do
      { 'program_id' => '48',
        'rank' => '1',
        'toc_location' => '1500',
        'name' => 'Unidad 1: Los viajes del viento',
        'label' => 'Unidad 1',
        'media_item_id' => '150620',
        'released' => '1' }
    end

    let(:publish_processor) { double(UnitPublishProcessor, status: 200, message: 'success') }

    def do_request
      post :unit, params: unit_params, xhr: true
    end

    before do
      allow(UnitPublishProcessor).to receive(:new).and_return(publish_processor)
      allow(publish_processor).to receive(:process_request).and_return(publish_processor)

      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    it 'instantiates a new MediaItemPublishProcessor object' do
      expect(UnitPublishProcessor).to receive(:new).with(hash_including('program_id' => '48',
                                                                        'rank' => '1',
                                                                        'toc_location' => '1500',
                                                                        'name' => 'Unidad 1: Los viajes del viento',
                                                                        'label' => 'Unidad 1',
                                                                        'media_item_id' => '150620',
                                                                        'released' => '1')).and_return(publish_processor)
      do_request
    end

    it 'processes the request' do
      expect(publish_processor).to receive(:process_request).and_return(publish_processor)
      do_request
    end
  end

  describe '#lesson' do
    let(:lesson_params) { {  'unit_toc_location' => 1, 'rank' => 1, 'name' => 'Lesson 1', 'toc_entries_xml' => 'some_file' } }
    let!(:publish_processor) { double('LessonPublishProcessor', status: 200, message: 'success') }

    before do
      allow(LessonPublishProcessor).to receive(:new).and_return(publish_processor)
      allow(publish_processor).to receive(:process_request).and_return(publish_processor)

      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request
      post :lesson, params: lesson_params, xhr: true
    end

    it 'instantiates a new LessonPublishProcessor object' do
      expect(LessonPublishProcessor).to receive(:new).with(hash_including('unit_toc_location' => '1',
                                                                          'rank' => '1',
                                                                          'name' => 'Lesson 1',
                                                                          'toc_entries_xml' => 'some_file'))
      do_request
    end

    it 'processes the request' do
      expect(publish_processor).to receive(:process_request).and_return(publish_processor)
      do_request
    end
  end

  describe '#activity' do
    let(:activity_params) do
      {
        'cms_activity_id' => '1',
        'cms_revision_id' => '1',
        'component_name' => 'Workbook',
        'concept_id' => '1',
        'concept_rank' => '100',
        'icon' => 'textbook',
        'lesson_id' => '1',
        'license_group_id' => '1',
        'page' => '2-5',
        'perform' => 'add',
        'points_possible' => '30',
        'title' => 'Activity 1',
        'toc_location' => '123',
        'toc_location_rank' => '10'
      }
    end

    let!(:publish_processor) do
      double('ActivityPublishProcessor', status: 200, message: 'success')
    end

    before do
      allow(ActivityPublishProcessor).to receive(:new).and_return(publish_processor)
      allow(publish_processor).to receive(:process_request).and_return(publish_processor)

      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request(params = {})
      post :activity, params: params.merge(activity_params), xhr: true
    end

    it 'instantiates a new ActivityPublishProcessor object' do
      expect(ActivityPublishProcessor).to receive(:new).with(hash_including(activity_params))
      do_request
    end

    it 'processes the request' do
      expect(publish_processor).to receive(:process_request).and_return(publish_processor)
      do_request
    end
  end

  describe '#unlisted_activity' do
    let(:unlisted_activity_params) do
      {
        'cms_activity_id' => '1',
        'cms_revision_id' => '1',
        'component_name' => 'Workbook',
        'concept_id' => '1',
        'concept_rank' => '100',
        'icon' => 'textbook',
        'lesson_id' => '1',
        'license_group_id' => '1',
        'page' => '2-5',
        'perform' => 'add',
        'points_possible' => '30',
        'title' => 'Activity 1'
      }
    end

    let!(:publish_processor) do
      double('UnlistedActivityPublishProcessor', status: 200, message: 'success')
    end

    before do
      allow(UnlistedActivityPublishProcessor).to receive(:new).and_return(publish_processor)
      allow(publish_processor).to receive(:process_request).and_return(publish_processor)
      allow(publish_processor).to receive(:message).and_return('')
      allow(publish_processor).to receive(:status).and_return('')

      basic_auth_user = 'iron_keep_b6eef'
      password = 'test'
      HTTP_AUTHENTICATIONS[basic_auth_user] = password
      request.env['HTTP_AUTHORIZATION'] =
        ActionController::HttpAuthentication::Basic.encode_credentials(basic_auth_user, password)
    end

    def do_request(params = {})
      post :unlisted_activity, params: params.merge(unlisted_activity_params), xhr: true
    end

    it 'instantiates a new UnlistedActivityPublishProcessor object' do
      expect(UnlistedActivityPublishProcessor).to receive(:new).with(hash_including(unlisted_activity_params))
      do_request
    end

    it 'processes the request' do
      expect(publish_processor).to receive(:process_request).and_return(publish_processor)
      do_request
    end
  end
end
