class StandardsController < ApplicationController
  include HttpBasicAuthHelper
  include StandardsMappingTemplates
  include UpdateStandards

  before_action :http_basic_authenticate
  skip_before_action :verify_authenticity_token

  def show
    respond_to do |format|
      format.js do
        return render status: :ok, body: { guid: standard.vendor_guid }.to_json if standard.present?

        render status: :not_found, body: { message: 'Standard does not exist'.to_json }
      end
    end
  end

  # endpoint called from CMS to do the following:
  #  - trigger AcademicBenchmarks API to retrieve updated Standards
  #    and new StandardSets
  #  - set searchable flag to false for any Standard that has no
  #    number AND no label
  #  - upload new and updated Standards to OpenSearch standards index
  # kicks off a Sidekiq Worker to perform these tasks;
  # errors logged to the Sidekiq log
  def update_all
    StandardsUpdateWorker.perform_async
    render status: :ok, body: { message: 'Standards are being updated in M3 and OpenSearch' }
  end

  def standards_mapping_activities_template
    respond_to do |format|
      format.json do
        render json: { csv: activities_mapping_csv } if validate_program_id
      end
    end
  end

  def standards_mapping_assessments_template
    respond_to do |format|
      format.json do
        render json: { csv: assessments_mapping_csv } if validate_program_id
      end
    end
  end

  def standards_mapping_ereader_template
    respond_to do |format|
      format.json do
        render json: { csv: StandardsMapping::EReaderCsvGenerator.generate_csv_string }
      end
    end
  end

  def standards_mapping_toc_csv
    respond_to do |format|
      format.json do
        if validate_program_id
          render(
            json: {
              csv: StandardsMapping::EReaderCsvGenerator.generate_toc_csv(@program.id)
            }
          )
        end
      end
    end
  end

  def standards_mapping_ingested_te_items
    respond_to do |format|
      format.json do
        if validate_program_id
          render json: {
            csv: StandardsMapping::IngestedTeItemGenerator.generate_csv(params[:program_id])
          }
        end
      end
    end
  end

  def standard_assets_template
    respond_to do |format|
      format.json do
        render json: { csv: assets_mapping_csv } if validate_program_id
      end
    end
  end

  private def standard
    @standard ||= Standard.find_by(vendor_guid: params[:id])
  end

  # update Standards in OpenSearch
  private def update_search
    helper = StandardsMapping::StandardsMappingIndicesHelper.new(true)
    helper.upload_standards(StandardsMapping::Etl::UploadTypes::UPDATE_UPLOAD_TYPE)
    @error_response.concat(helper.errors)
  end

  private def validate_program_id
    @program = Program.find params['program_id']
  rescue ActiveRecord::RecordNotFound
    msg = "The program ID #{params['program_id']} is not a valid program id."
    render(
      json: { error_message: msg },
      status: :not_found
    )
    false
  end
end
