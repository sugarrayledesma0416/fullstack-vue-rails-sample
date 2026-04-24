namespace :migrate_nfs_to_s3 do
  desc 'migrate announcement attachments to files.vhlcentral.com'
  task announcement_attachments: :environment do |task|
    validate_running_live
    validate_dry_run

    # upload getting the local file name and the bucket path.
    Announcement.include(AnnouncementLocalPath)
    announcements = Announcement.where("file_name IS NOT NULL AND file_name <> ''")
    exisiting_files, files_not_found = announcements.partition(&:local_file_exists?)

    # Migrate attachment files.
    puts "Migrating #{exisiting_files.count} announcement attachments."
    exisiting_files.each { |announcement| announcement.migrate_to_s3 } if dry_run == 'false'

    # Inform the ones that could not be migrated.
    unless files_not_found.empty?
      puts "#{files_not_found.count} announcements have a file path but the file does not exist locally."
      puts "ID's are: [#{files_not_found.map(&:id).join(',')}]"
    end
  end

  desc 'migrate composition attachments to files.vhlcentral.com'
  task composition_attachments: :environment do |task|
    validate_running_live
    validate_dry_run

    # 6.8G to be migrated from /var/www/m3/shared/assets/composition_attachments
    # 36604 records.
    # upload getting the local file name and the bucket path.
    CompositionAttachment.include(CompositionAttachmentLocalPath)
    composition_attachment_ids = CompositionAttachment.where("file_name IS NOT NULL AND file_name <> ''").order(:id).pluck(:id)
    File.open('migrate_composition_attachments.log', 'w') do |migration_log|
      # find a way to know what was the last migrated id.
      composition_attachment_ids.each_slice(500) do |batch|
        composition_attachments = CompositionAttachment.where(id: batch)
        exisiting_files, files_not_found = composition_attachments.partition(&:local_file_exists?)

        # Migrate attachment files.
        if dry_run == 'false'
          exisiting_files.each do |composition_attachment|
            composition_attachment.migrate_to_s3
            migration_log.write("Migrated ID: #{composition_attachment.id}\n")
          end
        end

        # Inform the ones that could not be migrated.
        unless files_not_found.empty?
          migration_log.write("#{files_not_found.count} composition attachments have a file path but the file does not exist locally.\n")
          migration_log.write("ID's are: [#{files_not_found.map(&:id).join(',')}]\n")
        end
      end
    end
  end

  desc 'migrate resources to files.vhlcentral.com'
  task resources: :environment do |task|
    require 'progressbar'
    validate_running_live
    validate_dry_run

    # upload getting the local file name and the bucket path.
    Resource.include(ResourceLocalPath)
    resources = Resource.where("file_name IS NOT NULL AND file_name <> ''")
    exisiting_files, files_not_found = resources.partition(&:local_file_exists?)
    progress_bar = ProgressBar.new("resources_migrate", resources.count)

    # Migrate resource files.
    puts "Migrating #{exisiting_files.count} resources."
    if dry_run == 'false'
      exisiting_files.each do |resource|
        resource.migrate_to_s3
        progress_bar.inc
      end
      progress_bar.finish
    end

    # Inform the ones that could not be migrated.
    unless files_not_found.empty?
      puts "#{files_not_found.count} resources have a file path but the file does not exist locally."
      puts "ID's are: [#{files_not_found.map(&:id).join(',')}]"
    end
  end

  def validate_running_live
    unless Rails.env.live?
      puts 'This rake task can only be run from live.'
      exit
    end
  end

  def dry_run
    ENV['dry_run'] && ENV['dry_run'].downcase || 'true'
  end

  def validate_dry_run
    unless dry_run == 'false'
      puts "Running with dry_run=true. No file will be migrated."
    end
  end

  module MigrateLocalPath
    def local_file_exists?
      File.exist?(local_file_path)
    end

    def migrate_to_s3
      upload_file(File.new(local_file_path)) unless has_file?
    end
  end

  module AnnouncementLocalPath
    include MigrateLocalPath

    def local_file_path
      Rails.root.join('announcements', Rails.env, id.to_s, file_name)
    end
  end

  module CompositionAttachmentLocalPath
    include MigrateLocalPath

    def local_file_path
      Rails.root.join('composition_attachments', Rails.env, user_id.to_s, self.id.to_s, file_name)
    end
  end

  module ResourceLocalPath
    include MigrateLocalPath

    def local_file_path
      if uploaded?
        Rails.root.join('resources', Rails.env, program_id.to_s, 'uploaded', owner_id.to_s, id.to_s, file_name)
      else
        Rails.root.join('resources', Rails.env, program_id.to_s, id.to_s, file_name)
      end
    end
  end
end

