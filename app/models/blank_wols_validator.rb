class BlankWolsValidator < ActiveModel::Validator
  def validate(record)
    # Only applies to JSON-based activities
    return unless record.send(:has_json_content?)

    # Don't attempt validations if the content_object cannot be retrieved.
    begin
      content_object = record.content_object
    rescue StandardError
      return
    end

    # Don't bother validating if the content object is already invalid.
    return if content_object.nil?

    # Don't validate if activity is being soft-deleted by setting
    # hide_from_my_content to true.
    return if record.hide_from_my_content

    # Only applies to exams or fill-in-the-blanks
    return unless %w[exam fill_in_the_blanks].include?(content_object.activity_type)

    return unless content_object.has_empty_wols?

    record.errors.add(:base, 'There is an error with the fill-in-the-blanks values.')
    restore_last_revision(record)
  end

  def restore_last_revision(record)
    # When editing an existing activity, the client-side editor will be
    # irreparably broken if wols are blank. To prevent this, reset to
    # the previous revision.
    last_good_revision = record.instructor_activity_revisions.last
    return unless last_good_revision

    record.content_json = last_good_revision.content_json
    # Re-parse to ensure content_object has the right data.
    record.parse_content
  end
end
