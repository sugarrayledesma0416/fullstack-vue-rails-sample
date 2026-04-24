module StandardsMapping
  module Etl
    class StandardAlignmentConverter

      def convert(alignment)
        @std = Standard.where(vendor_guid: alignment.vendor_standard_guid).first
        @additional_info = JSON.parse(@std.additional_info, symbolize_names: true)
        add_standard(@std).merge({
          alignment_id: alignment.id,
          alignment_status: alignment.alignment_status,
          parent: add_parent,
          ancestors: add_ancestors,
          grade_levels: add_grade_levels
        })

      end

      private def add_standard(standard)
        {
          vendor_guid: standard.vendor_guid,
          name: standard.name,
          number: standard.number,
          label: standard.label,
          description: standard.description,
          vendor_standard_set_guid: standard.vendor_standard_set_guid
        }
      end

      private def add_ancestors
        ancestor_guids = @additional_info[:additional_info][:ancestors].split(",")
        unless ancestor_guids.empty?
          ancestors = ancestor_guids.map do |anc_guid|
            ancs_std = Standard.where(vendor_guid: anc_guid).first
            if ancs_std.present?
              add_standard(ancs_std)
            else
              Rails.logger.warn "Std with vendor_guid: #{@std.vendor_guid} has non-existent ancestor standard with vendor_guid: #{anc_guid}"
              next
            end
          end
        end
        ancestors
      end

      private def add_parent
        parent = Standard.where(vendor_guid:@additional_info[:additional_info][:parent_guid]).first
        if parent.present?
          add_standard(parent)
        else
          Rails.logger.warn "Std with vendor_guid: #{@std.vendor_guid} has non-existent parent standard with vendor_guid: #{@additional_info[:additional_info][:parent_guid]}"
          nil
        end
      end

      private def add_grade_levels
        grade_level_values = @additional_info[:additional_info][:grade_levels].split(",")
        unless grade_level_values.empty?
          grade_levels = grade_level_values.map do |gl|
            { grade_level: "#{gl}" }
          end
        end
      end
    end
  end
end
