module Vitalsource
  describe ReferenceUser do
    describe '#access_token' do
      let(:client) { double(Vitalsource::Client) }

      let(:user) { build_stubbed(:user) }
      let(:access_token) { 'abdefghijklmnop' }
      let(:reference_user) { described_class.new(user) }

      before do
        allow(Client).to receive(:new) { client }
      end

      context 'when no previous redemption exists for the user' do
        it 'sends a post request to the create user endpoint' do
          expect(client).to receive(:post).with('v3/users.xml', anything)
            .and_return(error_code: 403)

          reference_user.access_token(&:noop)
        end

        it 'posts an xml body containing the name and id of the user' do
          allow(client).to receive(:post).with('v3/users.xml', anything) do |_, body|
            expect(body).to match %r{<first-name>#{user.first_name}</first-name>}
            expect(body).to match %r{<last-name>#{user.last_name}</last-name>}
            expect(body).to match %r{<reference>#{user.id}</reference}
            {error_code: 403}
          end

          reference_user.access_token(&:noop)
        end

        context 'when the reference user creation is successful' do
          it 'extracts the access token from the response body and yields it' do
            response_xml = <<-EOT
              <user>
                <email>bob@bobbington.com</email>
                <first-name>Bob</first-name>
                <last-name>Bobbington</last-name>
                <guid>12345678041234566</guid>
                <access-token>#{access_token}</access-token>
                <library></library>
              </user>
            EOT
            allow(client).to receive(:post).with('v3/users.xml', anything)
              .and_return(Nokogiri::XML.parse(response_xml))

            expect { |blk| reference_user.access_token(&blk) }.to yield_with_args(access_token)
          end
        end

        context 'when the reference user creation fails with a bad http status' do
          it 'returns the error or make any further requests' do
            expect(client).to receive(:post).once
            expect(client).not_to receive(:get)
            allow(client).to receive(:post).with('v3/users.xml', anything)
              .and_return(error_code: 403)

            result = reference_user.access_token

            expect(result[:error_code]).to eq(403)
          end

          it 'does not yield' do
            allow(client).to receive(:post).with('v3/users.xml', anything)
              .and_return(error_code: 403)

            expect { |blk| reference_user.access_token(&blk) }.not_to yield_control
          end
        end

        context 'when the reference user creation fails because the user already exists' do
          before do
            allow(client).to receive(:post).with('v3/users.xml', anything)
              .and_return(error_code: 904,
                          error_message: 'User reference already exists')
          end

          it 'does not return the error' do
            allow(client).to receive(:post).with('v3/credentials.xml', anything)
              .and_return(error_code: 403)
            result = reference_user.access_token

            expect(result[:error_code]).not_to eq(904)
          end

          it 'sends a post request to the credentials endpoint' do
            expect(client).to receive(:post).with('v3/credentials.xml', anything)

            reference_user.access_token
          end

          it 'posts an xml body containing the id of the user' do
            allow(client).to receive(:post).with('v3/credentials.xml', anything) do |_, body|
              expect(body).to match(/<credential reference="#{user.id}"/)
            end

            reference_user.access_token
          end

          context 'when the credentials request fails with a bad http status' do
            it 'returns a hash with the http error code' do
              allow(client).to receive(:post).with('v3/credentials.xml', anything)
                .and_return(error_code: 403)

              result = reference_user.access_token

              expect(result[:error_code]).to eq(403)
            end
          end

          context 'when the credentials request fails with a bad xml status' do
            before do
              response_xml = <<-EOT
              <credentials>
                <error code="603" message="Invalid reference value"
                       email="" guid="" reference="#{user.id}">
                </error>
              </credentials>
              EOT
              allow(client).to receive(:post).with('v3/credentials.xml', anything)
                .and_return(Nokogiri::XML.parse(response_xml))
            end

            it 'returns a hash with the xml error code and message' do
              result = reference_user.access_token

              expect(result[:error_code]).to eq(603)
              expect(result[:error_message]).to eq('Invalid reference value')
            end

            it 'does not yield' do
              expect { |blk| reference_user.access_token(&blk) }.not_to yield_control
            end
          end

          context 'when the credentials request is successful' do
            it 'extracts the access token from the response body and yields it' do
              response_xml = <<-EOT
              <credentials>
                <credential email="#{user.email}" access-token="#{access_token}"
                            guid="ESH87HNDKS7765SD" reference="#{user.id}">
                </credential>
               </credentials>
              EOT
              allow(client).to receive(:post).with('v3/credentials.xml', anything)
                .and_return(Nokogiri::XML.parse(response_xml))

              expect { |blk| reference_user.access_token(&blk) }.to yield_with_args(access_token)
            end
          end
        end
      end

      context 'when a record of a previous redemption exists for the user' do
        before do
          VitalsourceRedemption.create!(user_id: user.id,
                                        program_id: build_stubbed(:program).id)
        end

        it 'does not send a post request to the create user endpoint' do
          expect(client).not_to receive(:post).with('v3/users.xml', anything)

          reference_user.access_token
        end

        it 'sends a post request to the credentials endpoint' do
          expect(client).to receive(:post).with('v3/credentials.xml', anything)

          reference_user.access_token
        end
      end

    end
  end
end
