# Default S3 bucket settings
Rails.configuration.s3_region_name = 'us-east-1'
Rails.configuration.instructor_media_profile = nil
Rails.configuration.s3_activity_profile_name = nil
Rails.configuration.s3_media_profile_name = nil
Radner.region_name = Rails.configuration.s3_region_name
Radner.use_aws_credentials = false
Radner.profile_name = nil

# S3 bucket where santillana activities can be found.
Rails.configuration.santillana_book_host = 'smartbook.maestro.vhlcentral.com'.freeze
