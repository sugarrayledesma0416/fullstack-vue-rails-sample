# For use in InstructorGeneratedContentCopier.
#   Meant to be instantiated from an existing InstructorCreatedActivity record,
#   `dup`d, and updated with new lesson and concept IDs.
#
#   Handles XML copy to new file internally.
class InstructorCreatedActivityForCopy < InstructorCreatedActivity
  before_save :read_original_xml

  def self.copy(instructor_id, activity_to_copy)
    new_copy = self.find(activity_to_copy.id).dup
    new_copy.instructor_id = instructor_id
    new_copy.title = new_copy.title
    new_copy.save
    new_copy
  end

  private def read_original_xml
    # Before the record is saved, the revision ID has not changed,
    #   and the content is retrieved (either from cache or s3)
    #   by that ID.
    #
    # Assign it to an instance variable for use in after_save.
    @original_xml = content
  end

  # Override the implementation in InstructorCreatedActivity to copy the source
  #   XML instead of generating new XML.
  #
  # We get a copy of the source XML in the `read_original_xml` before_save above.
  #   After the record is saved, but before store_xml runs, the revision ID is
  #   updated via the `increment_version` after_save in InstructorCreatedActivity,
  #   so the XML will be written to the correct new location.
  private def store_xml
    activity_content.store_content(@original_xml)
  end

  # Several before_save and after_save callbacks in InstructorCreatedActivity
  #   set fields on the record to their initial values. Here, because we are
  #   copying an existing record, the values are already set, so we disable
  #   the callbacks by overriding them with a no-op implementation.
  #
  # If not overridden, these callbacks would, respectively,
  #   * generate new XML and set the values for concept_id and icon
  #   * set concept_rank and toc_location_rank
  #   * set component_name
  #   * set license_group_id
  #   * set several values based on the content object, as well as singular_label
  private def process_callbacks_for_activity; end
  private def set_rank; end
  private def set_component_name; end
  private def set_license_group_id; end
  private def set_denormalized_values; end

  # We disable this validation because it depends on a video_url attribute
  #   that is not set in the for-copy object, where the URL is already part of
  #   the content XML.
  private def valid_video_id; end
end
