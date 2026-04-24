describe Ua::SectionsController do
  let(:basic_auth_klass) { ActionController::HttpAuthentication::Basic }
  let(:auth_headers) { basic_auth_headers(valid_username, valid_password) }
  let(:valid_username) { 'maestro' }
  let(:valid_password) { 'test' }
  let(:assistant) { create(:instructor) }
  let(:assistant_role) { SectionInstructor::ASSISTANT_ROLE }
  let(:coinstructor) { create(:instructor) }
  let(:coinstructor_role) { SectionInstructor::COINSTRUCTOR_ROLE }

  def basic_auth_headers(username, password)
    credentials = basic_auth_klass.encode_credentials(username, password)
    { 'HTTP_AUTHORIZATION' => credentials }
  end

  def parse_response(response, element)
    JSON.parse(response.body).symbolize_keys[element]
  end

  before do
    stub_const('HTTP_AUTHENTICATIONS', valid_username => valid_password)
  end

  shared_examples 'requires valid basic auth credentials' do
    context 'with invalid basic auth credentials,' do
      let(:auth_headers) { basic_auth_headers('bad_username', 'bad_password') }

      it 'returns a 401 error' do
        do_request

        expect(response).to be_unauthorized
        expect(response.body.chomp).to eq('HTTP Basic: Access denied.')
      end
    end
  end

  shared_examples 'requires a valid section guid' do
    context 'when an m3 section with the specified guid does not exist,' do
      let(:section) { build(:section, guid: SecureRandom.uuid) }

      it 'raises a 404 error' do
        do_request

        expect(response).to be_not_found
        expect(parse_response(response, :message)).to eq(
          "Section with guid #{section.guid} not found"
        )
      end
    end
  end

  describe 'PUT /update' do
    let(:section) { create(:section) }
    let(:target_path) { ua_section_path(guid: section.guid) }
    let(:default_params) do
      {
        section_instructors_attributes: [
          { role: coinstructor_role, user_guid: coinstructor.guid },
          { role: assistant_role, user_guid: assistant.guid }
        ]
      }
    end

    def do_request(extra_params = {})
      put(
        target_path,
        params: default_params.merge(extra_params),
        headers: auth_headers
      )
    end

    include_examples 'requires valid basic auth credentials'
    include_examples 'requires a valid section guid'

    context 'when an m3 section with the specified id exists,' do
      it 'creates section instructor records with instructors specified ' \
         'by the user_guid attributes' do
        do_request

        expect(response).to be_ok

        results = section.section_instructors.reload.map do |record|
          record.attributes.symbolize_keys.slice(:role, :user_id)
        end

        expect(results).to contain_exactly(
          { role: 'Instructor', user_id: section.instructor_id },
          { role: coinstructor_role, user_id: coinstructor.id },
          { role: assistant_role, user_id: assistant.id }
        )
      end
    end
  end

  describe 'POST /add_section_instructor' do
    let!(:section) { create(:section) }
    let(:default_params) { {} }

    def target_path
      add_section_instructor_ua_section_path(guid: section.guid)
    end

    def do_request(params = {})
      post target_path, params: params, headers: auth_headers
    end

    include_examples 'requires valid basic auth credentials'
    include_examples 'requires a valid section guid'

    context 'when an m3 section with the specified id exists,' do
      it 'creates section instructor records with the specified params' do
        expect do
          do_request(
            section_instructors: [
              { role: coinstructor_role, user_guid: coinstructor.guid },
              { role: assistant_role, user_guid: assistant.guid }
            ]
          )
        end.to change(SectionInstructor, :count).by(2)

        expect(response).to be_ok

        expect(section.reload.section_instructors).to include(
          an_object_having_attributes(
            user_id: coinstructor.id,
            role: coinstructor_role
          ),
          an_object_having_attributes(
            user_id: assistant.id,
            role: assistant_role
          )
        )
      end

      it 'does not add section instructors that already exist' do
        create(
          :section_co_instructor,
          section: section,
          instructor: coinstructor
        )

        expect do
          do_request(
            section_instructors: [
              { role: coinstructor_role, user_guid: coinstructor.guid },
              { role: assistant_role, user_guid: assistant.guid }
            ]
          )
        end.to change(SectionInstructor, :count).by(1)

        expect(response).to be_ok

        expect(section.reload.section_instructors).to include(
          an_object_having_attributes(
            user_id: assistant.id,
            role: assistant_role
          )
        )
      end

      it 'returns an error when a section instructor already exists with a ' \
         'different role' do
        create(
          :section_co_instructor,
          section: section,
          instructor: coinstructor
        )

        expect do
          do_request(
            section_instructors: [
              { role: assistant_role, user_guid: assistant.guid },
              { role: assistant_role, user_guid: coinstructor.guid }
            ]
          )
        end.not_to change(SectionInstructor, :count)

        expect(response).to have_http_status(:unprocessable_entity)
        expect(parse_response(response, :errors)).to match_array(
          "Failed to create section instructor (section_guid #{section.guid}, " \
          "user_guid #{coinstructor.guid}, role #{assistant_role}): " \
          'User has already been used'
        )
      end
    end
  end

  describe 'POST /remove_section_instructor' do
    let(:section) { create(:section) }
    let(:default_params) { {} }

    def target_path
      remove_section_instructor_ua_section_path(guid: section.guid)
    end

    def do_request(params = {})
      post target_path, params: params, headers: auth_headers
    end

    include_examples 'requires valid basic auth credentials'
    include_examples 'requires a valid section guid'

    context 'when an m3 section with the specified id exists,' do
      it 'remove section instructor records with instructors specified ' \
         'by the user_guid attributes' do
        section_instructor_1 = create(
          :section_co_instructor,
          section: section,
          instructor: coinstructor
        )
        section_instructor_2 = create(
          :section_assistant,
          section: section,
          instructor: assistant
        )

        expect do
          do_request(
            section_instructors: [
              { role: coinstructor_role, user_guid: coinstructor.guid },
              { role: assistant_role, user_guid: assistant.guid }
            ]
          )
        end.to change(SectionInstructor, :count).by(-2)

        expect(response).to be_ok

        expect(SectionInstructor.exists?(section_instructor_1.id)).to be_falsey
        expect(SectionInstructor.exists?(section_instructor_2.id)).to be_falsey
      end

      it 'does not report error when specifying a non-existent section instructor' do
        section_instructor = create(
          :section_co_instructor,
          section: section,
          instructor: coinstructor
        )

        expect do
          do_request(
            section_instructors: [
              { user_guid: coinstructor.guid },
              { user_guid: SecureRandom.uuid }
            ]
          )
        end.to change(SectionInstructor, :count).by(-1)

        expect(response).to be_ok
        expect(SectionInstructor.exists?(section_instructor.id)).to be_falsey
      end
    end
  end
end
