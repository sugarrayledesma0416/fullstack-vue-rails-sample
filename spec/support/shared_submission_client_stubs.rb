module SharedSubmissionClientStubs
  def submission_class
    SubmissionClient::Submission
  end

  def stub_nil_submission_find
    allow(submission_class).to receive(:find).with(nil, anything).and_return([])
  end

  def stub_submission_find(submission_data = {}, submission_id = 1)
    # Stub default with nil id to return empty array
    stub_nil_submission_find

    allow(submission_class).to receive(:find).with(submission_id, anything).and_return(
      [
        SubmissionClient::Submission.new(
          'id' => submission_id,
          'data' => submission_data
        )
      ]
    )
  end

  def stub_submission_create(id = 999)
    allow(submission_class).to receive(:create).and_return(
      submission_class.new('id' => id, 'data' => {})
    )
  end
end
