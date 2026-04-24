describe OneRoster::Api::SchoolsController do

  describe 'PUT /update' do
    let(:school) do
      create(
        :one_roster_school,
        name: 'South Middle School',
        salesforce_id: SecureRandom.uuid
      )
    end

    let(:program) { create(:program_with_lessons) }
    let(:instructor) { create(:instructor) }
    let(:course_external_id) { SecureRandom.uuid }
    let(:class_external_id) { SecureRandom.uuid }
    let(:course) do
      create(:course,
             name: 'Spanish 1',
             school: school,
             program: program,
             owner: instructor,
             start_date: 2.days.ago,
             end_date: 2.months.from_now)
    end
    let!(:section) { create(:section, instructor: instructor, name: 'Section 1', course: course) }
    let!(:linked_section) { create(:one_roster_linked_section, course_external_id: course_external_id, class_external_id: class_external_id, section: section, school: school) }
    let(:new_section_name) { 'AP Spanish Section 1' }
    let(:new_course_name) { 'AP Spanish Section' }

    let(:roster_assistant_data) do
      [
        {
          'course_title' => new_course_name,
          'sourced_id' => class_external_id,
          'title' => new_section_name,
          'school_salesforce_id' => school.salesforce_id
        }
      ]
    end

    let(:roster_assistant_client) do
      instance_double(OneRoster::Client, classes_for_course: roster_assistant_data,
                      last_request_successful?: true)
    end

    let(:target_path) { one_roster_api_school_path(school.salesforce_id) }
    let(:missing_param_target_path) { one_roster_api_school_path }
    let(:bad_school_target_path) { one_roster_api_school_path('unknown_school') }

    def do_request(target_path)
      default_params = { format: :json }
      put(target_path, headers: http_login)
    end

    def do_bad_request
      default_params = { format: :json }
      put(target_path, headers: http_bad_creds_login)
    end

    def http_login
      user = HTTP_AUTHENTICATIONS.keys.first
      password = HTTP_AUTHENTICATIONS[user]
      {
        HTTP_AUTHORIZATION: ActionController::HttpAuthentication::Basic.encode_credentials(user, password)
      }
    end

    def http_bad_creds_login
      user = HTTP_AUTHENTICATIONS.keys.first
      {
          HTTP_AUTHORIZATION: ActionController::HttpAuthentication::Basic.encode_credentials(user, 'test')
      }
    end

    before do
      stub_const('HTTP_AUTHENTICATIONS', { 'maestro' => 'secret' })
      allow(OneRoster::Client).to receive(:new).and_return(roster_assistant_client)
      stub_request(:post, %r{.*/m3/one_roster_enrollments.json*}).to_return(status: 200,
                                                                       body:  "",
                                                                       headers: { 'Content-Type' => 'application/json' })
    end

    around do |example|
      Sidekiq::Testing.inline! do
        example.run
      end
    end

    describe 'when the request has invalid credentials' do
      it 'returns unauthorized status' do
        do_bad_request
        expect(response).not_to be_ok
      end
    end

    describe 'when the request contains the expected params' do
      it 'returns OK status' do
        do_request(target_path)
        expect(section.reload.name).to eql new_section_name
        expect(course.reload.name).to eql new_course_name
        expect(response).to be_ok
      end
    end

    context 'when there is something wrong with the request parameters' do
      describe 'when the request is missing the salesforce id' do
        it 'raises error invalid path' do
          expect{ do_request(missing_param_target_path) }.to raise_error(ActionController::UrlGenerationError)
        end
      end

      describe 'when no school is found with the specified salesforce id' do
        it 'returns server error status' do
          do_request(bad_school_target_path)
          json = JSON.parse(response.body, symbolize_names: true)
          expect(json).to eq(error: 'School not found for salesforce_id: unknown_school')
          expect(response).not_to be_ok
          expect(response).to have_http_status(:unprocessable_entity)
        end
      end
    end
  end
end
