module StandardsMapping
  module Etl
    class StandardConverter
      def convert(standard)
        @standard = standard
        @additional_info = JSON.parse(standard.additional_info, symbolize_names: true)
        {
          standard_id: standard.id,
          vendor_guid: standard.vendor_guid,
          name: standard.name,
          number: standard.number,
          label: standard.label,
          description: standard.description,
          issuer: standard.standard_set.issuer,
          display_name: standard.standard_set.display_name,
          vendor_standard_set_guid: standard.vendor_standard_set_guid,
          searchable: standard.searchable,
          parent: add_parent,
          grade_levels: add_grade_levels,
          ancestors: add_ancestors
        }
      end

      private def add_parent
        return if @additional_info.empty?

        parent_guid = @additional_info[:additional_info][:parent_guid]
        parent_std = Standard.where(vendor_guid: parent_guid)&.first
        if parent_std.present?
          {
            standard_id: parent_std.id,
            vendor_guid: parent_std.vendor_guid,
            name: parent_std.name,
            number: parent_std.number,
            label: parent_std.label,
            description: parent_std.description,
            issuer: parent_std.standard_set.issuer,
            display_name: parent_std.standard_set.display_name,
            vendor_standard_set_guid: parent_std.vendor_standard_set_guid
          }
        end
      end

      private def add_ancestors
        return if @additional_info.empty?

        ancestor_guids = @additional_info[:additional_info][:ancestors].split(',')
        ancestor_guids.map do |anc_guid|
          { vendor_guid: anc_guid }
        end
      end

      private def add_grade_levels
        return if @additional_info.empty?

        grade_level_values = @additional_info[:additional_info][:grade_levels].split(',')
        grade_level_values.map do |gl|
          { grade_level: gl }
        end
      end
    end
  end
end
