module Vitalsource
  describe License do
    let(:user) { build_stubbed(:user) }
    let(:access_token) { 'abdefghijklmnop' }
    let(:book_id) { '978-1-68004-319-8' }

    it 'raises an ArgumentError if expires_on arg is not a date' do
      expect do
        described_class.new(access_token, book_id, nil)
      end.to raise_error(ArgumentError, /Nil/)
      expect do
        described_class.new(access_token, book_id, 1.day.from_now)
      end.to raise_error(ArgumentError, /TimeWithZone/)
      expect do
        described_class.new(access_token, book_id, '2015-09-25')
      end.to raise_error(ArgumentError, /String/)
      expect do
        described_class.new(access_token, book_id, Date.new(1977, 9, 25))
      end.not_to raise_error
    end

    describe '#ensure_access' do
      let(:client) { double(Vitalsource::Client) }
      let(:license) { described_class.new(access_token, book_id, expires_on) }
      let(:code) { 'KJSHDFJHSDFJSKDDJFH' }
      let(:error_response) { { error_code: 403 } }
      let(:expires_on) { 30.days.from_now.to_date }
      let(:existing_license) { double(Vitalsource::ExistingLicense, active?: true) }

      before do
        allow(Client).to receive(:new) { client }
        allow(Vitalsource::ExistingLicense).to receive(:new) { existing_license }
      end

      it 'checks if the user already has the correct license' do
        expect(Vitalsource::ExistingLicense).to receive(:new)
          .with(access_token, book_id)
          .and_return(existing_license)
        expect(existing_license).to receive(:active?) { true }

        license.ensure_access {} # noop block
      end

      context 'when the user already has the correct access' do
        before do
          allow(existing_license).to receive(:active?) { true }
        end

        it 'does not send a request to the create code endpoint' do
          expect(client).not_to receive(:post).with('v3/codes.xml', anything)

          license.ensure_access {} # noop block
        end

        it 'yields control' do
          expect { |blk| license.ensure_access(&blk) }.to yield_control
        end
      end

      context 'when the user does not have the correct access' do
        before do
          allow(existing_license).to receive(:active?) { false }
        end

        it 'initializes a client with the specified access token' do
          expect(Client).to receive(:new).with(access_token) { client }
          allow(client).to receive(:post).and_return(error_response)

          license.ensure_access {} # noop block
        end

        it 'sends a post request to the create code endpoint' do
          expect(client).to receive(:post).with('v3/codes.xml', anything)
            .and_return(error_response)

          license.ensure_access {} # noop block
        end

        it 'posts an xml body containing the book id and license duration' do
          allow(client).to receive(:post).with('v3/codes.xml', anything) do |_, body|
            expect(body).to match(/<codes sku="#{book_id}"/)
            expect(body).to match(/license-type="absdate"/)
            expect(body).to match(/exp-year="#{expires_on.year}"/)
            expect(body).to match(/exp-month="#{expires_on.month}"/)
            expect(body).to match(/exp-day="#{expires_on.day}"/)
            expect(body).to match(/num-codes="1"/)
            error_response
          end

          license.ensure_access {} # noop block
        end

        context 'when the code creation is successful' do
          before do
            response_xml = "<codes><code>#{code}</code></codes>"
            allow(client).to receive(:post).with('v3/codes.xml', anything)
              .and_return(Nokogiri::XML.parse(response_xml))
          end

          it 'posts an xml body containing the access token and created code' do
            allow(client).to receive(:post).with('v3/redemptions.xml', anything) do |_, body|
              expect(body).to match(/<redemption>/)
              expect(body).to match %r{<code>#{code}</code>}
              expect(body).to match %r{</redemption>}
              error_response
            end

            license.ensure_access {} # noop block
          end

          context 'when the redemption request fails with a bad http status' do
            it 'returns the error response' do
              allow(client).to receive(:post).with('v3/redemptions.xml', anything)
                .and_return(error_response)

              result = license.ensure_access

              expect(result).to eq(error_response)
            end
          end

          context 'when the redemption request fails with a bad xml status' do
            before do
              allow(client).to receive(:post).with('v3/redemptions.xml', anything)
                .and_return(error_response)
            end

            it 'returns the error response' do
              result = license.ensure_access

              expect(result).to eq(error_response)
            end

            it 'does not yield' do
              expect { |blk| license.ensure_access(&blk) }.not_to yield_control
            end
          end

          context 'when the redemption request is successful' do
            it 'yields' do
              response_xml = <<-EOT
              <credentials>
                <credential email="#{user.email}" access-token="#{access_token}"
                            guid="ESH87HNDKS7765SD" reference="#{user.id}">
                </credential>
               </credentials>
              EOT
              allow(client).to receive(:post).with('v3/redemptions.xml', anything)
                .and_return(Nokogiri::XML.parse(response_xml))

              expect { |blk| license.ensure_access(&blk) }.to yield_control
            end
          end
        end

        context 'when the code creation fails with a bad http status' do
          it 'returns the error and does not make any further requests' do
            expect(client).to receive(:post).once
            expect(client).not_to receive(:get)
            allow(client).to receive(:post).with('v3/codes.xml', anything)
              .and_return(error_response)

            result = license.ensure_access

            expect(result).to eq(error_response)
          end

          it 'does not yield' do
            allow(client).to receive(:post).with('v3/codes.xml', anything)
              .and_return(error_response)

            expect { |blk| license.ensure_access(&blk) }.not_to yield_control
          end
        end
      end
    end
  end
end
