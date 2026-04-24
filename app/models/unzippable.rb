#  encoding: utf-8

require 'zip'

module Unzippable
  def unzip_with_subdirs(zip_file_path, destination_dir)
    FileUtils.mkdir_p(destination_dir) unless File.directory? destination_dir
    Zip::File.open(zip_file_path) do |zip_root|
      entries = zip_root.to_set.to_a
      entries.each do |entry|
        next if File.dirname(entry.name) =~ /__MACOSX/
        next if entry.directory?
        target_dir = File.join(destination_dir, File.dirname(entry.name))

        FileUtils.mkdir_p(target_dir) unless File.directory?(target_dir)
        extracted_location = File.join(target_dir, File.basename(entry.name))

        File.unlink extracted_location if File.exist? extracted_location
        entry.extract(extracted_location)
      end
    end
  end

  def unzip_without_subdirs(zip_file_path, destination_dir)
    FileUtils.mkdir_p(destination_dir) unless File.directory? destination_dir
    Zip::File.open(zip_file_path) do |zip_root|
      entries = zip_root.to_set.to_a
      entries.each do |entry|
        next if File.dirname(entry.name) =~ /__MACOSX/
        next if entry.directory?
        extracted_location = File.join(destination_dir, File.basename(entry.name))
        File.unlink extracted_location if File.exist? extracted_location
        entry.extract(extracted_location)
      end
    end
  end
end
