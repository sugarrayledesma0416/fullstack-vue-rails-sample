module StandardsMapping
  module Etl
    class StandardAlignmentIndexConverter < StandardAlignmentConverter
      def convert(alignment, standard, standard_asset)
        @std_asset = standard_asset
        @std = standard
        @additional_info = JSON.parse(@std.additional_info, symbolize_names: true)
        std_set = @std.standard_set
        add_standard(@std).merge(
          {
            alignment_id: alignment.id,
            alignment_status: alignment.alignment_status,
            parent: add_parent,
            ancestors: add_ancestors,
            grade_levels: add_grade_levels,
            standard_asset_domains: extract_domains(standard_asset, :domain),
            standard_asset_subdomains: extract_domains(standard_asset, :subdomain),
            standard_asset_id: @std_asset.id,
            standard_asset_reference_id: @std_asset.reference_id,
            standard_asset_reference_type: @std_asset.reference_type,
            programs: convert_programs,
            issuer: std_set.issuer,
            display_name: std_set.display_name,
            searchable: @std.searchable
          }
        )
      end

      private def convert_programs
        @cms_activity_id = nil
        determine_cms_activity_id

        return fetch_activity_programs if @cms_activity_id
        return fetch_ereader_programs if @ereader_item

        []
      end

      private def add_standard(standard)
        standard_set = standard.standard_set
        {
          vendor_guid: standard.vendor_guid,
          name: standard.name,
          number: standard.number, label: standard.label,
          description: standard.description,
          vendor_standard_set_guid: standard.vendor_standard_set_guid,
          issuer: standard_set.issuer,
          display_name: standard_set.display_name
        }
      end

      private def fetch_activity_programs
        activities = Activity.where(cms_activity_id: @cms_activity_id)
        activities.map do |item|
          next if item.toc_location.blank?

          {
            program_id: item.lesson.program.id,
            lesson_id: item.lesson.id,
            unit_id: item.lesson.unit.id
          }.compact
        end
      end

      private def fetch_ereader_programs
        concept = @ereader_item.concept
        [{
          program_id: concept.program.id,
          lesson_id: concept.lesson.id,
          unit_id: concept.lesson.unit.id
        }]
      end

      private def determine_cms_activity_id
        if @std_asset.activity_reference?
          @cms_activity_id = @std_asset.cms_activity_id_for_activity
        elsif @std_asset.assessment_item_reference?
          @cms_activity_id = @std_asset.cms_activity_id_for_assessment_item
        elsif @std_asset.ereader_item_reference?
          @ereader_item = @std_asset.ereader_item
        else
          message = "UNRECOGNIZED AND UNSUPPORTED REFERENCE TYPE #{@std_asset.reference_type}"
          Rails.logger.debug { message }
        end
      end

      private def extract_domains(standard_asset, key)
        standard_asset.additional_attrs[key]&.split(',')&.map { |domain| domain.strip.downcase }
      end
    end
  end
end
