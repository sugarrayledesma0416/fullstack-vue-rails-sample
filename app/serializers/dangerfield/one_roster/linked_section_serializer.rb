module Dangerfield
  module OneRoster
    class LinkedSectionSerializer < Dangerfield::BaseSerializer
      add_attributes :section_guid, :school_guid
      exclude_attributes :id, :section_id, :school_id

      def section_guid
        object.section.guid
      end

      def school_guid
        object.school.guid
      end
    end
  end
end
