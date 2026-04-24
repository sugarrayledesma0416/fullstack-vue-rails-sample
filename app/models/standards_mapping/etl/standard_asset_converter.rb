module StandardsMapping
  module Etl
    class StandardAssetConverter
      def convert(standard_asset)
        @standard_asset = standard_asset
        convert_properties
      end

      private def convert_properties
        # need to start nil so TE items dont take the cms_activity_id from the previous loop.
        @cms_activity_id = nil
        # need it to look ike this:
        # { "index": { "_index": "standard_assets", "_id": 1 } }
        # {"standard_assets_id":1,"item_type":"Activity",
        # "programs":[{ "program_id": 370, "lesson_id": 3661, "unit_id": 3089 }]}
        # no escaped strings, new line between index and  asset
        case
        when @standard_asset.activity_reference?
          @cms_activity_id = @standard_asset.cms_activity_id_for_activity
        when @standard_asset.assessment_item_reference?
          @cms_activity_id = @standard_asset.cms_activity_id_for_assessment_item
        when @standard_asset.ereader_item_reference?
          # need the ereader_item
          @ereader_item = @standard_asset.ereader_item
        else
          Rails.logger.debug { "UNRECOGNIZED AND UNSUPPORTED REFERENCE TYPE #{@standard_asset.reference_type}" }
          return "UNRECOGNIZED AND UNSUPPORTED REFERENCE TYPE #{@standard_asset.reference_type}"
        end
        {
          standard_asset_id: @standard_asset.id,
          reference_type: @standard_asset.reference_type,
          reference_id: @standard_asset.reference_id,
          domain:  @standard_asset.additional_attrs[:domain],
          subdomain: @standard_asset.additional_attrs[:subdomain],
          programs: convert_programs,
          standard_alignments: convert_alignments
        }
      end

      private def convert_programs
        # get programs/units/lessons from Activity table using cms_activity_id
        # this works for reference types Activity and AssessmentItem.
        if @cms_activity_id
          activities = Activity.where(cms_activity_id: @cms_activity_id)
          activities.map do |item|
            {
              program_id: item.lesson.program.id,
              lesson_id: item.lesson.id,
              unit_id: item.lesson.unit.id
            }.compact unless item.toc_location.blank?
          end
        elsif @ereader_item
          # get program, lesson, unit for the EReaderItem
          concept = @ereader_item.concept
          [{
            program_id: concept.program.id,
            lesson_id: concept.lesson.id,
            unit_id: concept.lesson.unit.id
          }]
        else
          []
        end
      end

      private def convert_alignments
        alignment_converter = StandardAlignmentConverter.new
        @standard_asset.standard_alignments.map do |alignment|
          alignment_converter.convert(alignment)
        end
      end
    end
  end
end
