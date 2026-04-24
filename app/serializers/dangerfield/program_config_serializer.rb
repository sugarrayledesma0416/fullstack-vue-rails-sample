module Dangerfield
  class ProgramConfigSerializer < Dangerfield::BaseSerializer
    add_attributes :creator_guid, :datastore_json
    exclude_attributes :id, :creator_id, :created_at, :updated_at

    def datastore_json
      object.datastore_json
    end

    def creator_guid
      object.creator.guid
    end
  end
end
