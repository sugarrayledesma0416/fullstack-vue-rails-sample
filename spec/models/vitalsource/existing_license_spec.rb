module Vitalsource
  describe ExistingLicense do
    let(:access_token) { 'abdefghijklmnop' }
    let(:book_id) { '978-1-68004-319-8' }

    describe '#active?' do
      let(:client) { double(Vitalsource::Client) }
      let(:existing_license) { described_class.new(access_token, book_id) }
      let(:error_response) { { error_code: 403 } }
      let(:time_format) { '%a, %d %b %Y %H:%M:%S %Z' }
      let(:future_expiration) { 1.year.from_now.strftime(time_format) }
      let(:past_expiration) { 1.day.ago.strftime(time_format) }
      let(:correct_access_xml) do
        %(<licenses>
            <summary distributable_products="1" total_products="1"/>
            <license publisher="publisher" imprint="imprint"
              type="online" sku="#{book_id}" expiration="#{future_expiration}"
              code-use="code-api" part_of="" name="book name" term="" />
          </licenses>)
      end

      before do
        allow(Client).to receive(:new) { client }
      end

      it 'initializes a client with the specified access token' do
        expect(Client).to receive(:new).with(access_token) { client }
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(Nokogiri::XML.parse(correct_access_xml))
        existing_license.active?
      end

      it 'sends a get request to the get licenses endpoint' do
        expect(client).to receive(:get).with('v3/licenses.xml')
          .and_return(Nokogiri::XML.parse(correct_access_xml))

        existing_license.active?
      end

      it 'is true when the user already has the correct access' do
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(Nokogiri::XML.parse(correct_access_xml))

        expect(existing_license).to be_active
      end

      it 'is false when the user has access that has expired' do
        response_xml = <<-EOT
          <licenses>
            <summary distributable_products="1" total_products="1"/>
            <license publisher="publisher" imprint="imprint"
              type="online" sku="#{book_id}" expiration="#{past_expiration}"
              code-use="code-api" part_of="" name="book name" term="" />
          </licenses>
        EOT
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(Nokogiri::XML.parse(response_xml))
        expect(existing_license).not_to be_active
      end

      it 'is false when the user has access to no products' do
        response_xml = <<-EOT
          <licenses>
            <summary distributable_products="0" total_products="0"/>
          </licenses>
        EOT
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(Nokogiri::XML.parse(response_xml))
        expect(existing_license).not_to be_active
      end

      it 'is false when the user has access only to other products' do
        response_xml = <<-EOT
          <licenses>
            <summary distributable_products="1" total_products="1"/>
            <license publisher="publisher" imprint="imprint"
              type="online" sku="other_book_id" expiration="#{future_expiration}"
              code-use="code-api" part_of="" name="book name" term="" />
          </licenses>
        EOT
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(Nokogiri::XML.parse(response_xml))
        expect(existing_license).not_to be_active
      end

      it 'raises an error if the response is an http error' do
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(error_response)
        expect { existing_license.active? }.to raise_error do |error|
          expect(error.message).to match(/:error_code=>403/)
        end
      end

      it 'raises an error if the response is an xml error' do
        response = { error_code: 474,
                     error_message: 'User could not be found' }
        allow(client).to receive(:get).with('v3/licenses.xml')
          .and_return(response)
        error_regexp = /Vitalsource API Error #{Regexp.escape(response.inspect)}/
        expect { existing_license.active? }.to raise_error(error_regexp)
      end
    end
  end
end
