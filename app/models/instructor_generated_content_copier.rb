# Copies instructor-created activities from one program
#   to another.
class InstructorGeneratedContentCopier
  attr_accessor :copied_ids, :to_be_copied_ids

  def initialize(dest_program_id:,
                 to_be_copied_ids: nil,
                 copied_ids: nil)
    @dest_program_id = dest_program_id
    @to_be_copied_ids = to_be_copied_ids
    @copied_ids = copied_ids
  end

  def copy
    failed_activity_ids = []
    error_messages = []

    activities_to_copy.each do |activity_pair|
      begin
        original_activity, modifiable_activity = activity_pair

        # Duplicate the activity object.
        dup_activity = modifiable_activity.dup

        # Change the strand and lesson ID fields to the destination values.
        update_lesson_and_concept(dup_activity)

        # Save the object to bump the instructor revision ID and invoke the
        # callback in the for-copy subclass to copy the XML to a new file.
        dup_activity.save!

        # If save succeeded, remove the original activity from the to-copy list.
        to_be_copied_ids.delete(original_activity.id)
        copied_ids.append(original_activity.id)
      rescue => e
        failed_activity_ids.append(original_activity.id)
        error_messages.append(e.message)
      ensure
        # If there is a problem with saving one activity, move on to the next one.
        next
      end
    end

    return unless failed_activity_ids.present?

    raise IgcCopyException.new(
      'Some activities failed to copy.',
      failed_activity_ids: failed_activity_ids,
      error_messages: error_messages
    )
  end

  private def update_lesson_and_concept(activity)
    destination_ids = strand_lookup[activity.concept_id]

    activity.lesson_id = destination_ids[:dest_lesson_id]
    activity.concept_id = destination_ids[:dest_strand_id]
    activity.toc_location = destination_ids[:dest_strand_id]
  end

  private def strand_lookup
    @strand_lookup ||= mappings.each_with_object({}) do |mapping, h|
      h[mapping.src_strand_id] = {
        dest_strand_id: mapping.dest_strand.id,
        dest_lesson_id: mapping.dest_strand.lesson_id
      }
    end
  end

  private def activities_to_copy
    # These are the original activities.
    original_activities = InstructorCreatedActivity.find(to_be_copied_ids)

    # The original activities have some flag set on them such that, if they
    #   are `dup`ed, the `dup` copy is not modifiable (I don't remember the details).
    #   These are based on the same activity records and don't cause a problem
    #   when saved.
    modifiable_activities = InstructorCreatedActivityForCopy
                            .where(id: to_be_copied_ids)
                            .select('activities.*')

    # For each activity, return a pair of the original activity and modifiable activity.
    #   We need the original for certain values that aren't part of the database record,
    #   and we need the modifiable version to `dup`.
    original_activities.zip(modifiable_activities)
  end

  private def mappings
    ProgramToProgramMapping
      .joins(%(
       inner join concepts
       on program_to_program_mappings.dest_strand_id = concepts.id
      ))
      .where(dest_program_id: @dest_program_id)
  end
end
