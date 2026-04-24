class IgcCopyJob < ApplicationRecord
  MAX_ATTEMPTS = 5

  belongs_to :src_program, class_name: 'Program'
  belongs_to :dest_program, class_name: 'Program'
  belongs_to :instructor

  # NOTE: We assume that the object is initialized with a value for `to_be_copied_ids`
  #       and `copied_ids`.
  # TODO: Validate that this is so.

  def run
    @attempt_count = 0

    # Save the initial count of activities to be copied.
    #   If not all activities are copied successfully,
    #   we can include this in the error message we provide
    #   to the user.
    @initial_to_be_copied_count = to_be_copied_ids.count

    # create the copier
    copier = InstructorGeneratedContentCopier.new(
      dest_program_id: dest_program_id,
      to_be_copied_ids: to_be_copied_ids,
      copied_ids: copied_ids
    )

    # We try to copy as long as there are still activities to be
    #   copied and we haven't exhausted all attempts.
    while in_progress?
      begin
        copier.copy
      rescue IgcCopyException => e
        # Catch the exception so that we can keep trying up to
        #   MAX_ATTEMPTS times.

        # Log some information about the copy error.
        if defined?(STATS_PROXY) && STATS_PROXY.present?
          stats_object = { type: 'logstash_object',
                           vhl_component: 'igc_copy',
                           application: :m3,
                           instructor_id: instructor_id,
                           src_program_id: src_program_id,
                           dest_program_id: dest_program_id,
                           message: e.message,
                           failed_activity_ids: e.data[:failed_activity_ids],
                           error_messages: e.data[:error_messages],
                           environment: Rails.env }

          STATS_PROXY.relay(stats_object)
        end
      ensure
        # The copier has a list of IDs it's trying to copy;
        #   it crosses items off the list as each copy succeeds.
        #
        # Here, we get the copier's list after the copy
        #   and check whether anything remains to be copied.
        #   If so, we increment the count and try again.
        #
        # This runs in an `ensure` block to enforce that we
        #   update the list of to-be-copied and copied IDs
        #   even if there is an error during the copy.
        self.to_be_copied_ids = copier.to_be_copied_ids
        self.copied_ids = copier.copied_ids

        # Update the to_be_copied_ids and copied_ids.
        save!
        @attempt_count += 1 if ids_still_to_be_copied?
      end
    end

    # If there are still activities to be copied,
    #   something went wrong: raise an error.
    raise 'Not all activities were copied.' unless to_be_copied_ids.empty?
  end

  def to_be_copied_ids
    ids_json = read_attribute(:to_be_copied_ids)
    @to_be_copied_ids = JSON.parse(ids_json)
  end

  def to_be_copied_ids=(ary)
    write_attribute(:to_be_copied_ids, ary.to_json)
  end

  def copied_ids
    ids_json = read_attribute(:copied_ids) || '[]'
    @copied_ids = JSON.parse(ids_json)
  end

  def copied_ids=(ary)
    write_attribute(:copied_ids, ary.to_json)
  end

  # The controller uses these two methods to populate the flash.
  def flash_notice
    %(
      #{copied_count}
      #{'activity'.pluralize(copied_count)} copied over successfully
    )
  end

  def flash_error
    %(
      #{to_be_copied_count}
      #{'activity'.pluralize(to_be_copied_count)} failed to copy.
      Please try again or contact Tech Support for help.
    )
  end

  def to_be_copied_count
    to_be_copied_ids.count
  end

  def copied_count
    @initial_to_be_copied_count - to_be_copied_count
  end

  private def in_progress?
    ids_still_to_be_copied? && @attempt_count < MAX_ATTEMPTS
  end

  private def ids_still_to_be_copied?
    to_be_copied_ids.length.positive?
  end

  private def activities_to_copy
    InstructorCreatedActivityForCopy
      .where(id: to_be_copied_ids)
      .select('activities.*')
  end
end
