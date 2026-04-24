class A11yReportGenerator
  include Radner::FilesS3Bucket
  S3_DESTINATION_FOLDER = {
    'detailed' => 'tasks/a11y_reports/detailed_reports/',
    'simplified' => 'tasks/a11y_reports/simplified_reports/'
  }.freeze

  attr_reader :file_name, :file_path

  def initialize(program_id, include_details = false)
    @program_id = program_id
    @include_details = include_details
  end

  def generate_report
    Rails.logger.debug("A11Y: Generating #{spreadsheet.file_path} ...")
    spreadsheet.write
  end

  def upload_report
    return true if s3_bucket.upload_file(file_s3_path, spreadsheet.file_path)

    Rails.logger.error(s3_bucket.upload_error)
  end

  def delete_file
    return if s3_bucket.upload_error.present?

    File.delete(spreadsheet.file_path) if File.exist?(spreadsheet.file_path)
  end

  def simplified_report_url
    download_links['simplified_report_url']
  end

  def detailed_report_url
    download_links['detailed_report_url']
  end

  def simplified_report_last_modified
    last_modified_dates['simplified_report_last_modified']
  end

  def detailed_report_last_modified
    last_modified_dates['detailed_report_last_modified']
  end

  private def spreadsheet
    @spreadsheet ||= A11ySpreadsheet.new(@program_id, @include_details)
  end

  private def download_links
    return @download_links if @download_links

    @download_links = {
      'detailed_report_url' => report_signed_url('detailed'),
      'simplified_report_url' => report_signed_url('simplified')
    }
  end

  private def last_modified_dates
    return @last_modified_dates if defined?(@last_modified_dates)

    @last_modified_dates = {
      'detailed_report_last_modified' => report_last_modified('detailed'),
      'simplified_report_last_modified' => report_last_modified('simplified')
    }
  end

  def file_s3_path
    if @include_details
      detailed_report_s3_path
    else
      simplified_report_s3_path
    end
  end

  private def simplified_report_s3_path
    File.join(
      S3_DESTINATION_FOLDER['simplified'], "simplified_#{spreadsheet.file_name}"
    )
  end

  private def detailed_report_s3_path
    File.join(
      S3_DESTINATION_FOLDER['detailed'], "detailed_#{spreadsheet.file_name}"
    )
  end

  private def report_signed_url(type)
    return if report_listing(type).blank?

    # Radner needs these values set to generate the signed url
    @file_path = report_listing(type).last.key
    @file_name = File.basename(@file_path)

    signed_url
  end

  private def report_last_modified(type)
    return if report_listing(type).blank?

    report_listing(type).last.last_modified.to_s(:rfc822)
  end

  private def report_listing(type)
    return @report_listing[type] if @report_listing&.fetch(type, nil)

    @report_listing ||= {}
    s3_path = S3_DESTINATION_FOLDER[type]

    # This listing will be sorted by object key
    @report_listing[type] = s3_bucket.directory_files(s3_path).select do |object|
      object.key =~ /_program_#{@program_id}/
    end
  end
end
