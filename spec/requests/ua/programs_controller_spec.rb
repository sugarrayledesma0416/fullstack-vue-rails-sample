describe Ua::ProgramsController do
  describe 'PUT /update' do
    let(:valid_username) { 'maestro' }
    let(:valid_password) { 'test' }
    let(:basic_auth_klass) { ActionController::HttpAuthentication::Basic }
    let(:valid_auth_headers) { auth_headers(valid_username, valid_password) }

    # program_id and program_params are overridden in update context, but
    # the values defined here are used for testing code shared across contexts.
    let(:program_id) { build_stubbed(:program).id }
    let(:program_params) { original_attrs }

    let(:target_path) { ua_program_path(id: program_id) }

    let(:original_attrs) do
      {
        title: 'original title',
        image_filename: 'original_filename.png',
        prefix_abbreviation: 'original_abbreviation',
        unit_label: 'OriginalUnit',
        lesson_label: 'OriginalLesson',
        language_code: 'es',
        maestro_version: 3
      }
    end

    def auth_headers(username, password)
      credentials = basic_auth_klass.encode_credentials(username, password)
      { 'HTTP_AUTHORIZATION' => credentials }
    end

    def do_request
      put(
        target_path,
        params: program_params.merge(format: :json),
        headers: valid_auth_headers
      )
    end

    before do
      stub_const('HTTP_AUTHENTICATIONS', valid_username => valid_password)
    end

    it 'requires valid basic auth credentials' do
      invalid_auth_headers = auth_headers('bad_username', 'bad_password')

      put(
        target_path,
        params: program_params.merge(format: :json),
        headers: invalid_auth_headers
      )

      expect(response).to be_unauthorized
      expect(response.body.chomp).to eq('HTTP Basic: Access denied.')
    end

    context 'when an m3 program with the specified id does not exist,' do
      it 'creates a new program record' do
        do_request

        expect(response).to be_ok

        program = Program.find(program_id)

        expect(response.body).to eq(program.to_json)

        expect(program).to have_attributes(original_attrs)
      end
    end

    context 'when an m3 program with the specified id exists,' do
      let(:program) { create(:program, original_attrs) }
      let(:program_id) { program.id }
      let(:program_params) { new_attrs }

      let(:new_attrs) do
        {
          image_filename: 'new_filename.png',
          language_code: 'fr',
          lesson_label: 'NewLesson',
          maestro_version: 3,
          prefix_abbreviation: 'new_abbreviation',
          title: 'new title',
          unit_label: 'NewUnit',
          family: 'vista_online_learning'
        }
      end

      it 'updates the program record with the specified params' do
        do_request

        expect(response).to be_ok

        program.reload
        expect(program).to have_attributes(new_attrs)
      end
    end
  end
end
