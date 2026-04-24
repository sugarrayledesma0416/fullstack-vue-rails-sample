# This model is a result of extraction submissions related attributes and methods from Attempt.
# It shares the same table with the Attempt model because we were not ready to migrate data
# (too many records)
# TODO: Ideally data must be migrated in its own table.
module AttemptSubmission
  def self.included(recipient)
    recipient.extend(ClassMethods)
  end

  class Mode
    # Mode values choosen exactly as this to keep it compatible with the
    # external code uses them as symbols or strings
    SAVED = :unsubmitted
    SUBMITTED = :submitted
  end

  module ClassMethods
    def act_as_attempt_submission
      include AttemptSubmission::InstanceMethods
    end
  end

  module InstanceMethods
    def submission_partition_key
      # if this is a new attempt record, we'll set created_at.
      # active record will not over-write this value when the record is saved.
      self.created_at ||= Time.now.utc
      # we want the key normalized to utc
      created_at.utc.strftime('%Y-%m-%d')
    end

    def submitted_values? # values that count for a grade
      (submission_id.present? || record_length.to_i > 0)
    end

    def saved_values? # values saved to resume work later
      (saved_submission_id.present? || save_record_length.to_i > 0)
    end

    def reset_submission
      update!(offset_bytes: nil, record_length: nil, submission_id: nil)
    end

    def set_submission(file_offset, byte_length, submission_id, save_mode = Mode::SUBMITTED)
      # don't do anything if save_mode is not specified
      return if save_mode.nil?

      if save_mode.to_sym == Mode::SAVED
        set_saved_attempt(file_offset, byte_length, submission_id)
      else
        set_stored_attempt(file_offset, byte_length, submission_id)
      end
    end

    def set_saved_attempt(file_offset, byte_length, submission_id)
      update!(
        save_offset_bytes: file_offset,
        save_record_length: byte_length,
        saved_submission_id: submission_id
      )
    end
    private :set_saved_attempt

    def set_stored_attempt(file_offset, byte_length, submission_id)
      update!(
        offset_bytes: file_offset,
        record_length: byte_length,
        submission_id: submission_id,
        save_offset_bytes: nil,
        save_record_length: nil,
        saved_submission_id: nil
      )
    end
    private :set_stored_attempt
  end
end
