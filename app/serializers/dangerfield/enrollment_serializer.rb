module Dangerfield
  class EnrollmentSerializer < Dangerfield::BaseSerializer
    add_attributes :section_guid, :user_guid, :added_by_guid, :section_transferred_to_guid, :transferred_from_guid, :dropped_by_guid
    exclude_attributes :id, :section_id, :user_id, :added_by_id, :section_transferred_to, :transferred_from, :dropped_by_id

    def section_guid
      object.section.guid
    end

    def user_guid
      object.user.guid
    end

    def added_by_guid
      User.unscoped.find(object.added_by_id).guid if object.added_by_id.present?
    end

    def section_transferred_to_guid
      Section.unscoped.find(object.section_transferred_to).guid if object.section_transferred_to.present?
    end

    def transferred_from_guid
      Section.unscoped.find(object.transferred_from).guid if object.transferred_from.present?
    end

    def dropped_by_guid
      User.unscoped.find(object.dropped_by_id).guid if object.dropped_by_id.present?
    end
  end
end
