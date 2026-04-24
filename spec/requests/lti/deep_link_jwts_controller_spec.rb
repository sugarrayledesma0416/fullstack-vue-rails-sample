describe Lti::DeepLinkJwtsController do
  let(:claims) { GradebookEngine::Lti::Constants::CLAIMS }
  let(:program) { create(:program) }
  let(:unit) { create(:unit, program: program) }
  let(:strand) { build_stubbed(:toc_entry) }
  let(:lesson) { create(:lesson, toc_entries: [strand], unit: unit) }
  let(:platform) { create(:lti_platform) }
  let(:private_key) { Rails.configuration.lti_tool_private_keys.first }
  let(:public_key) { private_key.public_key }
  let(:ua_url) { 'https://testenv.vhlcentral.com/' }

  let(:launch) do
    create(
      :lti_launch,
      decoded_jwt: { 'aud' => platform.client_id, 'iss' => platform.issuer_id }
    )
  end

  let(:activity) do
    create(:activity, lesson: lesson, toc_location: strand.location)
  end

  describe 'POST /create' do
    before { stub_const('UA_URL', ua_url) }

    def do_request(extra_params = {})
      post lti_deep_link_jwt_path(params: default_params.merge(extra_params))
    end

    def decoded_jwt(encoded_jwt)
      JWT.decode(encoded_jwt, public_key, true, algorithm: 'RS256').first
    end

    context 'when creating a vhlcentral home page deep link,' do
      let(:default_params) do
        { launch_guid: launch.guid, view: 'homepage' }
      end

      it 'returns a jwt' do
        do_request

        payload = JSON.parse(response.body, symbolize_names: true)

        jwt_result = decoded_jwt(payload[:jwt])

        title = 'VHLCentral Home'

        expect(jwt_result[claims[:content_item]]).to contain_exactly(
          'custom' => { 'view' => 'homepage' },
          'title' => title,
          'type' => 'ltiResourceLink',
          'url' => "#{UA_URL}lti/resource_link?view=homepage"
        )
      end
    end

    context 'when creating a dashboard deep link,' do
      let(:default_params) do
        {
          launch_guid: launch.guid,
          program_id: program.id,
          view: 'dashboard'
        }
      end

      it 'returns a jwt' do
        do_request

        payload = JSON.parse(response.body, symbolize_names: true)

        jwt_result = decoded_jwt(payload[:jwt])

        title = 'Current Assignments'

        expect(jwt_result[claims[:content_item]]).to contain_exactly(
          'custom' => {
            'program_id' => program.id.to_s, 'view' => 'dashboard'
          },
          'title' => title,
          'type' => 'ltiResourceLink',
          'url' => "#{UA_URL}lti/resource_link?program_id=#{program.id}" \
                   '&view=dashboard'
        )
      end
    end

    context 'when creating an activity deep link,' do
      let(:default_params) do
        {
          activity_id: activity.id,
          launch_guid: launch.guid
        }
      end

      it 'returns a jwt and link info' do
        do_request

        payload = JSON.parse(response.body, symbolize_names: true)

        title = "#{lesson.display_name} - #{strand.display_name} " \
                "- #{activity.title}"

        expect(payload[:link_info]).to eq(title)

        jwt_result = decoded_jwt(payload[:jwt])

        expect(jwt_result[claims[:content_item]]).to contain_exactly(
          'custom' => {
            'activity_id' => activity.id, 'program_id' => program.id
          },
          'title' => title,
          'type' => 'ltiResourceLink',
          'url' => "#{UA_URL}lti/resource_link?activity_id=#{activity.id}" \
                   "&program_id=#{program.id}"
        )
      end
    end
  end
end
