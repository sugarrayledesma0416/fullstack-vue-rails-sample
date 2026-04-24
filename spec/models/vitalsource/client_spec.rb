module Vitalsource
  describe Client do
    def new_xml_body
      xml = Builder::XmlMarkup.new(indent: 2)
      xml.instruct!
      xml
    end

    let(:user) { build_stubbed(:user) }
    let(:api_key) { 'abcd-1111-zzzz' }
    let(:api_url) { 'https://rspec.vitalsource.com/api' }

    let(:config) { double(Vitalsource::Config, api_key: api_key, api_url: api_url) }

    let(:xml_body) do
      new_xml_body.user(user.email)
    end

    let(:ok_response) { { status: 200, body: xml_body, headers: {} } }

    describe '#post' do
      before do
        allow(Vitalsource).to receive(:config) { config }
      end

      let(:endpoint_url) { 'v3/users.xml' }
      let(:request_url) { "#{api_url}/#{endpoint_url}" }

      let!(:request) { stub_request(:post, request_url).to_return(ok_response) }

      context 'when sending a request' do
        before do
          described_class.new.post(endpoint_url, xml_body)
        end

        it 'makes a post request to the specified endpoint url' do
          expect(request).to have_been_made
        end

        it 'includes the api key in the post request headers' do
          expected_headers = { 'X-VitalSource-API-Key' => api_key }
          expect(request.with(headers: expected_headers)).to have_been_made
        end

        it 'posts with a content type of xml' do
          expected_headers = { 'Content-Type' => 'text/xml' }
          expect(request.with(headers: expected_headers)).to have_been_made
        end

        it 'includes the specified body content in the post request body' do
          expect(request.with(body: xml_body)).to have_been_made
        end
      end

      context 'when initialized with an access token' do
        it 'includes the access token in the post request headers' do
          request = stub_request(:post, request_url).to_return(ok_response)

          access_token = 'abdefghijklmnop'
          expected_headers = { 'X-VitalSource-Access-Token' => access_token }

          described_class.new(access_token).post(endpoint_url, xml_body)

          expect(request.with(headers: expected_headers)).to have_been_made
        end
      end

      context 'when the http status code of the response is an error code' do
        it 'returns a hash with the error code as an integer' do
          error_code = 403
          stub_request(:post, request_url).to_return(status: error_code)

          result = described_class.new.post(endpoint_url, xml_body)

          expect(result[:error_code]).to eq(error_code)
        end
      end

      context 'when the http status code of the response is a success code' do
        context 'when the response body contains an xml error code' do
          it 'returns a hash with the xml error code as an integer and the error message' do
            error_code = 604
            error_message = 'Invalid parameters'

            error_body = new_xml_body.tag!('error-response') do |error_node|
              error_node.tag!('error-code', error_code.to_s)
              error_node.tag!('error-text', error_message)
            end
            stub_request(:post, request_url).to_return(status: 200,
                                                       body: error_body)

            result = described_class.new.post(endpoint_url, xml_body)

            expect(result[:error_code]).to eq(error_code)
            expect(result[:error_message]).to eq(error_message)
          end
        end

        context 'when the response body contains no xml error code' do
          it 'returns the response body parsed as xml' do
            stub_request(:post, request_url).to_return(status: 200,
                                                       body: xml_body)

            result = described_class.new.post(endpoint_url, xml_body)

            expect(result).to be_a(Nokogiri::XML::Document)
            expect(result.at('user').content).to eq(user.email)
          end
        end
      end
    end

    describe '#get' do
      before do
        allow(Vitalsource).to receive(:config) { config }
      end

      let(:endpoint_url) { 'v3/licenses.xml' }
      let(:request_url) { "#{api_url}/#{endpoint_url}" }
      let!(:request) { stub_request(:get, request_url).to_return(ok_response) }

      context 'when sending a request' do
        before do
          described_class.new.get(endpoint_url)
        end

        it 'makes a get request to the specified endpoint url' do
          expect(request).to have_been_made
        end

        it 'includes the api key in the get request headers' do
          expected_headers = { 'X-VitalSource-API-Key' => api_key }
          expect(request.with(headers: expected_headers)).to have_been_made
        end
      end

      context 'when initialized with an access token' do
        it 'includes the access token in the get request headers' do
          request = stub_request(:get, request_url).to_return(ok_response)

          access_token = 'abdefghijklmnop'
          expected_headers = { 'X-VitalSource-Access-Token' => access_token }

          described_class.new(access_token).get(endpoint_url)

          expect(request.with(headers: expected_headers)).to have_been_made
        end
      end

      context 'when the http status code of the response is an error code' do
        it 'returns a hash with the error code as an integer' do
          error_code = 403
          stub_request(:get, request_url).to_return(status: error_code)

          result = described_class.new.get(endpoint_url)

          expect(result[:error_code]).to eq(error_code)
        end
      end

      context 'when the http status code of the response is a success code' do
        context 'when the response body contains an xml error code' do
          it 'returns a hash with the xml error code as an integer and the error message' do
            error_code = 604
            error_message = 'Invalid parameters'

            error_body = new_xml_body.tag!('error-response') do |error_node|
              error_node.tag!('error-code', error_code.to_s)
              error_node.tag!('error-text', error_message)
            end
            stub_request(:get, request_url).to_return(status: 200,
                                                      body: error_body)

            result = described_class.new.get(endpoint_url)

            expect(result[:error_code]).to eq(error_code)
            expect(result[:error_message]).to eq(error_message)
          end
        end

        context 'when the response body contains no xml error code' do
          it 'returns the response body parsed as xml' do
            stub_request(:get, request_url).to_return(status: 200,
                                                      body: xml_body)

            result = described_class.new.get(endpoint_url)

            expect(result).to be_a(Nokogiri::XML::Document)
            expect(result.at('user').content).to eq(user.email)
          end
        end
      end
    end
  end
end
