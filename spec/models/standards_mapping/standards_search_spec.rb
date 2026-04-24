module StandardsMapping
  describe StandardsSearch do
    let(:std_set) { create(:standard_set, display_name: 'CCSS') }
    let(:parent_standard_1) do
      create(
        :standard,
        number: 'CCRA.1',
        vendor_standard_set_guid: std_set.vendor_guid,
        standard_set: std_set
      )
    end
    let(:parent_standard_2) do
      create(
        :standard,
        number: 'CCRA.2',
        vendor_standard_set_guid: std_set.vendor_guid,
        standard_set: std_set
      )
    end

    let(:additional_info_1) do
      JSON.generate(
        {
          additional_info: {
            ancestors: SecureRandom.uuid.to_s,
            grade_levels: '5,6',
            parent_guid: parent_standard_1.vendor_guid
          }
        }
      )
    end
    let(:additional_info_2) do
      JSON.generate(
        {
          additional_info: {
            ancestors: SecureRandom.uuid.to_s,
            grade_levels: '6,7,8',
            parent_guid: parent_standard_2.vendor_guid
          }
        }
      )
    end
    let(:standard_1) do
      create(
        :standard,
        number: 'CCRA.1.a',
        vendor_standard_set_guid: std_set.vendor_guid,
        standard_set: std_set,
        additional_info: additional_info_1
      )
    end
    let(:standard_2) do
      create(
        :standard,
        number: 'CCRA.2.a',
        vendor_standard_set_guid: std_set.vendor_guid,
        standard_set: std_set,
        additional_info: additional_info_2
      )
    end
    let(:standard_asset_1) { create(:standard_asset) }
    let(:standard_asset_2) { create(:standard_asset) }
    let(:http_connection)  { Net::HTTP.new('localhost', 3000) }
    let(:os_url) { 'https://localhost:9200' }
    let(:os_username) { 'test' }
    let(:os_password) { 'test' }
    let(:search_guid) { SecureRandom.uuid }
    let(:standards_search) { described_class.new }

    before do
      allow(Net::HTTP).to receive(:new).and_return(http_connection)
      allow(Rails.application.config).to receive(:standards_opensearch_url).and_return(os_url)
      allow(Rails.application.config).to receive(:opensearch_username).and_return(os_username)
      allow(Rails.application.config).to receive(:opensearch_password).and_return(os_password)
    end

    describe '#search_standards' do
      context 'when the search is successful' do
        let(:search_body) do
          {
            'took' => 464,
            'timed_out' => false,
            'aggregations' => {
              'unique_vendors' => {
                'buckets' => [
                  {
                    'vendor_details' => {
                      'hits' => {
                        'hits' => [
                          {
                            '_source' => {
                              'vendor_guid' => standard_1.vendor_guid,
                              'name' => standard_1.name,
                              'number' => standard_1.number,
                              'label' => standard_1.label,
                              'description' => standard_1.description,
                              'vendor_standard_set_guid' => standard_1.vendor_standard_set_guid,
                              'issuer' => standard_1.standard_set.issuer,
                              'display_name' => standard_1.standard_set.display_name,
                              'parent' => {
                                'vendor_guid' => parent_standard_1.vendor_guid,
                                'name' => parent_standard_1.name,
                                'number' => parent_standard_1.number,
                                'label' => parent_standard_1.label,
                                'description' => parent_standard_1.description,
                                'vendor_standard_set_guid' => parent_standard_1.vendor_standard_set_guid,
                                'issuer' => parent_standard_1.standard_set.issuer,
                                'display_name' => parent_standard_1.standard_set.display_name
                              }
                            }
                          }
                        ]
                      }
                    }
                  }
                ]
              }
            }
          }.to_json
        end

        let(:std_search_result) do
          [
            {
              vendor_guid: standard_1.vendor_guid,
              name: standard_1.name,
              number: standard_1.number,
              label: standard_1.label,
              description: standard_1.description,
              vendor_standard_set_guid: standard_1.vendor_standard_set_guid,
              issuer: standard_1.standard_set.issuer,
              display_name: standard_1.standard_set.display_name,
              parent: {
                vendor_guid: parent_standard_1.vendor_guid,
                name: parent_standard_1.name,
                number: parent_standard_1.number,
                label: parent_standard_1.label,
                description: parent_standard_1.description,
                vendor_standard_set_guid: parent_standard_1.vendor_standard_set_guid,
                issuer: parent_standard_1.standard_set.issuer,
                display_name: parent_standard_1.standard_set.display_name
              }
            }
          ]
        end

        let(:search_response) do
          instance_double(Net::HTTPResponse, body: search_body, code: '200')
        end

        it 'returns the matching standards' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(
            standards_search.search_standards(
              ['12233'],
              'test',
              ['6'],
              79
            )
          ).to eql std_search_result
        end
      end

      context 'when the search finds no matches' do
        let(:search_body_no_results) do
          {
            'aggregations' => {
              'unique_vendors' => {
                'buckets' => []
              }
            }
          }.to_json
        end

        let(:search_response) do
          instance_double(Net::HTTPResponse, body: search_body_no_results, code: '200')
        end

        it 'returns an empty array' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(standards_search.search_standards(['12233'], 'test', %w[6 7 8], 79)).to eql []
        end
      end

      context 'when the search returns an error' do
        let(:stds_search_error_response) do
          {
            error:
              {
                reason: 'Something bad happened',
                details: 'More info',
                type: 'SomeException'
              },
            status: 400
          }.to_json
        end
        let(:search_response) do
          instance_double(
            Net::HTTPResponse,
            body: stds_search_error_response,
            code: '400',
            message: 'error-'
          )
        end

        it 'returns an error message' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(
            standards_search.search_standards([search_guid], 'poem', %w[4 5 6], 79)
          ).to eql "Standards Search ERROR search_term:poem standard_set_guids:'#{search_guid}' " \
                   'status:400 error-Something bad happened.'
        end
      end

      context 'when the search is a multi-phrase search' do
        let(:search_body) do
          {
            'aggregations' => {
              'unique_vendors' => {
                'buckets' => [
                  {
                    'vendor_details' => {
                      'hits' => {
                        'hits' => [
                          {
                            '_source' => {
                              'vendor_guid' => standard_1.vendor_guid,
                              'name' => standard_1.name,
                              'number' => standard_1.number,
                              'label' => standard_1.label,
                              'description' => standard_1.description,
                              'vendor_standard_set_guid' => standard_1.vendor_standard_set_guid,
                              'issuer' => standard_1.standard_set.issuer,
                              'display_name' => standard_1.standard_set.display_name,
                              'parent' => {
                                'vendor_guid' => parent_standard_1.vendor_guid,
                                'name' => parent_standard_1.name,
                                'number' => parent_standard_1.number,
                                'label' => parent_standard_1.label,
                                'description' => parent_standard_1.description,
                                'vendor_standard_set_guid' => parent_standard_1.vendor_standard_set_guid,
                                'issuer' => parent_standard_1.standard_set.issuer,
                                'display_name' => parent_standard_1.standard_set.display_name
                              }
                            }
                          }
                        ]
                      }
                    }
                  }
                ]
              }
            }
          }.to_json
        end

        let(:search_response) do
          instance_double(Net::HTTPResponse, body: search_body, code: '200')
        end

        let(:std_search_result) do
          [
            {
              vendor_guid: standard_1.vendor_guid,
              name: standard_1.name,
              number: standard_1.number,
              label: standard_1.label,
              description: standard_1.description,
              vendor_standard_set_guid: standard_1.vendor_standard_set_guid,
              issuer: standard_1.standard_set.issuer,
              display_name: standard_1.standard_set.display_name,
              parent: {
                vendor_guid: parent_standard_1.vendor_guid,
                name: parent_standard_1.name,
                number: parent_standard_1.number,
                label: parent_standard_1.label,
                description: parent_standard_1.description,
                vendor_standard_set_guid: parent_standard_1.vendor_standard_set_guid,
                issuer: parent_standard_1.standard_set.issuer,
                display_name: parent_standard_1.standard_set.display_name
              }
            }
          ]
        end

        it 'returns the matching standards' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(
            standards_search.search_standards(
              ['12233'],
              'building alliances',
              ['6'],
              79
            )
          ).to eql std_search_result
        end
      end
    end

    describe '#search_standard_assets' do
      context 'when the search is successful' do
        let(:search_body) do
          {
            'took' => 464,
            'timed_out' => false,
            'aggregations' => {
              'unique_vendors' => {
                'buckets' => [
                  {
                    'vendor_details' => {
                      'hits' => {
                        'hits' => [
                          {
                            '_source' => {
                              standard_asset_id: standard_asset_1.id,
                              standard_asset_reference_type: standard_asset_1.reference_type,
                              standard_asset_reference_id: standard_asset_1.reference_id,
                              standard_asset_domains: standard_asset_1.additional_attrs[:domain],
                              standard_asset_subdomains: standard_asset_1.additional_attrs[:subdomain]
                            }
                          }
                        ]
                      }
                    }
                  },
                  {
                    'vendor_details' => {
                      'hits' => {
                        'hits' => [
                          {
                            '_source' => {
                              standard_asset_id: standard_asset_2.id,
                              standard_asset_reference_type: standard_asset_2.reference_type,
                              standard_asset_reference_id: standard_asset_2.reference_id,
                              standard_asset_domains: standard_asset_1.additional_attrs[:domain],
                              standard_asset_subdomains: standard_asset_1.additional_attrs[:subdomain]
                            }
                          }
                        ]
                      }
                    }
                  }
                ]
              }
            }
          }.to_json
        end

        let(:search_response) do
          instance_double(Net::HTTPResponse, body: search_body, code: '200')
        end

        let(:std_asset_search_result) do
          [
            {
              standard_asset_id: standard_asset_1.id,
              reference_type: standard_asset_1.reference_type,
              reference_id: standard_asset_1.reference_id
            },
            {
              standard_asset_id: standard_asset_2.id,
              reference_type: standard_asset_2.reference_type,
              reference_id: standard_asset_2.reference_id
            }
          ]
        end

        it 'returns the matching standard_assets' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(standards_search.search_standard_assets([SecureRandom.uuid, SecureRandom.uuid],
                                                         370,
                                                         {
                                                           unit_id: [123, 456],
                                                           lesson_id: [234],
                                                           reference_type: ['Activity'],
                                                           selected_skills: ['Math'],
                                                           selected_refinements: ['Algebra']
                                                         })).to eql std_asset_search_result
        end
      end

      context 'when the search finds no matches' do
        let(:search_body_no_results) do
          {
            'took' => 464,
            'timed_out' => false,
            'aggregations' => {
              'unique_vendors' => {
                'buckets' => []
              }
            }
          }.to_json
        end

        let(:search_response) do
          instance_double(Net::HTTPResponse, body: search_body_no_results, code: '200')
        end

        it 'returns an empty array' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(
            standards_search.search_standard_assets([SecureRandom.uuid, SecureRandom.uuid], 370)
          ).to eql []
        end
      end

      context 'when the search returns an error' do
        let(:std_asset_search_error_response) do
          {
            error:
              {
                reason: 'Something bad happened',
                details: 'More info',
                type: 'SomeException'
              },
            status: 404
          }.to_json
        end
        let(:search_response) do
          instance_double(Net::HTTPResponse, body: std_asset_search_error_response, code: '400')
        end

        it 'returns an error message' do
          allow(http_connection).to receive(:request).and_return(search_response)
          expect(
            standards_search.search_standard_assets([search_guid], 370, { unit_id: [2345] })
          ).to eql "StandardAssets Search ERROR standard_guids:'#{search_guid}' " \
                   'program:370 filter:{:unit_id=>[2345]} ' \
                   'status:400 Something bad happened.'
        end
      end
    end

    describe '.setup_post' do
      it 'composes the correct http request' do
        expect(standards_search.send(:setup_post).class).to be Net::HTTP::Post
      end

      it 'has the correct path for the request' do
        standards_search.send(:setup_post)
        expect(standards_search.send(:request).path).to include('/_plugins/_sql/')
      end
    end

    describe '.setup_std_alignments_get' do
      it 'composes the correct http request' do
        expect(standards_search.send(:setup_std_alignments_get).class).to be Net::HTTP::Get
      end

      it 'has the correct path for the request' do
        standards_search.send(:setup_std_alignments_get)
        expect(standards_search.send(:request).path).to include('_standard_alignments_alias/_search/')
      end
    end

    describe '#browse_standards' do
      let(:standard_set_guids) { ['12233'] }
      let(:grades) { %w[6 7] }
      let(:program_id) { 79 }

      subject(:standards_search) { described_class.new }

      context 'when the browse search is successful' do
        let(:search_body) { { results: 'some_data' }.to_json }
        let(:http_response) do
          instance_double(Net::HTTPResponse, body: search_body, code: '200', message: 'OK')
        end

        it 'returns a hash with grade keys and the browse standards results as values' do
          allow(http_connection).to receive(:request).and_return(http_response)
          allow(standards_search).to receive(:build_browse_standards_results)
            .and_return([{ sample: 'result' }])
          expect(standards_search.browse_standards(standard_set_guids, grades,
                                                   program_id)).to eq([{ sample: 'result' }])
        end
      end

      context 'when the browse search returns an error' do
        let(:error_response_body) do
          { error: { reason: 'Something bad happened' } }.to_json
        end
        let(:http_response) do
          instance_double(Net::HTTPResponse, body: error_response_body, code: '400',
                                             message: 'error-')
        end

        it 'raises a StandardError with a formatted error message' do
          allow(http_connection).to receive(:request).and_return(http_response)
          formatted_error = format(
            described_class::BROWSE_STDS_QUERY_ERROR_MESSAGE,
            standard_set_guids.map { |e| "'#{e}'" }.join(', '),
            program_id,
            http_response.code,
            "#{http_response.message} Something bad happened"
          )
          expect do
            standards_search.browse_standards(standard_set_guids, grades, program_id)
          end.to raise_error(StandardError, formatted_error)
        end
      end
    end
  end
end
