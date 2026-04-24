#encoding: utf-8
describe ResultsApiDatastore, :core => true do
  let(:attempt) { create(:attempt)}
  let(:api_ds) { ResultsApiDatastore.new(attempt) }
  let(:results) { [{label: 'label one' , response: 'response one' }]}
  let(:data_response) { double('response', :response => { "data" => { 'label one' => 'response one'}}, :any? => true )}
  let(:write_response) { double('response', :id => '101', :any? => true )}
  let(:empty_response) {}

  describe "#read" do
    it "returns the response data returned by the api service" do
      expect(SubmissionClient::Submission).to receive(:find)
        .with(attempt.submission_id, attempt.submission_partition_key)
        .and_return([data_response])

      expect(api_ds.read).to eql(data_response.response["data"])
    end
  end

  describe "#write" do
    it "send the results data by the api service" do
      allow(attempt).to receive(:set_saved_attempt)
      expect(SubmissionClient::Submission).to receive(:create)
        .with(attempt_id: attempt.id,
              partition_key: attempt.submission_partition_key,
              data: data_response.response['data'].to_json)
        .and_return(write_response)

      api_ds.write(results)
    end
  end

  describe "#stored_responses" do
    it "returns responses stored in the process, but not submitted yet" do
      allow(attempt).to receive(:submission_id).and_return(101)
      allow(attempt).to receive(:saved_submission_id).and_return(nil)

      api_ds = ResultsApiDatastore.new(attempt)

      expect(SubmissionClient::Submission).to receive(:find)
        .with(attempt.submission_id, attempt.submission_partition_key)
        .and_return([data_response])

      api_ds.stored_responses

      expect(SubmissionClient::Submission).to receive(:find)
        .with(attempt.saved_submission_id, attempt.submission_partition_key)
        .and_return([empty_response])

      api_ds.saved_responses
    end
  end

  describe "#saved_responses" do
    it "returns submitted as final responses" do
      allow(attempt).to receive(:submission_id).and_return(nil)
      allow(attempt).to receive(:saved_submission_id).and_return(102)
      ds = ResultsApiDatastore.new(attempt)

      expect(SubmissionClient::Submission).to receive(:find)
        .with(attempt.submission_id, attempt.submission_partition_key)
        .and_return([empty_response])

      ds.stored_responses

      expect(SubmissionClient::Submission).to receive(:find)
        .with(attempt.saved_submission_id, attempt.submission_partition_key)
        .and_return([data_response])

      ds.saved_responses
    end
  end
end

describe ResultsApiDatastore::MultipleAttempts do
  let(:store) { ResultsApiDatastore::MultipleAttempts.new(attempts) }
  let(:attempts) {[ create(:attempt, :submission_id => 10101),
                    create(:attempt, :submission_id => 20101)]}
  let(:response_1) { double(:submission, :attempt_id => attempts[0].id, data: 'Data 1')}
  let(:response_2) { double(:submission, :attempt_id => attempts[1].id, data: 'Data 2')}
  let(:part_key_1) { attempts[0].created_at.utc.strftime("%Y-%m-%d") }
  let(:part_key_2) { attempts[1].created_at.utc.strftime("%Y-%m-%d") }


  describe "#stored_response" do
    it "looks up the submission api using all the attempts" do
      expect(SubmissionClient::Submission).to receive(:find).with(
        [attempts[0].submission_id, attempts[1].submission_id],
        [part_key_1, part_key_1])
        .and_return([response_1, response_2])
      store.stored_response(attempts[0])
    end

    it "returns the submission for given attempt" do
      allow(SubmissionClient::Submission).to receive(:find).with(
        [attempts[0].submission_id, attempts[1].submission_id],
        [part_key_1, part_key_1])
        .and_return([response_1, response_2])
      expect(store.stored_response(attempts[1])).to eql(response_2.data)
    end
  end

  describe "#cacheable?" do
    it "return false when at least one attempt does not have a submission_id" do
      attempts << create(:attempt)
      expect(store.cacheable?).to be_falsey
    end

    it "return true when all attempts have a submission_id" do
      expect(store.cacheable?).to be_truthy
    end
  end
end
