module Vhl
  module Stats
    module Faraday
      describe SubmissionsUriSanitizer do
        describe 'sanitize' do
          let(:submissions_host) { 'submissions.maestro.vhlcentral.com' }
          let(:submissions_url_1) { '/submissions' }
          let(:submissions_genurl) { '/submissions' }
          let(:submissions_url_2) { '/submissions?id=627833008&partition_key=2018-07-06' }

          it 'passes through a submissions POST' do
            filter = SubmissionsUriSanitizer.new
            expect(filter.sanitize(submissions_host, submissions_url_1)).to eq submissions_genurl
          end

          it 'removes params' do
            filter = SubmissionsUriSanitizer.new
            expect(filter.sanitize(submissions_host, submissions_url_2)).to eq submissions_genurl
          end

          it 'passes thru a uri for an non-matching host' do
            filter = SubmissionsUriSanitizer.new
            expect(filter.sanitize('my_host.com', submissions_url_2)).to eq submissions_url_2
          end
        end
      end
    end
  end
end
