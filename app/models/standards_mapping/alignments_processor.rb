module StandardsMapping
  class AlignmentsProcessor
    attr_reader :ab_client, :errors, :obsolete_alignments

    def initialize
      @alignments = []
      @errors = []
      @ab_client = MaestroActivityEngine::ABConnect::Client.new
      @obsolete_alignments = []
    end

    def import_new_assets
      scope = StandardAsset.where(date_alignments_modified_utc: nil)
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_new_assets - starting with assets_count: #{scope.count}"

      scope.find_each(batch_size: 100) do |asset|
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_new_assets - processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
        process_new_alignments(asset)
      rescue StandardError => e
        error_message = "Alignments for asset with id: #{asset.id} could not be processed. Error: #{e.message}"
        @errors << error_message
        Rails.logger.error "[StandardsMapping::AlignmentsProcessor] import_new_assets - #{error_message}"
      end
      Rails.logger.info '[StandardsMapping::AlignmentsProcessor] import_new_assets - completed'
    end

    def sync_asset_alignments
      helper = StandardsMapping::StandardsMappingIndicesHelper.new
      last_sync_date = helper.last_successful_upload_date(
        StandardsMapping::OpenSearchClient.opensearch_std_alignments_alias
      )

      StandardAsset
        .where(date_alignments_modified_utc: last_sync_date..)
        .find_each(batch_size: 100) do |asset|
        process_new_alignments(asset)
        remove_obsolete_alignments(asset)
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] sync_asset_alignments - Alignments for asset with id: #{asset.id} were processed successfully."
      rescue StandardError => e
        error_message = "Alignments for asset with id: #{asset.id} could not be processed. Error: #{e.message}"
        @errors << error_message
        Rails.logger.error error_message
      end
    end

    def import_updated_alignments(program_id)
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_updated_alignments - starting for program_id: #{program_id}"
      last_imported_date = StandardAsset.where.not(date_alignments_modified_utc: nil)
                                        .order(:date_alignments_modified_utc)
                                        .pick(:date_alignments_modified_utc)

      # guard for nil last_imported_date (no prior imports)
      if last_imported_date.nil?
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_updated_alignments - no prior import found; skipping"
        return
      end

      # collect cms activity ids from Activity and AssessmentItems StandardAssets
      activity_asset_ids = StandardAsset.where('date_alignments_modified_utc >= ?',
                                               last_imported_date)
                                        .where(reference_type: 'Activity')
                                        .distinct
                                        .pluck(:reference_id)

      assessment_asset_ids = AssessmentItem.joins(:standard_asset)
                                           .where('standard_assets.date_alignments_modified_utc >= ?', last_imported_date)
                                           .distinct
                                           .pluck(:assessment_id)

      cms_ids = (activity_asset_ids + assessment_asset_ids).compact.uniq

      # narrow this list down to activities that belong to the program
      cms_activity_ids_in_program = Activity.where(cms_activity_id: cms_ids)
                                            .joins(lesson: :unit)
                                            .where(units: { program_id: program_id })
                                            .distinct
                                            .pluck(:cms_activity_id)

      # get AssessmentItem ids in the program
      ai_item_ids = AssessmentItem.where(assessment_id: cms_activity_ids_in_program).pluck(:id)

      # now retrieve the StandardAssets that need to be updated and process in batches
      assets_scope = StandardAsset.where(reference_type: 'Activity',
                                         reference_id: cms_activity_ids_in_program)
                                  .or(StandardAsset.where(reference_type: 'AssessmentItem',
                                                          reference_id: ai_item_ids))
      assets_scope.find_each(batch_size: 100) do |asset|
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_updated_alignments - processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
        process_added_alignments(asset)
        process_deleted_alignments(asset)
        update_asset_record(asset) if @added || @deleted
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_updated_alignments - completed processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
      rescue StandardError => e
        error_message = "Alignments for asset with id: #{asset.id} could not be processed. Error: #{e.message}"
        @errors << error_message
        Rails.logger.error "[StandardsMapping::AlignmentsProcessor] import_updated_alignments - error processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}. Error: #{e.message}"
      end
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] import_updated_alignments - completed for program_id: #{program_id}"
    end

    private def fetch_next_batch(alignments_content, vendor_guid, filters = {})
      return unless alignments_content

      if alignments_content['errors'].nil?
        fetched = alignments_content['data'] || []
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] fetch_next_batch - fetched #{fetched.size} alignments for vendor_guid: #{vendor_guid}"
        @alignments.concat(fetched)

        current_offset = alignments_content.dig('meta', 'offset').to_i
        total = (alignments_content.dig('meta', 'count') || @count || 0).to_i
        limit = (alignments_content.dig('meta', 'limit') || @limit || 0).to_i

        return if limit <= 0

        previous_offset = current_offset

        while (current_offset + limit) < total
          current_offset += limit
          batch = @ab_client.fetch_asset_alignments({ guid: vendor_guid, offset: current_offset,
                                                      limit: limit }.merge(filters))
          break unless batch && batch['errors'].nil?

          more = batch['data'] || []
          Rails.logger.info "[StandardsMapping::AlignmentsProcessor] fetch_next_batch - fetched #{more.size} alignments for vendor_guid: #{vendor_guid} (offset=#{current_offset})"
          @alignments.concat(more)

          new_offset = batch.dig('meta', 'offset')
          break if more.empty?
          break if new_offset.nil? || new_offset.to_i <= previous_offset

          previous_offset = new_offset.to_i
        end
      else
        error_message = "there was an error calling the API #{alignments_content['errors']}"
        @errors << error_message
        Rails.logger.error "[StandardsMapping::AlignmentsProcessor] fetch_next_batch - error fetching alignments for vendor_guid: #{vendor_guid}. Error: #{alignments_content['errors']}"
      end
    end

    private def process_new_alignments(asset)
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] process_new_alignments - processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
      @alignments = []
      @added = false

      alignments_by_asset = @ab_client.fetch_asset_alignments(
        guid: asset.vendor_guid,
        offset: 0,
        limit: 100
      )

      @count = alignments_by_asset['meta']['count']
      @limit = alignments_by_asset['meta']['limit']
      alignments_first_batch = alignments_by_asset
      fetch_next_batch(alignments_first_batch, asset.vendor_guid)
      parse_alignments(asset)

      update_asset_record(asset)
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] process_new_alignments - completed processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
    end

    private def process_added_alignments(asset)
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] process_added_alignments - processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
      @alignments = []
      @added = false
      # fetch_asset_alignments method returns alignments for a given vendor asset guid
      added_alignments = @ab_client.fetch_asset_alignments(guid: asset.vendor_guid,
                                                           date_created_utc: asset.date_alignments_modified_utc,
                                                           offset: 0, limit: 100)

      @count = added_alignments['meta']['count']
      @limit = added_alignments['meta']['limit']
      alignments_first_batch = added_alignments
      fetch_next_batch(
        alignments_first_batch,
        asset.vendor_guid,
        { date_created_utc: asset.date_alignments_modified_utc }
      )
      parse_alignments(asset)
    end

    private def remove_obsolete_alignments(asset)
      scope = StandardAlignment.where(standard_asset_id: asset.id,
                                      vendor_asset_guid: asset.vendor_guid)

      exclude_guids = @alignments.map { |a| a['id'] }.compact if @alignments.present?
      scope = scope.where.not(vendor_standard_guid: exclude_guids) if exclude_guids&.any?

      total_to_delete = scope.count
      return if total_to_delete.zero?

      Rails.logger.info("Deleting #{total_to_delete} alignment(s) for asset with id: #{asset.id}")
      scope.find_in_batches(batch_size: 100) do |batch|
        batch.each do |alignment|
          begin
            alignment.destroy!
            @obsolete_alignments << alignment
            Rails.logger.info "Alignment with standard guid: #{alignment.vendor_standard_guid} was deleted successfully."
          rescue StandardError => e
            error_message = "Failed to delete alignment with standard guid: #{alignment.vendor_standard_guid}. Error: #{e.message}"
            @errors << error_message
            Rails.logger.error error_message
          end
        end
      end
    end

    private def process_deleted_alignments(asset)
      Rails.logger.info "[StandardsMapping::AlignmentsProcessor] process_deleted_alignments - processing asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
      @alignments = []
      @deleted = false
      deleted_alignments = @ab_client.fetch_asset_alignments(guid: asset.vendor_guid,
                                                             date_deleted_utc: asset.date_alignments_modified_utc,
                                                             offset: 0,
                                                             limit: 100)

      @count = deleted_alignments['meta']['count']
      @limit = deleted_alignments['meta']['limit']
      alignments_first_batch = deleted_alignments
      fetch_next_batch(
        alignments_first_batch,
        asset.vendor_guid,
        { date_deleted_utc: asset.date_alignments_modified_utc }
      )
      delete_alignments(asset)
    end

    private def parse_alignments(asset)
      @alignments.each do |alignment|
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] parse_alignments - processing alignment with id: #{alignment['id']} for asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
        attributes = {
          standard_asset_id: asset.id,
          vendor_asset_guid: asset.vendor_guid,
          vendor_standard_guid: alignment['id'],
          alignment_status: 'confirmed'
        }

        save_alignment_record(attributes)
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] parse_alignments - completed processing alignment with id: #{alignment['id']} for asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
      end
    end

    private def delete_alignments(asset)
      @alignments.each do |alignment|
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] delete_alignments - processing deletion of alignment with id: #{alignment['id']} for asset with id: #{asset.id} and vendor_guid: #{asset.vendor_guid}"
        attributes = {
          standard_asset_id: asset.id,
          vendor_asset_guid: asset.vendor_guid,
          vendor_standard_guid: alignment['id']
        }

        begin
          alignment = StandardAlignment.where(attributes).first
          if alignment
            alignment.delete
            @deleted = true
            Rails.logger.info "[StandardsMapping::AlignmentsProcessor] delete_alignments - alignment with standard guid: #{attributes[:vendor_standard_guid]} was deleted successfully."
          end
        rescue ActiveRecord::RecordNotSaved
          error_message = "Alignment with standard guid: #{attributes[:vendor_standard_guid]} could not be deleted."
          @errors << error_message
          Rails.logger.error "[StandardsMapping::AlignmentsProcessor] delete_alignments - #{error_message}"
        end
      end
    end

    private def save_alignment_record(attributes)
      begin
        StandardAlignment.create!(
          standard_asset_id: attributes[:standard_asset_id],
          vendor_standard_guid: attributes[:vendor_standard_guid],
          vendor_asset_guid: attributes[:vendor_asset_guid],
          alignment_status: attributes[:alignment_status]
        )
        Rails.logger.info "[StandardsMapping::AlignmentsProcessor] save_alignment_record - alignment with standard guid: #{attributes[:vendor_standard_guid]} was saved successfully."
        @added = true
      rescue ActiveRecord::RecordInvalid => e
        error_message = "Alignment with standard guid: #{attributes[:vendor_standard_guid]} could not be saved: #{e.record.errors.full_messages.join(', ')}"
        @errors << error_message
        Rails.logger.error "[StandardsMapping::AlignmentsProcessor] save_alignment_record - #{error_message}"
      rescue ActiveRecord::RecordNotUnique
        Rails.logger.debug "[StandardsMapping::AlignmentsProcessor] save_alignment_record - duplicate alignment for #{attributes[:vendor_standard_guid]} ignored"
      end
    end

    private def update_asset_record(asset)
      # update date_alignments_modified_utc to today
      asset.date_alignments_modified_utc = DateTime.now
      asset.save!
    rescue ActiveRecord::RecordNotSaved
      error_message = "Asset with id: #{asset.id} could not be saved."
      @errors << error_message
      Rails.logger.error "[StandardsMapping::AlignmentsProcessor] update_asset_record - #{error_message}"
    end
  end
end
