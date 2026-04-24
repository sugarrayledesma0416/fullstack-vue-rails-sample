describe OneRoster::Client do
  let(:instructor) { build(:instructor) }
  let(:school_salesforce_id) { SecureRandom.uuid }
  let(:client) do
    described_class.new(instructor.username)
  end

  before do
    allow(VHLMonitor).to receive(:warning)
  end

  describe '#courses_for_school' do
    let(:expected_course) do
      {
        sourced_id: 1,
        title: 'Course title 1',
        classes: [
                   {
                     sourced_id: 'a',
                     title: 'class title A',
                     school_salesforce_id: school_salesforce_id,
                     academic_sessions: academic_sessions
                   },
                   {
                     sourced_id: 'b',
                     title: 'class title B',
                     school_salesforce_id: school_salesforce_id,
                     academic_sessions: []
                   }
                 ]
      }
    end
    let(:expected_response) do
      { courses: [ expected_course ] }
    end
    let(:instructor_courses_endpoint_url) { "#{RA_URL}/one_roster_api/courses" }
    let(:instructor_courses_request_endpoint) do
      "#{instructor_courses_endpoint_url}?school_salesforce_id=#{school_salesforce_id}&username=#{instructor.username}"
    end
    let(:academic_session_start_date) { 1.day.from_now.strftime('%Y-%m-%d') }
    let(:academic_session_end_date) { 70.days.from_now.strftime('%Y-%m-%d') }
    let(:academic_session_school_year) { Time.zone.now.strftime('%Y') }
    let(:academic_sessions) do
      [
        {
          start_date: academic_session_start_date,
          end_date: academic_session_end_date,
          school_year: academic_session_school_year
        }
      ]
    end

    before do
      stub_request(
        :get,
        %r{#{instructor_courses_endpoint_url}?.*}
      ).to_return(
        status: 200,
        body: expected_response.to_json,
        headers: { 'Content-Type' => 'application/json' }
      )
    end

    context 'when validating' do
      it 'raises an error if no username is given' do
        client = described_class.new
        expected_error = 'username is required'
        expect { client.courses_for_school(school_salesforce_id) }.to raise_error expected_error
      end
    end

    context 'when Roster Assistant request was successful' do
      it 'returns courses from Roster Assistant' do
        expect(client.courses_for_school(school_salesforce_id)).to match_array([JSON.parse(expected_course.to_json)])
      end

      it 'does not warn the VHLMonitor' do
        client.courses_for_school(school_salesforce_id)
        expect(VHLMonitor).not_to have_received(:warning)
      end
    end

    context 'when Roster Assitant request failed' do
      let(:errors_array) { ['something went wrong'] }
      let(:error_hash) do
        { 'errors' => errors_array }
      end
      let(:error_status) { 412 }

      before do
        stub_request(
          :get,
          %r{#{instructor_courses_endpoint_url}?.*}
        ).to_return(
          status: error_status,
          body: error_hash.to_json,
          headers: { 'Content-Type' => 'application/json' }
        )
      end

      it 'returns nil' do
        expect(client.courses_for_school(school_salesforce_id)).to be_nil
      end

      it 'warns the VHLMonitor' do
        expected_params = {
          endpoint: '/one_roster_api/courses',
          errors: errors_array,
          response_status: error_status,
          school_salesforce_id: school_salesforce_id,
          username: instructor.username
        }
        client.courses_for_school(school_salesforce_id)
        expect(VHLMonitor).to have_received(:warning).with('Fail response from RosterAssistant',
                                                           expected_params)
      end

      it 'does not save an error message if the response was not a JSON payload' do
        server_error_code = 500
        stub_request(:get, %r{#{instructor_courses_endpoint_url}?.*})
          .to_return(status: server_error_code, body: '')
        client.courses_for_school(school_salesforce_id)
        expect(client.last_request_errors).to be_nil
        expect(client.last_request_status).to eq server_error_code
      end
    end
  end

  describe '#last_request_successful?' do
    let(:any_ra_request) do
      %r(#{RA_URL}.*)
    end

    it 'returns true if the last response was 200' do
      stub_request(:get, any_ra_request)
        .to_return(
          status: 200,
          body: nil,
          headers: { 'Content-Type' => 'application/json' }
      )
      client.courses_for_school(school_salesforce_id)
      expect(client).to be_last_request_successful
    end

    it 'returns false if the last response was not 200' do
      stub_request(
        :get,
        any_ra_request
      ).to_return(
        status: 412,
        body: nil,
        headers: { 'Content-Type' => 'application/json' }
      )
      client.courses_for_school(school_salesforce_id)
      expect(client).not_to be_last_request_successful
    end
  end
end
