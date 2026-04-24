module Dangerfield
  class SectionInstructorSerializer < Dangerfield::BaseSerializer
    add_attributes :section_guid, :user_guid
    exclude_attributes :id, :section_id, :user_id, :role, :allowed_to_edit_content
    def section_guid
      object.section.guid
    end

    def user_guid
      object.instructor.guid
    end
  end
end
