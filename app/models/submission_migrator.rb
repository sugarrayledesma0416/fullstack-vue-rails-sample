class SubmissionMigrator
  def self.results_xml_datastore(attempt)
    @xml_store = ResultsXmlDatastore.new(attempt)
  end

  def self.results_api_datastore(attempt)
    @api_store = ResultsApiDatastore.new(attempt)
  end

  def self.sync_api(attempt)
    attempt.submitted_values? && attempt.update(
      submission_id: results_api_datastore(attempt).write(
        results_xml_datastore(attempt).stored_responses
      )
    )
    attempt.saved_values? && attempt.update(
      saved_submission_id: results_api_datastore(attempt).write(
        results_xml_datastore(attempt).saved_responses
      )
    )
  end
end
