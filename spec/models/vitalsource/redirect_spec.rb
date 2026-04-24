module Vitalsource
  describe Redirect do
    describe '#sso_url' do
      let(:client) { double(Vitalsource::Client) }
      let(:access_token) { 'abdefghijklmnop' }
      let(:book_id) { '978-1-68004-319-8' }
      let(:redirect) { described_class.new(access_token, book_id) }
      let(:error_response) { { error_code: 403 } }

      let(:bookshelf_url) { 'https://rspec.bookshelf.vitalsource.com/books' }

      let(:config) { double(Vitalsource::Config, bookshelf_url: bookshelf_url) }

      before do
        allow(Client).to receive(:new) { client }
        allow(Vitalsource).to receive(:config) { config }
      end

      it 'initializes a client with the specified access token' do
        expect(Client).to receive(:new).with(access_token) { client }
        allow(client).to receive(:post).and_return(error_response)

        redirect.sso_url
      end

      it 'sends a post request to the generate sso redirect endpoint' do
        expect(client).to receive(:post).with('v3/redirects.xml', anything)
          .and_return(error_response)

        redirect.sso_url
      end

      it 'posts an xml body containing the destination book id' do
        book_url = "#{bookshelf_url}/#{book_id}"
        allow(client).to receive(:post).with('v3/redirects.xml', anything) do |_, body|
          expect(body).to match(/<redirect>/)
          expect(body).to match %r{<destination>#{book_url}</destination>}
          expect(body).to match %r{</redirect>}
          error_response
        end

        redirect.sso_url
      end

      context 'when the sso redirect is generated successfully' do
        it 'returns the redirect_url' do
          redirect_url = 'https://online.vitalsource.com/redirects/EFH7RPC'
          response_xml = %(<redirect auto-signin="#{redirect_url}" />)
          allow(client).to receive(:post).with('v3/redirects.xml', anything)
            .and_return(Nokogiri::XML.parse(response_xml))

          expect(redirect.sso_url).to eq(redirect_url)
        end
      end

      context 'when the request fails with a bad http status' do
        it 'returns the error response' do
          allow(client).to receive(:post).with('v3/redirects.xml', anything)
            .and_return(error_response)

          expect(redirect.sso_url).to eq(error_response)
        end
      end

      context 'when the request fails with a bad xml status' do
        it 'returns the error response' do
          allow(client).to receive(:post).with('v3/redirects.xml', anything)
            .and_return(error_response)

          expect(redirect.sso_url).to eq(error_response)
        end
      end
    end
  end
end
