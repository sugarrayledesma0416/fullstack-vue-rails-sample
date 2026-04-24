module InstructorMediaItemStorage
  include Radner::S3Bucket

  private def store_remote_file
    s3_bucket.move_file(temp_file_path, file_path)
  rescue StandardError => e
    VHLMonitor.error(
      e,
      'Failed to store InstructorMediaItem temp file',
      destination_file: file_path,
      source_file: temp_file_path
    )
  end

  private def s3_profile_name
    M3::Application.config.instructor_media_profile
  end

  private def s3_bucket_name
    M3::Application.config.instructor_media_bucket_name
  end
end
