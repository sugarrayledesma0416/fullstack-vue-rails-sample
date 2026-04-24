module StandardsMappingTemplates
  extend ActiveSupport::Concern

  def activities_mapping_csv
    @activities_mapping_csv ||=
      StandardsMapping::CsvGenerator.new(@program.id, 'Activity').generate_csv_string
  end

  def assessments_mapping_csv
    @assessments_mapping_csv ||=
      StandardsMapping::CsvGenerator.new(@program.id, 'Assessment').generate_csv_string
  end

  def assets_mapping_csv
    @assets_mapping_csv ||=
      StandardsMapping::StandardAssetCsvGenerator.new(
        @program.id, params[:asset_type]
      ).generate_csv_string
  end
end
