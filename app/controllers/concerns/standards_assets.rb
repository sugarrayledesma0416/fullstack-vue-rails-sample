module StandardsAssets
  extend ActiveSupport::Concern

  private def validation_errors(error)
    return { msg: error.message } if @asset.errors.blank?

    {
      attempted_attrs: @asset.attributes.symbolize_keys.except(:id, :created_at, :updated_at),
      msg: @asset.errors.full_messages.join('; ')
    }
  end

  private def permitted
    params
      .require(:standard_asset)
      .permit(
        :vendor_guid,
        :reference_id,
        :reference_type,
        :m3_publish_status,
        :date_alignments_modified_utc,
        additional_attrs: %i[domain subdomain],
        assessment_item_attributes: %i[guid assessment_id points_possible],
        ereader_item_attributes: %i[guid concept_id title page_section descriptor page_number]
      )
  end

  private def create_asset
    @asset = StandardAsset.new(permitted)
    @asset.save!
  end

  private def update_asset
    @asset = StandardAsset.find_by!(vendor_guid: params[:vendor_guid])
    @asset.update!(permitted)
  end
end
