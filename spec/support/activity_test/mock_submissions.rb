module ActivityTest
  module MockSubmissions
    def initialize_fake_submissions_client
      allow(SubmissionClient::Submission).to receive(:create) do |args|
        @submission_id ||= 0
        @submission_id += 1
        id = @submission_id

        submission = SubmissionClient::Submission.new(
          'id' => id,
          'attempt_id' => args[:attempt_id],
          'partition_key' => args[:partition_key],
          'data' => JSON.parse(args[:data])
        )
        fake_submissions[id] = submission
        submission
      end

      allow(SubmissionClient::Submission).to receive(:find) do |id, _partition_key|
        ids = id.is_a?(Array) ? id : [id]
        ids.map do |id|
          fake_submissions[id]
        end.compact
      end
    end
  end
end
