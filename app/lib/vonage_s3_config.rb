module VonageS3Config
  private def s3_profile_name
    nil
  end

  private def s3_bucket_name
    M3::Application.config.vonage_media_bucket_name
  end
end
