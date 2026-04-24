module Vhl
  module Stats
    module Faraday
      describe VhlApiUriSanitizer do
        describe 'sanitize' do
          let(:api_host) { 'api.maestro.vhlcentral.com' }
          let(:api_url_1) { '/v3/site_admins/23' }
          let(:api_genurl_1) { '/v3/site_admins/_id_' }
          let(:api_url_2) { '/v3/users/f4bc5683-cd04-4b4f-a057-43a0c79519f9/programs' }
          let(:api_genurl_2) { '/v3/users/_guid_/programs' }
          let(:api_url_3) do
            '/v3/users/f4bc5683-cd04-4b4f-a057-43a0c79519f9/course_access?course_guid=9bf40461-03c3-407e-b168-06f52c315e4f'
          end
          let(:api_genurl_3) { '/v3/users/_guid_/course_access' }

          it 'replaces ids' do
            filter = VhlApiUriSanitizer.new
            expect(filter.sanitize(api_host, api_url_1)).to eq api_genurl_1
          end

          it 'replaces guids' do
            filter = VhlApiUriSanitizer.new
            expect(filter.sanitize(api_host, api_url_2)).to eq api_genurl_2
          end

          it 'removes params' do
            filter = VhlApiUriSanitizer.new
            expect(filter.sanitize(api_host, api_url_3)).to eq api_genurl_3
          end

          it 'passes thru a uri for an non-matching host' do
            filter = VhlApiUriSanitizer.new
            expect(filter.sanitize('my_host.com', api_url_1)).to eq api_url_1
          end
        end
      end
    end
  end
end
