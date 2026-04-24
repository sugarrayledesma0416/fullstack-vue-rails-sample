describe PublishApiController, type: :request do
  let(:request_env) { {} }

  def basic_auth_headers
    auth_string = ActionController::HttpAuthentication::Basic.encode_credentials(
      'maestro', 'test'
    )
    { 'HTTP_AUTHORIZATION' => auth_string }
  end

  def do_request(url, params)
    post url, params: params, headers: basic_auth_headers
  end

  before do
    stub_const('HTTP_AUTHENTICATIONS', 'maestro' => 'test')
  end

  describe 'POST /publish/concepts/:id' do
    let(:program) { create(:program) }
    let(:unit) { create(:unit, program: program, toc_location: 123_456) }
    let(:lesson) { create(:lesson, unit: unit) }
    let(:media_item) { create(:media_item) }

    let(:concept_url) { '/publish/concepts/1' }

    let(:concept_params) do
      {
        'assessment' => '1',
        'background_color' => 'blue',
        'breadcrumb_string' => 'concept',
        'id' => '1',
        'lesson_id' => lesson.id.to_s,
        'lesson_rank' => lesson.rank.to_s,
        'media_item_id' => media_item.id.to_s,
        'name' => 'Concept 1',
        'program_id' => program.id.to_s,
        'rank' => '100',
        'unit_toc_location' => unit.toc_location.to_s
      }
    end

    it 'performs the process to publish a concept in CMS with expected params' do
      do_request(concept_url, concept_params)

      # Output for debugging validation failures.
      puts response.body unless response.ok?

      expect(response).to be_ok

      published_concept = Concept.find(1)

      expect(published_concept).to have_attributes(
        assessment: true,
        background_color: concept_params['background_color'],
        breadcrumb_string: concept_params['breadcrumb_string'],
        lesson_id: concept_params['lesson_id'].to_i,
        media_item_id: concept_params['media_item_id'].to_i,
        name: concept_params['name'],
        rank: concept_params['rank'].to_i
      )
    end

    it 'does not receive forbidden params when trying to process a publish' do
      other_params = concept_params.merge('invalid_key' => true)

      allow(ConceptPublishProcessor).to receive(:new).and_call_original

      do_request(concept_url, other_params)

      expect(ConceptPublishProcessor).to have_received(:new) do |args|
        expect(args).not_to have_key(:invalid_key)
        expect(args).not_to have_key('invalid_key')
      end
    end
  end

  describe 'POST /publish/programs/:program_id/after_publish_actions' do
    it 'schedules a worker for the specified program' do
      program_id = 100

      expect(LearningTracksExporterWorker).to receive(:perform_async).with(program_id.to_s)

      do_request("/publish/programs/#{program_id}/after_publish_actions", {})
    end
  end
end
