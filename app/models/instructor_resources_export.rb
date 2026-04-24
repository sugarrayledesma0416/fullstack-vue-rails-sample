require 'zip'
require 'csv'
require 'tempfile'

class InstructorResourcesExport
  include Radner::FilesS3Bucket
  attr_reader :file_name, :file_path

  def initialize(program)
    @program = program
    @prefix_abbreviation = program.prefix_abbreviation
    @zip_file_name = "#{program.prefix_abbreviation}_m3_resources.zip"
    @zip_file_s3_path = "tasks/instructor_resources/#{@zip_file_name}"
    @csv_file_name = "#{@prefix_abbreviation}_m3_resources.csv"
    @csv_s3_path = "tasks/instructor_resources/#{@csv_file_name}"
  end

  def export_resources_to_csv
    CSV.open(temp_csv_file.path, 'wb') do |csv|
      csv << %w[source_file_path start_unit end_unit component_name subcomponent_name
                clean_title is_student_resource is_protected description]
      @program.resources.each do |resource|
        csv << [resource.file_path, start_unit_and_lesson_for_resource(resource),
                resource&.end_unit ? (resource.end_unit.rank + 1) : '',
                resource.component_name,
                resource.subcomponent_name, resource.title,
                resource.vhl_student_resource ? 1 : 0, resource.protected ? 1 : 0,
                resource.description]
      end
    end
  end

  def fetch_and_zip_resources
    Zip::OutputStream.open(temp_zip_file.path) do |zipfile|
      @program.resources.each do |resource|
        if s3_bucket.file_exist?(resource.file_path)
          zipfile.put_next_entry(resource.file_path)
          zipfile.write(s3_bucket.fetch(resource.file_path))
        end
      end
      export_resources_to_csv
      zipfile.put_next_entry(@csv_file_name)
      zipfile.write(temp_csv_file.read)
    end
    upload_zip_file
    temp_zip_file
  end

  private def start_unit_and_lesson_for_resource(resource)
    unit_rank = resource.start_unit&.rank
    lesson_rank = resource.lesson&.rank
    if unit_rank.present? && lesson_rank.present?
      "#{unit_rank + 1}.#{lesson_rank + 1}"
    elsif unit_rank.present?
      (unit_rank + 1).to_s
    else
      ''
    end
  end

  def upload_csv_file
    s3_bucket.upload_file(@csv_s3_path, temp_csv_file.path,
                          cache_control: 'no-cache, no-store, must-revalidate',
                          content_type: 'text/csv')
  end

  def set_file_path_to_csv
    @file_path = @csv_s3_path
    @file_name = @csv_file_name
  end

  def set_file_path_to_zip
    @file_path = @zip_file_s3_path
    @file_name = @zip_file_name
  end

  def csv_exists_in_s3?
    s3_bucket.bucket.object(@csv_s3_path).exists?
  end

  def delete_files
    delete_zip_file
    delete_csv_file
  end

  def zip_exist_in_s3?
    s3_bucket.file_exist?(@zip_file_s3_path)
  end

  def last_modified
    s3_bucket.bucket.object(@file_path).last_modified.to_s(:rfc822)
  end

  def formatted_file_size
    # Where d is the data length in bytes and
    # e is a scale coefficient to show the best unit for display.
    d = s3_bucket.content_length(@file_path)
    e = Math.log10(d).to_i / 3
    return '%.2f' % (d / 1000 ** e) + [' B', ' KB', ' MB', ' GB'][e]
  end

  private def temp_csv_file
    @temp_csv_file ||= Tempfile.new(@csv_file_name)
  end

  private def temp_zip_file
    @temp_zip_file ||= Tempfile.new(@zip_file_name)
  end

  private def upload_zip_file
    s3_bucket.upload_file(@zip_file_s3_path, temp_zip_file.path,
                          cache_control: 'no-cache, no-store, must-revalidate',
                          content_type: 'application/zip')
  end

  private def delete_csv_file
    temp_csv_file.close
    temp_csv_file.unlink
  end

  private def delete_zip_file
    temp_zip_file.close
    temp_zip_file.unlink
  end
end
