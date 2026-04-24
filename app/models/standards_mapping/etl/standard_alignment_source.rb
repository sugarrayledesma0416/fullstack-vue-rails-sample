module StandardsMapping
  module Etl
    class StandardAlignmentSource
      include UploadTypes

      def initialize(params)
        @batch_size = params[:batch_size]
        @upload_type = params[:upload_type]
        @last_upload_date = params[:last_upload_date]
        Rails.logger.info "[StandardsMapping::Etl::StandardAlignmentSource] initialize - Initialized with batch_size: #{@batch_size}, upload_type: #{@upload_type}, last_upload_date: #{@last_upload_date}"
      end

      # Kiba will call this to get each record for processing
      def each
        if @upload_type != INITIAL_UPLOAD_TYPE && @last_upload_date.present?
          alignments = StandardAlignment.eager_load(:standard, :standard_asset).where(
            'standard_alignments.created_at > :last_date OR ' \
            'standards.created_at > :last_date OR ' \
            'standard_assets.created_at > :last_date OR ' \
            'standard_alignments.updated_at > :last_date OR ' \
            'standards.updated_at > :last_date OR ' \
            'standard_assets.updated_at > :last_date',
            last_date: @last_upload_date
          ).distinct
        else
          alignments = StandardAlignment.includes(:standard, :standard_asset)
        end

        alignments.find_each(batch_size: @batch_size) do |record|
          yield record
        end
      end
    end
  end
end
